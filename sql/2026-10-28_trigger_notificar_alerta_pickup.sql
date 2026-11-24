USE [PedidosWeb]
GO

/* ============================================================
   TRIGGER: TR_PEDIDO_CONTROL_NOTIFICAR_ALERTA_PICKUP
   ON: PEDIDO_CONTROL (AFTER INSERT)

   Alimenta PEDIDO_PICKUP_ALERTA_CORREO. Mismo patron que
   TR_PEDIDO_CONTROL_NOTIFICAR_SUPERVISOR (misma cadena
   farmacia -> VW_FARMACIAS_SUPERVISOR -> supervisor), pero:

   - Solo para pedidos PICKUP (DeliveryType = 'pickup').
   - Solo AFTER INSERT (igual que el otro): si el pedido se crea
     ya asignado a su farmacia, se encola la alerta. Si el pedido
     pickup se crea sin farmacia disponible y se resuelve despues
     via UPDATE (reintento automatico), esta alerta puntual no se
     genera -- mismo comportamiento/limitacion que ya tiene
     TR_PEDIDO_CONTROL_NOTIFICAR_SUPERVISOR.

   Envuelto en TRY/CATCH para no interrumpir el INSERT real en
   PEDIDO_CONTROL si algo falla aqui.
   ============================================================ */

CREATE OR ALTER TRIGGER [dbo].[TR_PEDIDO_CONTROL_NOTIFICAR_ALERTA_PICKUP]
ON [dbo].[PEDIDO_CONTROL]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        INSERT INTO dbo.PEDIDO_PICKUP_ALERTA_CORREO
        (
            id_pedido_gestion,
            OrderCode,
            OrderIdWeb,
            BranchId,
            BranchName,
            SupervisorNombre,
            SupervisorCorreo
        )
        SELECT DISTINCT
            I.id_pedido_gestion,
            PG.OrderCode,
            PG.OrderIdWeb,
            I.StaffID,
            R.NAME,
            R.Supervisor,
            SUP.codigo

        FROM inserted I

        INNER JOIN dbo.PEDIDO_GESTION PG
            ON PG.id_pedido_gestion = I.id_pedido_gestion

        INNER JOIN dbo.AGENTE FARMACIA
            ON LTRIM(RTRIM(FARMACIA.StaffID)) COLLATE DATABASE_DEFAULT =
               LTRIM(RTRIM(I.StaffID)) COLLATE DATABASE_DEFAULT
           AND FARMACIA.rol = 3
           AND ISNULL(FARMACIA.deleted, 0) = 0

        INNER JOIN dbo.VW_FARMACIAS_SUPERVISOR R
            ON LTRIM(RTRIM(R.STOREID)) COLLATE DATABASE_DEFAULT =
               LTRIM(RTRIM(I.StaffID)) COLLATE DATABASE_DEFAULT

        INNER JOIN dbo.AGENTE SUP
            ON LTRIM(RTRIM(SUP.nombre)) COLLATE DATABASE_DEFAULT =
               LTRIM(RTRIM(R.Supervisor)) COLLATE DATABASE_DEFAULT
           AND SUP.rol = 5
           AND ISNULL(SUP.deleted, 0) = 0

        WHERE LOWER(LTRIM(RTRIM(ISNULL(PG.DeliveryType, '')))) = 'pickup'
          AND I.StaffID IS NOT NULL
          AND LTRIM(RTRIM(I.StaffID)) <> ''
          AND SUP.codigo IS NOT NULL
          AND LTRIM(RTRIM(SUP.codigo)) <> ''
          AND NOT EXISTS
          (
              SELECT 1
              FROM dbo.PEDIDO_PICKUP_ALERTA_CORREO A
              WHERE A.id_pedido_gestion = I.id_pedido_gestion
          );

    END TRY
    BEGIN CATCH
        -- No interrumpir el INSERT real en PEDIDO_CONTROL por un problema aqui.
    END CATCH;
END;
GO
