/* ============================================================
   Ejecutar en el servidor/base de MEDICATEL
   (donde ya vive dbo.PedidosWeb y dbo.PedidosWebEstado).
   ============================================================ */

CREATE TABLE dbo.PedidosWebHistorialAsignacion
(
    IdHistorialAsignacion    BIGINT IDENTITY(1,1) PRIMARY KEY,

    -- Identificadores del pedido (los mismos que ustedes nos enviaron)
    IdPedidoWeb              BIGINT NOT NULL,
    OrderCode                NVARCHAR(50) NULL,

    -- 1 = primera asignacion, 2 = primera reasignacion, etc.
    NumeroAsignacion         INT NOT NULL,

    -- A quien se asigno en este evento (codigo + nombre legible
    -- congelado en ese momento: nombre de farmacia si es pickup,
    -- nombre del agente si es delivery/otros)
    StaffID                  NVARCHAR(50) NOT NULL,
    NombreAsignado           NVARCHAR(200) NULL,
    DeliveryType              NVARCHAR(30) NULL,

    -- A quien tenia el pedido justo antes (NULL si es la primera asignacion)
    StaffIDAnterior           NVARCHAR(50) NULL,

    -- Cuando paso, y el motivo que registro el sistema de origen
    FechaAsignacion           DATETIME2(7) NOT NULL,
    Observacion               NVARCHAR(500) NULL,

    -- Cuando llego este registro a esta tabla (de su lado)
    FechaRegistro             DATETIME2(7) NOT NULL DEFAULT (SYSDATETIME())
);
GO

CREATE INDEX IX_PedidosWebHistorialAsignacion_IdPedidoWeb
    ON dbo.PedidosWebHistorialAsignacion (IdPedidoWeb);
GO

/* ============================================================
   Nota de diseno:

   Es un log de eventos igual que PedidosWebEstado: nosotros solo
   insertamos, nunca actualizamos. Cada reasignacion de un pedido
   llega como una fila nueva con NumeroAsignacion mas alto.

   Para ver quien tiene un pedido AHORA, tomar la fila con mayor
   NumeroAsignacion (o FechaRegistro) por IdPedidoWeb:

       SELECT TOP 1 *
       FROM dbo.PedidosWebHistorialAsignacion
       WHERE IdPedidoWeb = @IdPedidoWeb
       ORDER BY NumeroAsignacion DESC;

   Para ver el historial completo de un pedido, simplemente
   filtrar por IdPedidoWeb y ordenar por NumeroAsignacion.

   Igual que con PedidosWebEstado, falta que el usuario que usamos
   desde PedidosWeb (via el linked server
   [145.223.79.81,1433\API_MEDICATEL]) tenga permiso INSERT sobre
   esta tabla.
   ============================================================ */
