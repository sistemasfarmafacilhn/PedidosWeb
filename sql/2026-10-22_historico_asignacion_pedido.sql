USE [PedidosWeb]
GO

/* ============================================================
   TABLA: HISTORICO_ASIGNACION_PEDIDO

   Log de auditoria, solo se inserta (append-only), nunca se
   actualiza ni se borra. Cada vez que un pedido se asigna o
   reasigna a un StaffID distinto, queda una fila nueva aqui,
   para poder ver quien tuvo cada pedido a lo largo del tiempo.

   numero_asignacion: 1 = primera asignacion del pedido,
   2 = primera reasignacion, 3 = segunda reasignacion, etc.

   NombreAsignado: nombre legible al momento de la asignacion
   (nombre de la farmacia si es pickup, nombre del agente si es
   delivery/otros) - queda "congelado" en ese momento, no cambia
   si despues el agente cambia de nombre o de farmacia.

   StaffID_anterior: a quien tenia el pedido justo antes de esta
   asignacion. NULL si es la primera asignacion del pedido.
   ============================================================ */

IF OBJECT_ID('dbo.HISTORICO_ASIGNACION_PEDIDO', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.HISTORICO_ASIGNACION_PEDIDO
    (
        id_historico        BIGINT IDENTITY(1,1) PRIMARY KEY,

        id_control_pedido   BIGINT NOT NULL,
        id_pedido_gestion   BIGINT NOT NULL,
        OrderCode           NVARCHAR(50) NULL,

        numero_asignacion   INT NOT NULL,

        StaffID             NVARCHAR(50) NOT NULL,
        NombreAsignado      NVARCHAR(200) NULL,
        DeliveryType        NVARCHAR(30) NULL,

        StaffID_anterior    NVARCHAR(50) NULL,

        fecha_asignacion    DATETIME2(7) NOT NULL,
        observacion         NVARCHAR(500) NULL,

        fecha_registro      DATETIME2(7) NOT NULL DEFAULT (SYSDATETIME())
    );

    CREATE INDEX IX_HISTORICO_ASIGNACION_PEDIDO_CONTROL
        ON dbo.HISTORICO_ASIGNACION_PEDIDO (id_control_pedido, numero_asignacion);

    CREATE INDEX IX_HISTORICO_ASIGNACION_PEDIDO_STAFFID
        ON dbo.HISTORICO_ASIGNACION_PEDIDO (StaffID, fecha_asignacion);
END;
GO
