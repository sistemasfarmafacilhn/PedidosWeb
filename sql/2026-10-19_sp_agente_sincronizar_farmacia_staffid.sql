USE [PedidosWeb]
GO

/* ============================================================
   SP: SP_AGENTE_SINCRONIZAR_FARMACIA_STAFFID

   Complementa a SincronizarAgentesFarmaciaServlet (que solo
   INSERTA agentes de farmacia nuevos). Este SP corrige el
   StaffID de agentes que YA EXISTEN pero cuya farmacia cambio
   del lado de HQ (ej. un empleado que se traslado de sucursal).

   No crea agentes nuevos ni toca contraseñas: solo compara y
   actualiza la columna StaffID cuando difiere de lo que HQ
   tiene registrado hoy para ese mismo codigo de usuario.

   Pensado para correr una vez al dia via SQL Agent Job.
   ============================================================ */

CREATE OR ALTER PROCEDURE [dbo].[SP_AGENTE_SINCRONIZAR_FARMACIA_STAFFID]
(
    @mensaje      NVARCHAR(500) OUTPUT,
    @actualizados INT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    SET @actualizados = 0;
    SET @mensaje = N'';

    BEGIN TRY

        ;WITH ORIGEN AS
        (
            SELECT DISTINCT
                U.USUARIO AS codigo,
                R.STOREID AS StaffIDNuevo
            FROM [192.168.50.9,1433\HQ].[HQ_CosavalLS].[dbo].[TBL_AE_PharmacyUsuarios_Login] U
            INNER JOIN dbo.VW_FARMACIAS_SUPERVISOR R
                ON R.CENTRO COLLATE DATABASE_DEFAULT =
                   U.STOREID COLLATE DATABASE_DEFAULT
            WHERE U.ROLE = 'FF'
              AND U.USUARIO IS NOT NULL
              AND LTRIM(RTRIM(U.USUARIO)) <> ''
              AND R.STOREID IS NOT NULL
              AND LTRIM(RTRIM(R.STOREID)) <> ''
        )

        UPDATE A
            SET A.StaffID = O.StaffIDNuevo
        FROM dbo.AGENTE A
        INNER JOIN ORIGEN O
            ON A.codigo COLLATE DATABASE_DEFAULT =
               O.codigo COLLATE DATABASE_DEFAULT
        WHERE A.rol = 3
          AND ISNULL(A.deleted, 0) = 0
          AND (
                A.StaffID IS NULL
                OR A.StaffID COLLATE DATABASE_DEFAULT <>
                   O.StaffIDNuevo COLLATE DATABASE_DEFAULT
              );

        SET @actualizados = @@ROWCOUNT;

        SET @mensaje = CONCAT(
            N'Sincronizacion de StaffID completada. Agentes actualizados: ',
            @actualizados,
            N'.'
        );

    END TRY
    BEGIN CATCH

        SET @actualizados = -1;
        SET @mensaje = CONCAT(N'Error al sincronizar StaffID: ', ERROR_MESSAGE());

    END CATCH
END;
GO
