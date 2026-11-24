USE [PedidosWeb]
GO

/* ============================================================
   BACKFILL: puebla NOTIFICACION_MEDICATEL_PEDIDO con todos los
   PEDIDO_CONTROL que existian antes de que se creara el trigger
   (y por lo tanto nunca generaron una fila).

   Es seguro de volver a correr: el WHERE NOT EXISTS evita tocar
   pedidos que ya estan registrados, asi que no duplica ni
   sobreescribe nada si lo ejecutas mas de una vez.

   Usa EXACTAMENTE la misma logica de resolucion que el trigger
   TR_PEDIDO_CONTROL_NOTIFICAR_MEDICATEL (estado_control_descripcion,
   nombre de farmacia para pickup, fecha_cierre_cancelacion solo en
   estados finales, motivo_cancelacion solo si esta cancelado).

   Todo queda con pendiente_envio = 1, asi que el job de envio
   (SP_NOTIFICACIONES_MEDICATEL_ENVIAR) los va a ir mandando a
   Medicatel en lotes de 50 por corrida.
   ============================================================ */

INSERT INTO dbo.NOTIFICACION_MEDICATEL_PEDIDO
(
    id_pedido_gestion, id_control_pedido, IdPedidoWeb, OrderCode,
    estado_control, estado_control_descripcion,
    StaffID_asignado, fecha_asignacion,
    StaffID_cierre_cancelacion, fecha_cierre_cancelacion,
    motivo_cancelacion,
    version_envio, pendiente_envio, enviado, intentos, error_envio,
    fecha_creacion, fecha_actualizacion
)
SELECT
    O.id_pedido_gestion, O.id_control_pedido, O.IdPedidoWeb, O.OrderCode,
    O.estado_control, O.estado_control_descripcion,
    O.StaffID_asignado, O.fecha_asignacion,
    O.StaffID_cierre_cancelacion, O.fecha_cierre_cancelacion,
    O.motivo_cancelacion,
    1, 1, 0, 0, NULL,
    SYSDATETIME(), SYSDATETIME()
FROM
(
    SELECT
        PC.id_control_pedido,
        PC.id_pedido_gestion,
        PG.IdPedidoWeb,
        PG.OrderCode,

        PC.estado AS estado_control,
        CASE PC.estado
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
                THEN ISNULL(FARM.NombreFarmacia, PC.StaffID COLLATE DATABASE_DEFAULT)
            ELSE PC.StaffID COLLATE DATABASE_DEFAULT
        END COLLATE DATABASE_DEFAULT AS StaffID_asignado,
        PC.fecha_asignacion,

        CASE
            WHEN LOWER(LTRIM(RTRIM(ISNULL(PG.DeliveryType, '')))) = 'pickup'
                THEN ISNULL(FARM.NombreFarmacia, PC.StaffID COLLATE DATABASE_DEFAULT)
            ELSE PC.StaffID COLLATE DATABASE_DEFAULT
        END COLLATE DATABASE_DEFAULT AS StaffID_cierre_cancelacion,

        CASE
            WHEN PC.estado IN (1, 2)
                THEN COALESCE(PC.fecha_cierre, PC.fecha_cancelacion)
            ELSE NULL
        END AS fecha_cierre_cancelacion,

        CASE WHEN PC.estado = 2 THEN PC.observacion ELSE NULL END AS motivo_cancelacion

    FROM dbo.PEDIDO_CONTROL PC
    INNER JOIN dbo.PEDIDO_GESTION PG
        ON PG.id_pedido_gestion = PC.id_pedido_gestion
    OUTER APPLY
    (
        SELECT TOP 1
            LTRIM(RTRIM(REPLACE(REPLACE(V.NAME, CHAR(13), ' '), CHAR(10), ' '))) AS NombreFarmacia
        FROM dbo.VW_FARMACIAS_SUPERVISOR V
        WHERE LTRIM(RTRIM(V.STOREID)) COLLATE DATABASE_DEFAULT =
              LTRIM(RTRIM(PC.StaffID)) COLLATE DATABASE_DEFAULT
    ) FARM
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dbo.NOTIFICACION_MEDICATEL_PEDIDO N
        WHERE N.id_control_pedido = PC.id_control_pedido
    )
) O;
GO
