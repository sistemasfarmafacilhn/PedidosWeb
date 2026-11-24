USE [PedidosWeb]
GO

/* ============================================================
   PEDIDO_PICKUP_ALERTA_CORREO: nueva columna mailitem_id, mismo
   proposito que en NOTIFICACION_SUPERVISOR_PEDIDO.
   ============================================================ */

IF COL_LENGTH('dbo.PEDIDO_PICKUP_ALERTA_CORREO', 'mailitem_id') IS NULL
BEGIN
    ALTER TABLE dbo.PEDIDO_PICKUP_ALERTA_CORREO
        ADD mailitem_id INT NULL;
END;
GO

/* ============================================================
   SP: SP_ENVIAR_ALERTAS_PICKUP_SUPERVISOR (actualizado)

   Mismo cambio que SP_NOTIFICACIONES_SUPERVISOR_ENVIAR: ya no
   marca estado = 1 (enviado) apenas sp_send_dbmail termina sin
   error -- eso solo confirma que se encolo. Ahora:

   PASO 1 - Reconciliar pendientes de corridas anteriores.
   PASO 2 - Enviar nuevos (estado=0, intentos<5, sin mailitem_id).
   PASO 3 - Esperar y reconciliar el lote recien enviado.

   estado: 0 = pendiente, 1 = enviado (confirmado), 2 = fallido
   definitivo (agoto los 5 intentos). Igual que antes, pero ahora
   estado = 1 solo se pone tras confirmar sent_status = 'sent' en
   msdb.dbo.sysmail_allitems.
   ============================================================ */

