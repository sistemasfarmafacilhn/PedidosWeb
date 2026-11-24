/* ============================================================
   Ejecutar en el servidor/base de MEDICATEL
   (donde vive hoy dbo.PedidosWeb, la que nos importa los pedidos).

   Ajusta el "USE" al nombre real de esa base si es distinto.
   ============================================================ */

-- USE [DB_COSAVAL_MEDICATEL]
-- GO

CREATE TABLE dbo.PedidosWebEstado
(
    IdEstadoPedido              BIGINT IDENTITY(1,1) PRIMARY KEY,

    -- Identificadores del pedido (los mismos que ustedes nos enviaron)
    IdPedidoWeb                 BIGINT NOT NULL,
    OrderCode                   NVARCHAR(50) NULL,

    -- Estado reportado
    EstadoPedido                NVARCHAR(20) NOT NULL,          -- 'Cerrado' o 'Cancelado'

    -- Agente asignado al pedido
    StaffIDAsignado              NVARCHAR(50) NULL,
    FechaAsignacion              DATETIME2(7) NULL,

    -- Quien y cuando cerro/cancelo el pedido
    StaffIDCierreCancelacion     NVARCHAR(50) NULL,
    FechaCierreCancelacion       DATETIME2(7) NOT NULL,

    -- Solo tiene valor cuando EstadoPedido = 'Cancelado'
    MotivoCancelacion            NVARCHAR(300) NULL,

    -- Numero de version del envio: sube cada vez que el dato
    -- cambio de nuestro lado y se volvio a mandar (reenvio).
    -- VersionEnvio = 1 es el primer envio para ese pedido.
    VersionEnvio                 INT NOT NULL,

    -- Cuando llego este registro a esta tabla (de su lado)
    FechaRegistro                DATETIME2(7) NOT NULL DEFAULT (SYSDATETIME()),

    CONSTRAINT CK_PedidosWebEstado_Estado
        CHECK (EstadoPedido IN (N'Cerrado', N'Cancelado'))
);
GO

CREATE INDEX IX_PedidosWebEstado_IdPedidoWeb
    ON dbo.PedidosWebEstado (IdPedidoWeb);
GO

/* ============================================================
   Nota de diseno:

   Esta tabla es un LOG de eventos, no se actualiza desde nuestro
   lado: cada vez que un pedido se cierra/cancela, o cambia algo
   relevante despues (agente, fechas, motivo), insertamos una fila
   NUEVA con VersionEnvio mas alto para ese mismo IdPedidoWeb.

   Para saber el estado "actual" de un pedido desde el lado de
   Medicatel, se recomienda tomar la fila con mayor VersionEnvio
   (o mayor FechaRegistro) por IdPedidoWeb, por ejemplo:

       SELECT TOP 1 *
       FROM dbo.PedidosWebEstado
       WHERE IdPedidoWeb = @IdPedidoWeb
       ORDER BY VersionEnvio DESC;

   Falta que el usuario de conexion que usamos desde PedidosWeb
   (el que corre vía el linked server [145.223.79.81,1433\API_MEDICATEL])
   tenga permiso INSERT sobre esta tabla.
   ============================================================ */
