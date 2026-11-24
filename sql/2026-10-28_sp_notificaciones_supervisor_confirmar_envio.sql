USE [PedidosWeb]
GO

/* ============================================================
   NOTIFICACION_SUPERVISOR_PEDIDO: nueva columna mailitem_id.
   Guarda el ID que devuelve sp_send_dbmail, para poder cruzarlo
   despues contra msdb.dbo.sysmail_allitems y saber si el correo
   realmente salio (no solo que se encolo).
   ============================================================ */

IF COL_LENGTH('dbo.NOTIFICACION_SUPERVISOR_PEDIDO', 'mailitem_id') IS NULL
BEGIN
    ALTER TABLE dbo.NOTIFICACION_SUPERVISOR_PEDIDO
        ADD mailitem_id INT NULL;
END;
GO

/* ============================================================
   SP: SP_NOTIFICACIONES_SUPERVISOR_ENVIAR (actualizado)

   Antes: marcaba enviado = 1 apenas sp_send_dbmail terminaba sin
   lanzar error -- eso solo confirma que el correo quedo encolado
   en Database Mail, no que salio de verdad (el envio real lo hace
   un proceso aparte, asincrono).

   Ahora:

   PASO 1 - Reconciliar: revisa filas que ya tienen mailitem_id
   pero siguen con enviado = 0 (de corridas anteriores que no
   habian confirmado todavia), y actualiza su estado real contra
   msdb.dbo.sysmail_allitems.

   PASO 2 - Enviar: toma hasta 50 pendientes SIN mailitem_id
   (nunca intentados, o que fallaron de verdad y se limpiaron
   para reintentar) y los encola con sp_send_dbmail, guardando
   el mailitem_id que devuelve.

   PASO 3 - Esperar un poco (Database Mail normalmente procesa en
   segundos) y reconciliar otra vez, ahora para el lote que se
   acaba de mandar.

   Si el envio fallo de verdad (sent_status = 'failed'), se limpia
   mailitem_id para que el pendiente se reintente en la siguiente
   corrida (hasta agotar 5 intentos), y error_envio queda con el
   motivo real tomado de msdb.dbo.sysmail_event_log.
   ============================================================ */

