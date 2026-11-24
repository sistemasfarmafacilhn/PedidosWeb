USE [PedidosWeb]
GO

/* ============================================================
   SP: SP_REPORTE_PEDIDOS_DELIVERY_LISTAR

   Para el modulo de reporte/exportacion de pedidos delivery,
   visible solo para Administrador (rol=1) y Vista Total (rol=4).

   Solo trae pedidos con DeliveryType = 'delivery' (los que
   maneja el agente de call center, rol = 2). No incluye pickup
   ni otros tipos.

   Filtros:
     @FechaInicio / @FechaFin: rango de fecha de asignacion.
       Si ambos vienen NULL, se usa SOLO el dia de hoy.
       Si solo viene uno de los dos, se usa ese mismo dia como
       rango (un solo dia).
     @StaffIDAgente: opcional, filtra por un agente especifico.
   ============================================================ */

CREATE OR ALTER PROCEDURE [dbo].[SP_REPORTE_PEDIDOS_DELIVERY_LISTAR]
(
    @FechaInicio   DATE = NULL,
    @FechaFin      DATE = NULL,
    @StaffIDAgente NVARCHAR(50) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    SET @StaffIDAgente = NULLIF(LTRIM(RTRIM(@StaffIDAgente)), '');

    IF @FechaInicio IS NULL AND @FechaFin IS NULL
    BEGIN
        SET @FechaInicio = CAST(SYSDATETIME() AS DATE);
        SET @FechaFin    = CAST(SYSDATETIME() AS DATE);
    END
    ELSE IF @FechaInicio IS NULL
        SET @FechaInicio = @FechaFin;
    ELSE IF @FechaFin IS NULL
        SET @FechaFin = @FechaInicio;

    SELECT
        PC.fecha_asignacion,
        ISNULL(A.nombre, N'Sin asignar') AS NombreAgente,
        PC.StaffID,
        PG.CustomerName,
        PG.CustomerPhone,
        PG.OrderCode,
        PG.OrderIdWeb,
        PG.Total,
        PG.Currency,
        PC.estado AS estado_control,
        CASE PC.estado
            WHEN 0 THEN N'Abierto'
            WHEN 1 THEN N'Cerrado'
            WHEN 2 THEN N'Cancelado'
            WHEN 3 THEN N'En Preparación'
            WHEN 4 THEN N'Listo para Despacho'
            WHEN 5 THEN N'En Ruta'
            ELSE N'Desconocido'
        END AS estado_control_descripcion

    FROM dbo.PEDIDO_CONTROL PC
    INNER JOIN dbo.PEDIDO_GESTION PG
        ON PG.id_pedido_gestion = PC.id_pedido_gestion
    LEFT JOIN dbo.AGENTE A
        ON A.StaffID COLLATE DATABASE_DEFAULT = PC.StaffID COLLATE DATABASE_DEFAULT
       AND ISNULL(A.deleted, 0) = 0

    WHERE LOWER(LTRIM(RTRIM(ISNULL(PG.DeliveryType, '')))) = 'delivery'
      AND CAST(PC.fecha_asignacion AS DATE) >= @FechaInicio
      AND CAST(PC.fecha_asignacion AS DATE) <= @FechaFin
      AND (
            @StaffIDAgente IS NULL
            OR PC.StaffID COLLATE DATABASE_DEFAULT = @StaffIDAgente COLLATE DATABASE_DEFAULT
          )

    ORDER BY PC.fecha_asignacion ASC;
END;
GO
