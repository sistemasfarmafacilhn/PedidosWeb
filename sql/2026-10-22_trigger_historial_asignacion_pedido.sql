USE [PedidosWeb]
GO

/* ============================================================
   TRIGGER: TR_PEDIDO_CONTROL_HISTORIAL_ASIGNACION
   ON: PEDIDO_CONTROL (AFTER INSERT, UPDATE)

   Alimenta HISTORICO_ASIGNACION_PEDIDO cada vez que un pedido
   queda con un StaffID distinto al que tenia antes:

     - Fila nueva en PEDIDO_CONTROL con StaffID ya asignado
       (primera asignacion, viene del trigger de asignacion
       automatica al crear el pedido).
     - Fila existente cuyo StaffID cambio respecto al valor
       anterior (reasignacion, manual o automatica).

   Si StaffID pasa a NULL (pedido que se queda sin asignar) NO
   se registra nada, porque no hay "a quien" asignarselo todavia.

   Resuelve un nombre legible en el momento de la asignacion:
     - pickup  -> nombre de la farmacia (VW_FARMACIAS_SUPERVISOR)
     - otros   -> nombre del agente (AGENTE.nombre por StaffID)

   numero_asignacion se calcula sumando las filas que ya existen
   para ese pedido en el historico + la posicion dentro del lote
   actual (por si varias filas del mismo pedido llegan en el
   mismo INSERT/UPDATE masivo).
   ============================================================ */

CREATE OR ALTER TRIGGER [dbo].[TR_PEDIDO_CONTROL_HISTORIAL_ASIGNACION]
ON [dbo].[PEDIDO_CONTROL]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH CAMBIOS AS
    (
        SELECT
            I.id_control_pedido,
            I.id_pedido_gestion,
            I.StaffID            AS StaffID_nuevo,
            D.StaffID             AS StaffID_anterior,
            I.fecha_asignacion,
            I.observacion,
            PG.OrderCode,
            PG.DeliveryType
        FROM inserted I
        LEFT JOIN deleted D
            ON D.id_control_pedido = I.id_control_pedido
        INNER JOIN dbo.PEDIDO_GESTION PG
            ON PG.id_pedido_gestion = I.id_pedido_gestion
        WHERE I.StaffID IS NOT NULL
          AND (
                D.id_control_pedido IS NULL
             OR ISNULL(D.StaffID COLLATE DATABASE_DEFAULT, N'') <>
                ISNULL(I.StaffID COLLATE DATABASE_DEFAULT, N'')
              )
    ),
    RESUELTO AS
    (
        SELECT
            C.*,
            CASE
                WHEN LOWER(LTRIM(RTRIM(ISNULL(C.DeliveryType, '')))) = 'pickup'
                    THEN ISNULL(FARM.NombreFarmacia, AG.nombre) COLLATE DATABASE_DEFAULT
                ELSE AG.nombre COLLATE DATABASE_DEFAULT
            END AS NombreAsignado
        FROM CAMBIOS C
        OUTER APPLY
        (
            SELECT TOP 1
                LTRIM(RTRIM(REPLACE(REPLACE(V.NAME, CHAR(13), ' '), CHAR(10), ' '))) AS NombreFarmacia
            FROM dbo.VW_FARMACIAS_SUPERVISOR V
            WHERE LTRIM(RTRIM(V.STOREID)) COLLATE DATABASE_DEFAULT =
                  LTRIM(RTRIM(C.StaffID_nuevo)) COLLATE DATABASE_DEFAULT
        ) FARM
        OUTER APPLY
        (
            SELECT TOP 1 A.nombre
            FROM dbo.AGENTE A
            WHERE A.StaffID COLLATE DATABASE_DEFAULT =
                  C.StaffID_nuevo COLLATE DATABASE_DEFAULT
              AND ISNULL(A.deleted, 0) = 0
            ORDER BY A.id_usuario ASC
        ) AG
    )

    INSERT INTO dbo.HISTORICO_ASIGNACION_PEDIDO
    (
        id_control_pedido, id_pedido_gestion, OrderCode,
        numero_asignacion,
        StaffID, NombreAsignado, DeliveryType,
        StaffID_anterior,
        fecha_asignacion, observacion,
        fecha_registro
    )
    SELECT
        R.id_control_pedido,
        R.id_pedido_gestion,
        R.OrderCode,
        ISNULL(
            (
                SELECT COUNT(*)
                FROM dbo.HISTORICO_ASIGNACION_PEDIDO H
                WHERE H.id_control_pedido = R.id_control_pedido
            ),
            0
        ) + ROW_NUMBER() OVER (PARTITION BY R.id_control_pedido ORDER BY (SELECT NULL)),
        R.StaffID_nuevo COLLATE DATABASE_DEFAULT,
        R.NombreAsignado,
        R.DeliveryType,
        R.StaffID_anterior COLLATE DATABASE_DEFAULT,
        R.fecha_asignacion,
        R.observacion,
        SYSDATETIME()
    FROM RESUELTO R;
END;
GO