CREATE OR ALTER PROCEDURE [dbo].[SP_NOTIFICACIONES_SUPERVISOR_ENVIAR]
AS
BEGIN
    SET NOCOUNT ON;

    /* ============================================================
       PASO 1: reconciliar envios pendientes de corridas anteriores
       ============================================================ */
    UPDATE N
    SET
        N.enviado = CASE WHEN M.sent_status = 'sent' THEN 1 ELSE 0 END,
        N.fecha_envio = CASE WHEN M.sent_status = 'sent' THEN M.sent_date ELSE N.fecha_envio END,
        N.mailitem_id = CASE WHEN M.sent_status = 'failed' THEN NULL ELSE N.mailitem_id END,
        N.error_envio = CASE
            WHEN M.sent_status = 'sent' THEN NULL
            WHEN M.sent_status = 'failed' THEN ISNULL(
                (
                    SELECT TOP 1 L.description
                    FROM msdb.dbo.sysmail_event_log L
                    WHERE L.mailitem_id = M.mailitem_id
                    ORDER BY L.log_date DESC
                ),
                N'Fallo el envio real (sysmail_allitems.sent_status = failed).'
            )
            ELSE CONCAT(N'Database Mail aun no confirma el envio (estado actual: ', M.sent_status, N').')
        END
    FROM dbo.NOTIFICACION_SUPERVISOR_PEDIDO N
    INNER JOIN msdb.dbo.sysmail_allitems M
        ON M.mailitem_id = N.mailitem_id
    WHERE N.mailitem_id IS NOT NULL
      AND N.enviado = 0;

    /* ============================================================
       PASO 2: enviar pendientes nuevos (nunca intentados o
       reintentos tras fallo confirmado)
       ============================================================ */
    DECLARE
        @id_notificacion BIGINT,
        @id_pedido_gestion BIGINT,
        @OrderCode NVARCHAR(100),
        @Farmacia NVARCHAR(100),
        @Supervisor NVARCHAR(300),
        @Correo NVARCHAR(320),
        @CorreoFarmacia NVARCHAR(320),
        @Destinatarios NVARCHAR(700),

        @CustomerName NVARCHAR(300),
        @CustomerPhone NVARCHAR(100),
        @CustomerEmail NVARCHAR(300),
        @RecipientName NVARCHAR(300),
        @Total DECIMAL(18,2),
        @PaymentStatus NVARCHAR(100),
        @BranchName NVARCHAR(300),

        @Asunto NVARCHAR(255),
        @Cuerpo NVARCHAR(MAX),
        @mailitem_id INT,
        @error NVARCHAR(1000);

    DECLARE cur_notificaciones CURSOR LOCAL FAST_FORWARD FOR
        SELECT TOP 50
            N.id_notificacion,
            N.id_pedido_gestion,
            N.OrderCode,
            N.farmacia,
            N.supervisor,
            N.correo,
            N.correo_farmacia,

            PG.CustomerName,
            PG.CustomerPhone,
            PG.CustomerEmail,
            PG.RecipientName,
            PG.Total,
            PG.PaymentStatus,
            PG.BranchName

        FROM dbo.NOTIFICACION_SUPERVISOR_PEDIDO N
        INNER JOIN dbo.PEDIDO_GESTION PG
            ON PG.id_pedido_gestion = N.id_pedido_gestion
        WHERE N.enviado = 0
          AND N.intentos < 5
          AND N.mailitem_id IS NULL
        ORDER BY N.id_notificacion;

    OPEN cur_notificaciones;

    FETCH NEXT FROM cur_notificaciones INTO
        @id_notificacion,
        @id_pedido_gestion,
        @OrderCode,
        @Farmacia,
        @Supervisor,
        @Correo,
        @CorreoFarmacia,
        @CustomerName,
        @CustomerPhone,
        @CustomerEmail,
        @RecipientName,
        @Total,
        @PaymentStatus,
        @BranchName;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY

            SET @Destinatarios = NULL;

            SET @Correo = NULLIF(LTRIM(RTRIM(@Correo)), '');
            SET @CorreoFarmacia = NULLIF(LTRIM(RTRIM(@CorreoFarmacia)), '');

            IF @Correo IS NOT NULL AND @CorreoFarmacia IS NOT NULL
            BEGIN
                IF @Correo COLLATE DATABASE_DEFAULT =
                   @CorreoFarmacia COLLATE DATABASE_DEFAULT
                BEGIN
                    SET @Destinatarios = @Correo;
                END
                ELSE
                BEGIN
                    SET @Destinatarios = @Correo + N';' + @CorreoFarmacia;
                END
            END
            ELSE IF @Correo IS NOT NULL
            BEGIN
                SET @Destinatarios = @Correo;
            END
            ELSE IF @CorreoFarmacia IS NOT NULL
            BEGIN
                SET @Destinatarios = @CorreoFarmacia;
            END;

            IF @Destinatarios IS NULL
            BEGIN
                THROW 50001, 'La notificación no tiene correo de supervisor ni correo de farmacia.', 1;
            END;

            SET @Asunto = CONCAT(
                N'Nuevo pedido recibido - ',
                ISNULL(@BranchName, ISNULL(@Farmacia, N'Farmacia')),
                N' - ',
                ISNULL(@OrderCode, N'Sin código')
            );

            SET @Cuerpo = CONCAT(
                N'<html>',
                N'<body style="font-family:Arial,Helvetica,sans-serif;font-size:14px;color:#333;">',

                N'<h2 style="margin-bottom:5px;">Nuevo pedido recibido</h2>',

                N'<p>La farmacia <strong>',
                ISNULL(@BranchName, ISNULL(@Farmacia, N'Farmacia')),
                N'</strong> ha recibido un nuevo pedido.</p>',

                N'<table style="border-collapse:collapse;width:600px;">',

                N'<tr>',
                N'<td style="padding:8px;border:1px solid #ddd;"><strong>Código del pedido</strong></td>',
                N'<td style="padding:8px;border:1px solid #ddd;">',
                ISNULL(@OrderCode, N'No disponible'),
                N'</td>',
                N'</tr>',

                N'<tr>',
                N'<td style="padding:8px;border:1px solid #ddd;"><strong>Farmacia</strong></td>',
                N'<td style="padding:8px;border:1px solid #ddd;">',
                ISNULL(@BranchName, ISNULL(@Farmacia, N'No disponible')),
                N'</td>',
                N'</tr>',

                N'<tr>',
                N'<td style="padding:8px;border:1px solid #ddd;"><strong>Nombre del cliente</strong></td>',
                N'<td style="padding:8px;border:1px solid #ddd;">',
                ISNULL(@CustomerName, N'No disponible'),
                N'</td>',
                N'</tr>',

                N'<tr>',
                N'<td style="padding:8px;border:1px solid #ddd;"><strong>Teléfono del cliente</strong></td>',
                N'<td style="padding:8px;border:1px solid #ddd;">',
                ISNULL(@CustomerPhone, N'No disponible'),
                N'</td>',
                N'</tr>',

                N'<tr>',
                N'<td style="padding:8px;border:1px solid #ddd;"><strong>Correo del cliente</strong></td>',
                N'<td style="padding:8px;border:1px solid #ddd;">',
                ISNULL(@CustomerEmail, N'No disponible'),
                N'</td>',
                N'</tr>',

                N'<tr>',
                N'<td style="padding:8px;border:1px solid #ddd;"><strong>Nombre del destinatario</strong></td>',
                N'<td style="padding:8px;border:1px solid #ddd;">',
                ISNULL(@RecipientName, N'No disponible'),
                N'</td>',
                N'</tr>',

                N'<tr>',
                N'<td style="padding:8px;border:1px solid #ddd;"><strong>Total del pedido</strong></td>',
                N'<td style="padding:8px;border:1px solid #ddd;"><strong>L ',
                ISNULL(FORMAT(@Total, 'N2'), N'0.00'),
                N'</strong></td>',
                N'</tr>',

                N'<tr>',
                N'<td style="padding:8px;border:1px solid #ddd;"><strong>Estado del pago</strong></td>',
                N'<td style="padding:8px;border:1px solid #ddd;">',
                ISNULL(@PaymentStatus, N'No disponible'),
                N'</td>',
                N'</tr>',

                N'</table>',

                N'<br>',

                N'<p style="font-size:12px;color:#777;">',
                N'Notificación automática del sistema de gestión de pedidos.',
                N'</p>',

                N'</body>',
                N'</html>'
            );

            SET @mailitem_id = NULL;

            EXEC msdb.dbo.sp_send_dbmail
                @profile_name = N'Alertas',
                @recipients = @Destinatarios,
                @subject = @Asunto,
                @body = @Cuerpo,
                @body_format = 'HTML',
                @mailitem_id = @mailitem_id OUTPUT;

            UPDATE dbo.NOTIFICACION_SUPERVISOR_PEDIDO
            SET
                mailitem_id = @mailitem_id,
                intentos = intentos + 1,
                error_envio = N'Encolado, esperando confirmación de envío real.'
            WHERE id_notificacion = @id_notificacion;

        END TRY
        BEGIN CATCH

            UPDATE dbo.NOTIFICACION_SUPERVISOR_PEDIDO
            SET
                intentos = intentos + 1,
                error_envio = LEFT(ERROR_MESSAGE(), 1000)
            WHERE id_notificacion = @id_notificacion;

        END CATCH;

        FETCH NEXT FROM cur_notificaciones INTO
            @id_notificacion,
            @id_pedido_gestion,
            @OrderCode,
            @Farmacia,
            @Supervisor,
            @Correo,
            @CorreoFarmacia,
            @CustomerName,
            @CustomerPhone,
            @CustomerEmail,
            @RecipientName,
            @Total,
            @PaymentStatus,
            @BranchName;
    END;

    CLOSE cur_notificaciones;
    DEALLOCATE cur_notificaciones;

    /* ============================================================
       PASO 3: dar tiempo a Database Mail y reconciliar el lote
       que se acaba de mandar en este PASO 2
       ============================================================ */
    WAITFOR DELAY '00:00:08';

    UPDATE N
    SET
        N.enviado = CASE WHEN M.sent_status = 'sent' THEN 1 ELSE 0 END,
        N.fecha_envio = CASE WHEN M.sent_status = 'sent' THEN M.sent_date ELSE N.fecha_envio END,
        N.mailitem_id = CASE WHEN M.sent_status = 'failed' THEN NULL ELSE N.mailitem_id END,
        N.error_envio = CASE
            WHEN M.sent_status = 'sent' THEN NULL
            WHEN M.sent_status = 'failed' THEN ISNULL(
                (
                    SELECT TOP 1 L.description
                    FROM msdb.dbo.sysmail_event_log L
                    WHERE L.mailitem_id = M.mailitem_id
                    ORDER BY L.log_date DESC
                ),
                N'Fallo el envio real (sysmail_allitems.sent_status = failed).'
            )
            ELSE CONCAT(N'Database Mail aun no confirma el envio (estado actual: ', M.sent_status, N').')
        END
    FROM dbo.NOTIFICACION_SUPERVISOR_PEDIDO N
    INNER JOIN msdb.dbo.sysmail_allitems M
        ON M.mailitem_id = N.mailitem_id
    WHERE N.mailitem_id IS NOT NULL
      AND N.enviado = 0;
END;
GO
