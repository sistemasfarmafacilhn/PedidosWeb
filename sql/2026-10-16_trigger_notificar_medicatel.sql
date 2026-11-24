USE [PedidosWeb]
GO

/* ============================================================
   TRIGGER: TR_PEDIDO_CONTROL_NOTIFICAR_MEDICATEL
   ON: PEDIDO_CONTROL (AFTER INSERT, UPDATE)

   Mantiene NOTIFICACION_MEDICATEL_PEDIDO con una fila por pedido
   (id_control_pedido) cada vez que el pedido queda Cerrado (1) o
   Cancelado (2).

   - Si el pedido no existe aun en la tabla de notificacion, la crea
     con pendiente_envio = 1, version_envio = 1.

   - Si ya existe y algo relevante cambio (estado, agente asignado,
     fecha de asignacion, fecha de cierre/cancelacion o motivo de
     cancelacion), la ACTUALIZA, sube version_envio, vuelve a poner
     pendiente_envio = 1 y resetea enviado/intentos/error_envio para
     que el proceso de envio la vuelva a tomar.

   - Si no hay ningun cambio relevante, no toca la fila (no reenvia
     sin necesidad).

   PEDIDO_CONTROL solo tiene un StaffID (el agente asignado). No hay
   una columna separada para "quien cerro/cancelo", asi que se usa
   el mismo StaffID para StaffID_asignado y StaffID_cierre_cancelacion,
   ya que en el flujo actual es el propio agente asignado quien cierra
   o cancela su pedido.
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

            I.StaffID AS StaffID_asignado,
            I.fecha_asignacion,

            I.StaffID AS StaffID_cierre_cancelacion,
            COALESCE(I.fecha_cierre, I.fecha_cancelacion) AS fecha_cierre_cancelacion,

            CASE WHEN I.estado = 2 THEN I.observacion ELSE NULL END AS motivo_cancelacion

        FROM inserted I
        INNER JOIN dbo.PEDIDO_GESTION PG
            ON PG.id_pedido_gestion = I.id_pedido_gestion
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
