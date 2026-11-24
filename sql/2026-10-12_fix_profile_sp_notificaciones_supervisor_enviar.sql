USE PedidosWeb;
GO
-- Correccion: 'profile name is not valid' al enviar notificaciones a supervisores.
-- El perfil de Database Mail ya no esta fijo: se valida y se usa uno de respaldo.
ALTER PROCEDURE [dbo].[SP_NOTIFICACIONES_SUPERVISOR_ENVIAR]
AS
BEGIN
    SET NOCOUNT ON;

    /* ============================================================
       VALIDAR PERFIL DE DATABASE MAIL (una sola vez, antes del cursor)
       - Preferido: 'Alertas'
       - Si no existe en este servidor, usa el primer perfil disponible
       - Si no hay ninguno, falla sin consumir intentos de las notificaciones
       ============================================================ */
    DECLARE @PerfilCorreo SYSNAME = N'Alertas';

    CREATE TABLE #PerfilesMail (
        profile_id INT,
        name SYSNAME,
        description NVARCHAR(256) NULL
    );

    INSERT INTO #PerfilesMail (profile_id, name, description)
    EXEC msdb.dbo.sysmail_help_profile_sp;

    IF NOT EXISTS (SELECT 1 FROM #PerfilesMail WHERE name = @PerfilCorreo)
    BEGIN
        SELECT TOP (1) @PerfilCorreo = name
        FROM #PerfilesMail
        ORDER BY profile_id;
    END;

    IF NOT EXISTS (SELECT 1 FROM #PerfilesMail WHERE name = @PerfilCorreo)
    BEGIN
        DROP TABLE #PerfilesMail;
        THROW 50002, 'No existe ningun perfil de Database Mail configurado en este servidor (msdb). Configure uno antes de ejecutar el SP.', 1;
    END;

    DROP TABLE #PerfilesMail;

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
        @Cuerpo NVARCHAR(MAX);

    DECLARE cur_notificaciones CURSOR LOCAL FAST_FORWARD FOR
        SELECT
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

            /* ============================================================
               ARMAR DESTINATARIOS
               SUPERVISOR + FARMACIA
               ============================================================ */

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

            /* ============================================================
               ASUNTO
               ============================================================ */

            SET @Asunto = CONCAT(
                N'Nuevo pedido recibido - ',
                ISNULL(@BranchName, ISNULL(@Farmacia, N'Farmacia')),
                N' - ',
                ISNULL(@OrderCode, N'Sin código')
            );

            /* ============================================================
               CUERPO
               ============================================================ */

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

            /* ============================================================
               ENVIAR A SUPERVISOR + FARMACIA
               ============================================================ */

            EXEC msdb.dbo.sp_send_dbmail
                @profile_name = @PerfilCorreo,
                @recipients = @Destinatarios,
                @subject = @Asunto,
                @body = @Cuerpo,
                @body_format = 'HTML';

            UPDATE dbo.NOTIFICACION_SUPERVISOR_PEDIDO
            SET
                enviado = 1,
                fecha_envio = SYSDATETIME(),
                intentos = intentos + 1,
                error_envio = NULL
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
END;
GO
