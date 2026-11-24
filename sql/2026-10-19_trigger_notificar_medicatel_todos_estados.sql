USE [PedidosWeb]
GO

/* ============================================================
   CAMBIO DE ALCANCE: ya no se notifican solo Cerrado/Cancelado,
   se notifican TODOS los estados del pedido (Abierto, En
   Preparacion, Listo para Despacho, En Ruta, Cerrado, Cancelado).
   Cada cambio de estado relevante genera un nuevo envio/reenvio,
   para que Medicatel pueda dar seguimiento al ciclo completo.
   ============================================================ */

ALTER TABLE dbo.NOTIFICACION_MEDICATEL_PEDIDO
    DROP CONSTRAINT CK_NOTIFICACION_MEDICATEL_ESTADO;
GO

ALTER TABLE dbo.NOTIFICACION_MEDICATEL_PEDIDO
    ADD CONSTRAINT CK_NOTIFICACION_MEDICATEL_ESTADO
        CHECK (estado_control IN (0, 1, 2, 3, 4, 5));
GO

-- Ya no siempre hay fecha de cierre/cancelacion (estados intermedios no la tienen)
ALTER TABLE dbo.NOTIFICACION_MEDICATEL_PEDIDO
    ALTER COLUMN fecha_cierre_cancelacion DATETIME2(7) NULL;
GO

/* ============================================================
   TRIGGER: TR_PEDIDO_CONTROL_NOTIFICAR_MEDICATEL (actualizado)

   - Se quita el filtro "WHERE estado IN (1,2)": ahora procesa
     cualquier estado (0 a 5).
   - estado_control_descripcion cubre los 6 estados, mismos
     textos que ya usa SP_PEDIDOS_ABIERTOS_POR_AGENTE.
   - fecha_cierre_cancelacion solo se llena cuando estado es
     Cerrado o Cancelado (1,2); en los demas queda NULL.
   - motivo_cancelacion solo se llena cuando estado = 2.
   - El resto de la logica (resolver nombre de farmacia para
     pickup, MERGE para no duplicar fila por pedido, version_envio
     que sube con cada cambio relevante) queda igual.
   ============================================================ */

CREATE OR ALTER TRIGGER [dbo].[TR_PEDIDO_CONTROL_NOTIFICAR_MEDICATEL]
ON [dbo].[PEDIDO_CONTROL]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH ORIGEN AS
    (
        SELECT
            I.id_control_pedido,
            I.id_pedido_gestion,
            PG.IdPedidoWeb,
            PG.OrderCode,

            I.estado AS estado_control,
            CASE I.estado
                WHEN 0 THEN N'Abierto'
                WHEN 1 THEN N'Cerrado'
                WHEN 2 THEN N'Cancelado'
                WHEN 3 THEN N'En Preparación'
                WHEN 4 THEN N'Listo para Despacho'
                WHEN 5 THEN N'En Ruta'
                ELSE N'Desconocido'
            END AS estado_control_descripcion,

            CASE
                WHEN LOWER(LTRIM(RTRIM(ISNULL(PG.DeliveryType, '')))) = 'pickup'
                    THEN ISNULL(FARM.NombreFarmacia, I.StaffID COLLATE DATABASE_DEFAULT)
                ELSE I.StaffID COLLATE DATABASE_DEFAULT
            END COLLATE DATABASE_DEFAULT AS StaffID_asignado,
            I.fecha_asignacion,

            CASE
                WHEN LOWER(LTRIM(RTRIM(ISNULL(PG.DeliveryType, '')))) = 'pickup'
                    THEN ISNULL(FARM.NombreFarmacia, I.StaffID COLLATE DATABASE_DEFAULT)
                ELSE I.StaffID COLLATE DATABASE_DEFAULT
            END COLLATE DATABASE_DEFAULT AS StaffID_cierre_cancelacion,

            CASE
                WHEN I.estado IN (1, 2)
                    THEN COALESCE(I.fecha_cierre, I.fecha_cancelacion)
                ELSE NULL
            END AS fecha_cierre_cancelacion,

            CASE WHEN I.estado = 2 THEN I.observacion ELSE NULL END AS motivo_cancelacion

        FROM inserted I
        INNER JOIN dbo.PEDIDO_GESTION PG
            ON PG.id_pedido_gestion = I.id_pedido_gestion
        OUTER APPLY
        (
            SELECT TOP 1
                LTRIM(RTRIM(REPLACE(REPLACE(V.NAME, CHAR(13), ' '), CHAR(10), ' '))) AS NombreFarmacia
            FROM dbo.VW_FARMACIAS_SUPERVISOR V
            WHERE LTRIM(RTRIM(V.STOREID)) COLLATE DATABASE_DEFAULT =
                  LTRIM(RTRIM(I.StaffID)) COLLATE DATABASE_DEFAULT
        ) FARM
        -- sin WHERE de estado: se procesan todos (0 a 5)
    )

    MERGE dbo.NOTIFICACION_MEDICATEL_PEDIDO AS DESTINO
    USING ORIGEN AS O
        ON DESTINO.id_control_pedido = O.id_control_pedido

    WHEN MATCHED
      AND (
                DESTINO.estado_control <> O.estado_control
            OR  ISNULL(DESTINO.StaffID_asignado, N'')  <> ISNULL(O.StaffID_asignado, N'')
            OR  ISNULL(DESTINO.fecha_asignacion, '19000101') <> ISNULL(O.fecha_asignacion, '19000101')
            OR  ISNULL(DESTINO.StaffID_cierre_cancelacion, N'') <> ISNULL(O.StaffID_cierre_cancelacion, N'')
            OR  ISNULL(DESTINO.fecha_cierre_cancelacion, '19000101') <> ISNULL(O.fecha_cierre_cancelacion, '19000101')
            OR  ISNULL(DESTINO.motivo_cancelacion, N'') <> ISNULL(O.motivo_cancelacion, N'')
          )
    THEN UPDATE SET
        estado_control              = O.estado_control,
        estado_control_descripcion  = O.estado_control_descripcion,
        StaffID_asignado            = O.StaffID_asignado,
        fecha_asignacion            = O.fecha_asignacion,
        StaffID_cierre_cancelacion  = O.StaffID_cierre_cancelacion,
        fecha_cierre_cancelacion    = O.fecha_cierre_cancelacion,
        motivo_cancelacion          = O.motivo_cancelacion,
        version_envio               = DESTINO.version_envio + 1,
        pendiente_envio             = 1,
        enviado                     = 0,
        intentos                    = 0,
        error_envio                 = NULL,
        fecha_actualizacion         = SYSDATETIME()

    WHEN NOT MATCHED BY TARGET THEN
        INSERT
        (
            id_pedido_gestion, id_control_pedido, IdPedidoWeb, OrderCode,
            estado_control, estado_control_descripcion,
            StaffID_asignado, fecha_asignacion,
            StaffID_cierre_cancelacion, fecha_cierre_cancelacion,
            motivo_cancelacion,
            version_envio, pendiente_envio, enviado, intentos, error_envio,
            fecha_creacion, fecha_actualizacion
        )
        VALUES
        (
            O.id_pedido_gestion, O.id_control_pedido, O.IdPedidoWeb, O.OrderCode,
            O.estado_control, O.estado_control_descripcion,
            O.StaffID_asignado, O.fecha_asignacion,
            O.StaffID_cierre_cancelacion, O.fecha_cierre_cancelacion,
            O.motivo_cancelacion,
            1, 1, 0, 0, NULL,
            SYSDATETIME(), SYSDATETIME()
        );
END;
GO
