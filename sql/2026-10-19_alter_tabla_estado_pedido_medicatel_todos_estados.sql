/* ============================================================
   Ejecutar en el servidor/base de MEDICATEL (dbo.PedidosWebEstado).

   Ahora se va a reportar el ciclo completo del pedido (Abierto,
   En Preparacion, Listo para Despacho, En Ruta, Cerrado,
   Cancelado), no solo el estado final. Esto requiere:

   1. Permitir NULL en FechaCierreCancelacion (los estados
      intermedios no tienen fecha de cierre/cancelacion todavia).
   2. Ampliar el CHECK de EstadoPedido para aceptar los 6 estados.
   ============================================================ */

ALTER TABLE dbo.PedidosWebEstado
    ALTER COLUMN FechaCierreCancelacion DATETIME2(7) NULL;
GO

DECLARE @chkName SYSNAME;

SELECT @chkName = cc.name
FROM sys.check_constraints cc
WHERE cc.parent_object_id = OBJECT_ID('dbo.PedidosWebEstado')
  AND cc.definition LIKE '%EstadoPedido%';

IF @chkName IS NOT NULL
BEGIN
    EXEC('ALTER TABLE dbo.PedidosWebEstado DROP CONSTRAINT [' + @chkName + ']');
END;
GO

ALTER TABLE dbo.PedidosWebEstado
    ADD CONSTRAINT CK_PedidosWebEstado_Estado
        CHECK (EstadoPedido IN (
            N'Abierto',
            N'Cerrado',
            N'Cancelado',
            N'En Preparación',
            N'Listo para Despacho',
            N'En Ruta'
        ));
GO
