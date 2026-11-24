USE [PedidosWeb]
GO

/* ============================================================
   SP: SP_NOTIFICACIONES_MEDICATEL_ENVIAR

   Pensado para correr desde un SQL Agent Job cada minuto.

   Toma hasta 50 pedidos con pendiente_envio = 1 (y menos de 5
   intentos fallidos) de NOTIFICACION_MEDICATEL_PEDIDO, los inserta
   como un evento mas en dbo.PedidosWebEstado del lado de Medicatel
   (via el linked server que ya se usa para importar pedidos), y
   marca el resultado por fila:

     - Si el INSERT tuvo exito:
         enviado = 1, pendiente_envio = 0, fecha_envio = ahora,
         intentos += 1, error_envio = NULL.

     - Si fallo (linked server caido, tabla sin permisos, etc.):
         intentos += 1, error_envio = mensaje de error.
         pendiente_envio sigue en 1, asi que el proximo minuto
         se vuelve a intentar, hasta agotar los 5 intentos.

   Mismo patron que SP_ENVIAR_ALERTAS_PICKUP_SUPERVISOR y
   SP_NOTIFICACIONES_SUPERVISOR_ENVIAR: top N por corrida, cursor,
   TRY/CATCH por fila, no se detiene toda la corrida por un solo
   error.
   ============================================================ */

CREATE OR ALTER PROCEDURE [dbo].[SP_NOTIFICACIONES_MEDICATEL_ENVIAR]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @id_notificacion_medicatel  BIGINT,
        @IdPedidoWeb                BIGINT,
        @OrderCode                  NVARCHAR(50),
        @EstadoPedido               NVARCHAR(20),
        @StaffIDAsignado            NVARCHAR(50),
        @FechaAsignacion            DATETIME2(7),
        @StaffIDCierreCancelacion   NVARCHAR(50),
        @FechaCierreCancelacion     DATETIME2(7),
        @MotivoCancelacion          NVARCHAR(300),
        @VersionEnvio               INT,
        @error                      NVARCHAR(1000);

    DECLARE cur_pendientes CURSOR LOCAL FAST_FORWARD FOR
        SELECT TOP 50
            N.id_notificacion_medicatel,
            N.IdPedidoWeb,
            N.OrderCode,
            N.estado_control_descripcion,
            N.StaffID_asignado,
            N.fecha_asignacion,
            N.StaffID_cierre_cancelacion,
            N.fecha_cierre_cancelacion,
            N.motivo_cancelacion,
            N.version_envio
        FROM dbo.NOTIFICACION_MEDICATEL_PEDIDO N
        WHERE N.pendiente_envio = 1
          AND N.intentos < 5
        ORDER BY N.id_notificacion_medicatel ASC;

    OPEN cur_pendientes;

    FETCH NEXT FROM cur_pendientes INTO
        @id_notificacion_medicatel, @IdPedidoWeb, @OrderCode, @EstadoPedido,
        @StaffIDAsignado, @FechaAsignacion,
        @StaffIDCierreCancelacion, @FechaCierreCancelacion,
        @MotivoCancelacion, @VersionEnvio;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY

            INSERT INTO [145.223.79.81,1433\API_MEDICATEL].[DB_COSAVAL_MEDICATEL].dbo.PedidosWebEstado
            (
                IdPedidoWeb,
                OrderCode,
                EstadoPedido,
                StaffIDAsignado,
                FechaAsignacion,
                StaffIDCierreCancelacion,
                FechaCierreCancelacion,
                MotivoCancelacion,
                VersionEnvio
            )
            VALUES
            (
                @IdPedidoWeb,
                @OrderCode,
                @EstadoPedido,
                @StaffIDAsignado,
                @FechaAsignacion,
                @StaffIDCierreCancelacion,
                @FechaCierreCancelacion,
                @MotivoCancelacion,
                @VersionEnvio
            );

            UPDATE dbo.NOTIFICACION_MEDICATEL_PEDIDO
            SET
                enviado             = 1,
                pendiente_envio     = 0,
                fecha_envio         = SYSDATETIME(),
                intentos            = intentos + 1,
                error_envio         = NULL,
                fecha_actualizacion = SYSDATETIME()
            WHERE id_notificacion_medicatel = @id_notificacion_medicatel;

        END TRY
        BEGIN CATCH

            SET @error = ERROR_MESSAGE();

            UPDATE dbo.NOTIFICACION_MEDICATEL_PEDIDO
            SET
                intentos            = intentos + 1,
                error_envio         = LEFT(@error, 1000),
                fecha_actualizacion = SYSDATETIME()
            WHERE id_notificacion_medicatel = @id_notificacion_medicatel;

        END CATCH;

        FETCH NEXT FROM cur_pendientes INTO
            @id_notificacion_medicatel, @IdPedidoWeb, @OrderCode, @EstadoPedido,
            @StaffIDAsignado, @FechaAsignacion,
            @StaffIDCierreCancelacion, @FechaCierreCancelacion,
            @MotivoCancelacion, @VersionEnvio;
    END;

    CLOSE cur_pendientes;
    DEALLOCATE cur_pendientes;
END;
GO
