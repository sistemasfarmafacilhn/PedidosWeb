USE [PedidosWeb]
GO

/* ============================================================
   TABLA: MOTIVO_CANCELACION_PEDIDO

   Catálogo de motivos de cancelación, separados por tipo de
   entrega (pickup = recoger en sucursal, delivery = domicilio).
   Reemplaza la observación manual que se escribía al cancelar
   un pedido.
   ============================================================ */

IF OBJECT_ID('dbo.MOTIVO_CANCELACION_PEDIDO', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.MOTIVO_CANCELACION_PEDIDO
    (
        id_motivo     INT IDENTITY(1,1) PRIMARY KEY,
        descripcion   NVARCHAR(300) NOT NULL,
        tipo_entrega  VARCHAR(20)   NOT NULL,
        orden         INT           NOT NULL DEFAULT 0,
        activo        BIT           NOT NULL DEFAULT 1,

        CONSTRAINT CK_MOTIVO_CANCELACION_TIPO
            CHECK (tipo_entrega IN ('pickup', 'delivery'))
    );
END;
GO

/* Limpia el catálogo antes de volver a insertar, por si el script se re-ejecuta. */
DELETE FROM dbo.MOTIVO_CANCELACION_PEDIDO;
GO

/* ---------------------------------------------------------
   Opciones para pedido recoger en sucursal (pickup)
   --------------------------------------------------------- */
INSERT INTO dbo.MOTIVO_CANCELACION_PEDIDO (descripcion, tipo_entrega, orden) VALUES
(N'Cliente no respondió llamadas/mensajes.', 'pickup', 1),
(N'Rechazo del pedido por el cliente al momento de la entrega.', 'pickup', 2),
(N'Pedido duplicado.', 'pickup', 3),
(N'Producto Agotado/Descontinuado', 'pickup', 4),
(N'Cliente no retiro el pedido', 'pickup', 5),
(N'Producto equivocado/No es la presentación deseada', 'pickup', 6),
(N'Pedido con datos incompletos o erróneos', 'pickup', 7),
(N'Cliente solo quería cotización y por error genero el pedido', 'pickup', 8),
(N'Tarjeta de crédito/debito denegada', 'pickup', 9);

/* ---------------------------------------------------------
   Opciones para domicilio (delivery)
   --------------------------------------------------------- */
INSERT INTO dbo.MOTIVO_CANCELACION_PEDIDO (descripcion, tipo_entrega, orden) VALUES
(N'Dirección incompleta o incorrecta', 'delivery', 1),
(N'Cliente no se encontraba en el domicilio', 'delivery', 2),
(N'Cliente solicitó cancelar el pedido', 'delivery', 3),
(N'Pago no confirmado', 'delivery', 4),
(N'Producto requiere receta médica y no fue entregada', 'delivery', 5),
(N'Zona fuera de cobertura de entrega', 'delivery', 6),
(N'Horario de entrega no disponible', 'delivery', 7),
(N'Condiciones climáticas o de seguridad impidieron la entrega', 'delivery', 8),
(N'Error en inventario o preparación del pedido', 'delivery', 9),
(N'Cliente solicitó reprogramar la entrega', 'delivery', 10),
(N'Incidente con el Driver', 'delivery', 11);
GO

/* ============================================================
   SP: SP_MOTIVOS_CANCELACION_LISTAR

   Devuelve los motivos activos, ordenados por tipo de entrega
   y orden de despliegue.
   ============================================================ */
CREATE OR ALTER PROCEDURE [dbo].[SP_MOTIVOS_CANCELACION_LISTAR]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        M.id_motivo,
        M.descripcion,
        M.tipo_entrega,
        M.orden
    FROM dbo.MOTIVO_CANCELACION_PEDIDO M
    WHERE M.activo = 1
    ORDER BY M.tipo_entrega ASC, M.orden ASC;
END;
GO
