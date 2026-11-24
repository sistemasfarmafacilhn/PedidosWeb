USE [PedidosWeb]
GO

/* ============================================================
   TABLA: PEDIDO_PICKUP_ALERTA_CORREO

   Cola de alertas por correo al supervisor cuando se asigna un
   pedido PICKUP a su farmacia. SP_ENVIAR_ALERTAS_PICKUP_SUPERVISOR
   ya existia y la referenciaba, pero la tabla nunca se habia
   creado en ningun ambiente.

   estado: 0 = pendiente, 1 = enviado (confirmado), 2 = fallido
   definitivo (agoto 5 intentos).

   mailitem_id: se incluye desde el inicio (igual que ya se hizo
   en NOTIFICACION_SUPERVISOR_PEDIDO) para poder confirmar el
   envio real contra msdb.dbo.sysmail_allitems, no solo que se
   encolo.
   ============================================================ */

IF OBJECT_ID('dbo.PEDIDO_PICKUP_ALERTA_CORREO', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.PEDIDO_PICKUP_ALERTA_CORREO
    (
        id_alerta         BIGINT IDENTITY(1,1) PRIMARY KEY,

        id_pedido_gestion BIGINT NOT NULL,
        OrderCode         NVARCHAR(50) NULL,
        OrderIdWeb        NVARCHAR(80) NULL,
        BranchId          NVARCHAR(80) NULL,
        BranchName        NVARCHAR(200) NULL,

        SupervisorNombre  NVARCHAR(300) NULL,
        SupervisorCorreo  NVARCHAR(300) NULL,

        estado            INT NOT NULL DEFAULT (0),
        intentos          INT NOT NULL DEFAULT (0),
        ultimo_error      NVARCHAR(1000) NULL,
        mailitem_id       INT NULL,

        fecha_creacion    DATETIME2(7) NOT NULL DEFAULT (SYSDATETIME()),
        fecha_envio       DATETIME2(7) NULL,

        CONSTRAINT CK_PEDIDO_PICKUP_ALERTA_CORREO_ESTADO
            CHECK (estado IN (0, 1, 2))
    );

    CREATE INDEX IX_PEDIDO_PICKUP_ALERTA_CORREO_PENDIENTES
        ON dbo.PEDIDO_PICKUP_ALERTA_CORREO (estado)
        WHERE estado = 0;
END;
GO