CREATE OR ALTER PROCEDURE [dbo].[SP_ENVIAR_ALERTAS_PICKUP_SUPERVISOR]
AS
BEGIN
    SET NOCOUNT ON;

    /* ============================================================
       PASO 1: reconciliar alertas pendientes de corridas anteriores
       ============================================================ */
    UPDATE Q
    SET
        Q.estado = CASE
            WHEN M.sent_status = 'sent' THEN 1
            WHEN M.sent_status = 'failed' AND Q.intentos >= 5 THEN 2
            ELSE 0
        END,
        Q.fecha_envio = CASE WHEN M.sent_status = 'sent' THEN M.sent_date ELSE Q.fecha_envio END,
        Q.mailitem_id = CASE
            WHEN M.sent_status = 'failed' AND Q.intentos < 5 THEN NULL
            ELSE Q.mailitem_id
        END,
        Q.ultimo_error = CASE
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
    FROM dbo.PEDIDO_PICKUP_ALERTA_CORREO Q
    INNER JOIN msdb.dbo.sysmail_allitems M
        ON M.mailitem_id = Q.mailitem_id
    WHERE Q.mailitem_id IS NOT NULL
      AND Q.estado = 0;

    /* ============================================================
       PASO 2: enviar alertas pendientes nuevas
       ============================================================ */
    DECLARE
        @id_alerta BIGINT,
        @id_pedido_gestion BIGINT,
        @correo NVARCHAR(300),
        @supervisor NVARCHAR(300),
        @OrderCode NVARCHAR(50),
        @OrderIdWeb NVARCHAR(80),
        @BranchId NVARCHAR(80),
        @BranchName NVARCHAR(200),
        @CustomerName NVARCHAR(200),
        @CustomerPhone NVARCHAR(50),
        @CustomerIdentityDocument NVARCHAR(80),
        @Total DECIMAL(18,4),
        @Currency CHAR(3),
        @PaymentMethod NVARCHAR(80),
        @PaymentStatus NVARCHAR(80),
        @fecha_recepcion_local DATETIME2(7),
        @subject NVARCHAR(300),
        @body NVARCHAR(MAX),
        @mailitem_id INT,
        @error NVARCHAR(MAX);

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT TOP 50
            Q.id_alerta,
            Q.id_pedido_gestion,
            Q.SupervisorCorreo,
            Q.SupervisorNombre,
            Q.OrderCode,
            Q.OrderIdWeb,
            Q.BranchId,
            Q.BranchName,
            PG.CustomerName,
            PG.CustomerPhone,
            PG.CustomerIdentityDocument,
            PG.Total,
            PG.Currency,
            PG.PaymentMethod,
            PG.PaymentStatus,
            PG.fecha_recepcion_local
        FROM dbo.PEDIDO_PICKUP_ALERTA_CORREO Q
        INNER JOIN dbo.PEDIDO_GESTION PG
            ON PG.id_pedido_gestion = Q.id_pedido_gestion
        WHERE Q.estado = 0
          AND Q.intentos < 5
          AND Q.mailitem_id IS NULL
        ORDER BY Q.id_alerta ASC;

    OPEN cur;

    FETCH NEXT FROM cur INTO
        @id_alerta,
        @id_pedido_gestion,
        @correo,
        @supervisor,
        @OrderCode,
        @OrderIdWeb,
        @BranchId,
        @BranchName,
        @CustomerName,
        @CustomerPhone,
        @CustomerIdentityDocument,
        @Total,
        @Currency,
        @PaymentMethod,
        @PaymentStatus,
        @fecha_recepcion_local;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY

            SET @subject = N'Nuevo pedido pickup para farmacia supervisada';

            SET @body =
                N'<html>
                    <body style="font-family: Arial, sans-serif; font-size: 14px; color: #333;">
                        <h3 style="color:#6f8f24;">Nuevo pedido pickup</h3>

                        <p>Hola <strong>' + ISNULL(@supervisor, '') + N'</strong>,</p>

                        <p>Se recibió un nuevo pedido tipo <strong>pickup</strong> para una farmacia bajo tu supervisión.</p>

                        <table style="border-collapse: collapse; width: 100%; max-width: 720px;">
                            <tr>
                                <td style="border:1px solid #ddd; padding:8px; font-weight:bold;">Pedido</td>
                                <td style="border:1px solid #ddd; padding:8px;">' + ISNULL(@OrderCode, @OrderIdWeb) + N'</td>
                            </tr>
                            <tr>
                                <td style="border:1px solid #ddd; padding:8px; font-weight:bold;">OrderIdWeb</td>
                                <td style="border:1px solid #ddd; padding:8px;">' + ISNULL(@OrderIdWeb, '') + N'</td>
                            </tr>
                            <tr>
                                <td style="border:1px solid #ddd; padding:8px; font-weight:bold;">Cliente</td>
                                <td style="border:1px solid #ddd; padding:8px;">' + ISNULL(@CustomerName, '') + N'</td>
                            </tr>
                            <tr>
                                <td style="border:1px solid #ddd; padding:8px; font-weight:bold;">Teléfono</td>
                                <td style="border:1px solid #ddd; padding:8px;">' + ISNULL(@CustomerPhone, '') + N'</td>
                            </tr>
                            <tr>
                                <td style="border:1px solid #ddd; padding:8px; font-weight:bold;">Identidad</td>
                                <td style="border:1px solid #ddd; padding:8px;">' + ISNULL(@CustomerIdentityDocument, '') + N'</td>
                            </tr>
                            <tr>
                                <td style="border:1px solid #ddd; padding:8px; font-weight:bold;">Sucursal</td>
                                <td style="border:1px solid #ddd; padding:8px;">' + ISNULL(@BranchId, '') + N' - ' + ISNULL(@BranchName, '') + N'</td>
                            </tr>
                            <tr>
                                <td style="border:1px solid #ddd; padding:8px; font-weight:bold;">Total</td>
                                <td style="border:1px solid #ddd; padding:8px;">' + ISNULL(@Currency, 'HNL') + N' ' + CONVERT(NVARCHAR(50), ISNULL(@Total, 0)) + N'</td>
                            </tr>
                            <tr>
                                <td style="border:1px solid #ddd; padding:8px; font-weight:bold;">Pago</td>
                                <td style="border:1px solid #ddd; padding:8px;">' + ISNULL(@PaymentMethod, '') + N' / ' + ISNULL(@PaymentStatus, '') + N'</td>
                            </tr>
                            <tr>
                                <td style="border:1px solid #ddd; padding:8px; font-weight:bold;">Fecha recepción</td>
                                <td style="border:1px solid #ddd; padding:8px;">' + CONVERT(NVARCHAR(30), @fecha_recepcion_local, 120) + N'</td>
                            </tr>
                        </table>

                        <p style="margin-top:18px;">Favor revisar el pedido en el sistema de Pedidos Web.</p>

                        <p style="color:#777; font-size:12px;">Correo generado automáticamente por Pedidos Web.</p>
                    </body>
                </html>';

            SET @mailitem_id = NULL;

            EXEC msdb.dbo.sp_send_dbmail
                @profile_name = 'Alertas',
                @recipients = @correo,
                @subject = @subject,
                @body = @body,
                @body_format = 'HTML',
                @mailitem_id = @mailitem_id OUTPUT;

            UPDATE dbo.PEDIDO_PICKUP_ALERTA_CORREO
            SET
                mailitem_id = @mailitem_id,
                intentos = intentos + 1,
                ultimo_error = N'Encolado, esperando confirmación de envío real.'
            WHERE id_alerta = @id_alerta;

        END TRY
        BEGIN CATCH

            SET @error = ERROR_MESSAGE();

            UPDATE dbo.PEDIDO_PICKUP_ALERTA_CORREO
            SET estado = CASE WHEN intentos + 1 >= 5 THEN 2 ELSE 0 END,
                intentos = intentos + 1,
                ultimo_error = @error
            WHERE id_alerta = @id_alerta;

        END CATCH;

        FETCH NEXT FROM cur INTO
            @id_alerta,
            @id_pedido_gestion,
            @correo,
            @supervisor,
            @OrderCode,
            @OrderIdWeb,
            @BranchId,
            @BranchName,
            @CustomerName,
            @CustomerPhone,
            @CustomerIdentityDocument,
            @Total,
            @Currency,
            @PaymentMethod,
            @PaymentStatus,
            @fecha_recepcion_local;
    END;

    CLOSE cur;
    DEALLOCATE cur;

    /* ============================================================
       PASO 3: dar tiempo a Database Mail y reconciliar el lote
       que se acaba de mandar en este PASO 2
       ============================================================ */
    WAITFOR DELAY '00:00:08';

    UPDATE Q
    SET
        Q.estado = CASE
            WHEN M.sent_status = 'sent' THEN 1
            WHEN M.sent_status = 'failed' AND Q.intentos >= 5 THEN 2
            ELSE 0
        END,
        Q.fecha_envio = CASE WHEN M.sent_status = 'sent' THEN M.sent_date ELSE Q.fecha_envio END,
        Q.mailitem_id = CASE
            WHEN M.sent_status = 'failed' AND Q.intentos < 5 THEN NULL
            ELSE Q.mailitem_id
        END,
        Q.ultimo_error = CASE
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
    FROM dbo.PEDIDO_PICKUP_ALERTA_CORREO Q
    INNER JOIN msdb.dbo.sysmail_allitems M
        ON M.mailitem_id = Q.mailitem_id
    WHERE Q.mailitem_id IS NOT NULL
      AND Q.estado = 0;
END;
GO
