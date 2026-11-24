USE [PedidosWeb]
GO

/* ============================================================
   NOTIFICACION_MEDICATEL_PEDIDO: columnas StaffID_asignado y
   StaffID_cierre_cancelacion ampliadas de NVARCHAR(50) a
   NVARCHAR(200) para poder guardar el nombre de la farmacia
   (hasta 46 caracteres hoy, se deja margen) en vez del codigo
   de StaffID cuando el pedido es pickup.
   ============================================================ */

ALTER TABLE dbo.NOTIFICACION_MEDICATEL_PEDIDO
    ALTER COLUMN StaffID_asignado NVARCHAR(200) NULL;

ALTER TABLE dbo.NOTIFICACION_MEDICATEL_PEDIDO
    ALTER COLUMN StaffID_cierre_cancelacion NVARCHAR(200) NULL;
GO

/* ============================================================
   TRIGGER: TR_PEDIDO_CONTROL_NOTIFICAR_MEDICATEL (actualizado)

   Cambio: cuando el pedido es pickup (recoger en farmacia),
   StaffID_asignado y StaffID_cierre_cancelacion ya NO guardan el
   codigo de StaffID (ej. 'S0061'), sino el NOMBRE de la farmacia
   (ej. 'FarmaFacil #38 - Hospital del Sur Choluteca #2'), tomado
   de VW_FARMACIAS_SUPERVISOR.NAME por STOREID = StaffID.

   Para delivery/otros no cambia nada: se sigue guardando el
   StaffID del agente tal cual.

   Si por alguna razon no se encuentra la farmacia en el catalogo
   (STOREID sin match), se deja el StaffID crudo como respaldo
   (ISNULL) para no perder el dato.
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
                WHEN 1 THEN N'Cerrado'
                WHEN 2 THEN N'Cancelado'
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
            COALESCE(I.fecha_cierre, I.fecha_cancelacion) AS fecha_cierre_cancelacion,

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
        WHERE I.estado IN (1, 2)
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
