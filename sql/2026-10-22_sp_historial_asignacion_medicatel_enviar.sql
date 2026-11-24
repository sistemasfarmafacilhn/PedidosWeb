USE [PedidosWeb]
GO

/* ============================================================
   HISTORICO_ASIGNACION_PEDIDO: se agregan columnas de control
   de envio. Como es un log append-only (cada fila es un evento
   inmutable, nunca se actualiza), no necesita pendiente_envio/
   version como NOTIFICACION_MEDICATEL_PEDIDO -- basta con saber
   si ya se envio o no.
   ============================================================ */

ALTER TABLE dbo.HISTORICO_ASIGNACION_PEDIDO
    ADD enviado     BIT NOT NULL DEFAULT (0),
        fecha_envio DATETIME2(7) NULL,
        intentos    INT NOT NULL DEFAULT (0),
        error_envio NVARCHAR(1000) NULL;
GO

CREATE INDEX IX_HISTORICO_ASIGNACION_PEDIDO_PENDIENTES
    ON dbo.HISTORICO_ASIGNACION_PEDIDO (enviado)
    WHERE enviado = 0;
GO

/* ============================================================
   SP: SP_HISTORIAL_ASIGNACION_MEDICATEL_ENVIAR

   Pensado para un SQL Agent Job (ej. cada minuto, igual que
   SP_NOTIFICACIONES_MEDICATEL_ENVIAR).

   Toma hasta 50 filas con enviado = 0 (y menos de 5 intentos) de
   HISTORICO_ASIGNACION_PEDIDO, las inserta tal cual en
   dbo.PedidosWebHistorialAsignacion del lado de Medicatel (via el
   mismo linked server que ya se usa), y marca el resultado por
   fila. Un fallo en una fila no detiene las demas.
   ============================================================ */

CREATE OR ALTER PROCEDURE [dbo].[SP_HISTORIAL_ASIGNACION_MEDICATEL_ENVIAR]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @id_historico       BIGINT,
        @IdPedidoWeb        BIGINT,
        @OrderCode          NVARCHAR(50),
        @numero_asignacion  INT,
        @StaffID            NVARCHAR(50),
        @NombreAsignado     NVARCHAR(200),
        @DeliveryType       NVARCHAR(30),
        @StaffID_anterior   NVARCHAR(50),
        @fecha_asignacion   DATETIME2(7),
        @observacion        NVARCHAR(500),
        @error              NVARCHAR(1000);

    DECLARE cur_pendientes CURSOR LOCAL FAST_FORWARD FOR
        SELECT TOP 50
            H.id_historico,
            PG.IdPedidoWeb,
            H.OrderCode,
            H.numero_asignacion,
            H.StaffID,
            H.NombreAsignado,
            H.DeliveryType,
            H.StaffID_anterior,
            H.fecha_asignacion,
            H.observacion
        FROM dbo.HISTORICO_ASIGNACION_PEDIDO H
        INNER JOIN dbo.PEDIDO_GESTION PG
            ON PG.id_pedido_gestion = H.id_pedido_gestion
        WHERE H.enviado = 0
          AND H.intentos < 5
        ORDER BY H.id_historico ASC;

    OPEN cur_pendientes;

    FETCH NEXT FROM cur_pendientes INTO
        @id_historico, @IdPedidoWeb, @OrderCode, @numero_asignacion,
        @StaffID, @NombreAsignado, @DeliveryType, @StaffID_anterior,
        @fecha_asignacion, @observacion;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY

            INSERT INTO [145.223.79.81,1433\API_MEDICATEL].[DB_COSAVAL_MEDICATEL].dbo.PedidosWebHistorialAsignacion
            (
                IdPedidoWeb,
                OrderCode,
                NumeroAsignacion,
                StaffID,
                NombreAsignado,
                DeliveryType,
                StaffIDAnterior,
                FechaAsignacion,
                Observacion
            )
            VALUES
            (
                @IdPedidoWeb,
                @OrderCode,
                @numero_asignacion,
                @StaffID,
                @NombreAsignado,
                @DeliveryType,
                @StaffID_anterior,
                @fecha_asignacion,
                @observacion
            );

            UPDATE dbo.HISTORICO_ASIGNACION_PEDIDO
            SET
                enviado     = 1,
                fecha_envio = SYSDATETIME(),
                intentos    = intentos + 1,
                error_envio = NULL
            WHERE id_historico = @id_historico;

        END TRY
        BEGIN CATCH

            SET @error = ERROR_MESSAGE();

            UPDATE dbo.HISTORICO_ASIGNACION_PEDIDO
            SET
                intentos    = intentos + 1,
                error_envio = LEFT(@error, 1000)
            WHERE id_historico = @id_historico;

        END CATCH;

        FETCH NEXT FROM cur_pendientes INTO
            @id_historico, @IdPedidoWeb, @OrderCode, @numero_asignacion,
            @StaffID, @NombreAsignado, @DeliveryType, @StaffID_anterior,
            @fecha_asignacion, @observacion;
    END;

    CLOSE cur_pendientes;
    DEALLOCATE cur_pendientes;
END;
GO
