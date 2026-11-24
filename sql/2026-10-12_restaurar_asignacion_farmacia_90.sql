USE [PedidosWeb]
GO

/*
    Restaura la asignacion automatica de pedidos PICKUP a la farmacia
    (AGENTE rol = 3, StaffID = PEDIDO_GESTION.BranchId), revirtiendo el
    CAMBIO TEMPORAL que mandaba todo a agentes rol = 2.
    Version tomada de la base local (PedidosWeb) el 2026-10-12.
*/

-- ====================================================================
-- TR_PEDIDO_GESTION_ASIGNAR_CONTROL
-- ====================================================================
CREATE OR ALTER TRIGGER [dbo].[TR_PEDIDO_GESTION_ASIGNAR_CONTROL]
ON [dbo].[PEDIDO_GESTION]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @id_pedido_gestion BIGINT;
    DECLARE @DeliveryType NVARCHAR(30);
    DECLARE @BranchId NVARCHAR(80);

    DECLARE @StaffID NVARCHAR(50);
    DECLARE @LockResult INT;
    DECLARE @MaxPedidosPorAgente INT = 5;

    -- Bloqueo para evitar concurrencia
    EXEC @LockResult = sp_getapplock
        @Resource = 'PEDIDO_GESTION_ASIGNACION_AUTOMATICA',
        @LockMode = 'Exclusive',
        @LockOwner = 'Transaction',
        @LockTimeout = 10000;

    IF @LockResult < 0
    BEGIN
        THROW 51000, 'No se pudo obtener bloqueo para asignación automática de pedidos.', 1;
    END;

    /*
        LÓGICA ORIGINAL RESTAURADA

        - PICKUP:
          Se asigna directamente a farmacia rol = 3
          usando PEDIDO_GESTION.BranchId = AGENTE.StaffID.
          No valida estado, carga ni máximo.

        - DELIVERY / OTROS:
          Se asignan a agente rol = 2 disponible,
          respetando máximo 5 pedidos abiertos.
    */

    DECLARE cur_pedidos CURSOR LOCAL FAST_FORWARD FOR
        SELECT
            I.id_pedido_gestion,
            I.DeliveryType,
            I.BranchId
        FROM inserted I
        ORDER BY I.id_pedido_gestion ASC;

    OPEN cur_pedidos;

    FETCH NEXT FROM cur_pedidos
    INTO @id_pedido_gestion, @DeliveryType, @BranchId;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @StaffID = NULL;

        /* ============================================================
           CASO 1: PICKUP
           ============================================================ */
        IF LOWER(LTRIM(RTRIM(ISNULL(@DeliveryType, '')))) = 'pickup'
        BEGIN
            SELECT TOP 1
                @StaffID = A.StaffID
            FROM dbo.AGENTE A WITH (UPDLOCK, HOLDLOCK)
            WHERE ISNULL(A.deleted, 0) = 0
              AND A.rol = 3
              AND A.StaffID IS NOT NULL
              AND LTRIM(RTRIM(A.StaffID)) <> ''
              AND LTRIM(RTRIM(A.StaffID)) COLLATE DATABASE_DEFAULT =
                  LTRIM(RTRIM(ISNULL(@BranchId, ''))) COLLATE DATABASE_DEFAULT
            ORDER BY A.id_usuario ASC;

            IF @StaffID IS NOT NULL
            BEGIN
                INSERT INTO dbo.PEDIDO_CONTROL
                (
                    id_pedido_gestion,
                    StaffID,
                    estado,
                    fecha_asignacion,
                    observacion
                )
                VALUES
                (
                    @id_pedido_gestion,
                    @StaffID,
                    0,
                    SYSDATETIME(),
                    CONCAT(
                        N'Pedido pickup asignado automáticamente a farmacia por BranchId/StaffID: ',
                        @StaffID,
                        N'.'
                    )
                );

                FETCH NEXT FROM cur_pedidos
                INTO @id_pedido_gestion, @DeliveryType, @BranchId;

                CONTINUE;
            END;

            INSERT INTO dbo.PEDIDO_CONTROL
            (
                id_pedido_gestion,
                StaffID,
                estado,
                fecha_asignacion,
                observacion
            )
            VALUES
            (
                @id_pedido_gestion,
                NULL,
                0,
                SYSDATETIME(),
                CONCAT(
                    N'Pendiente de asignación. Pedido pickup sin farmacia configurada. BranchId: ',
                    ISNULL(@BranchId, N'SIN_BRANCHID'),
                    N'. Debe existir un AGENTE con rol = 3 y StaffID igual al BranchId.'
                )
            );

            FETCH NEXT FROM cur_pedidos
            INTO @id_pedido_gestion, @DeliveryType, @BranchId;

            CONTINUE;
        END;

        /* ============================================================
           CASO 2: DELIVERY / OTROS
           ============================================================ */

        SELECT TOP 1
            @StaffID = A.StaffID
        FROM dbo.AGENTE A WITH (UPDLOCK, HOLDLOCK)

        OUTER APPLY
        (
            SELECT COUNT(1) AS PedidosAbiertos
            FROM dbo.PEDIDO_CONTROL PC WITH (UPDLOCK, HOLDLOCK)
            WHERE PC.StaffID COLLATE DATABASE_DEFAULT =
                  A.StaffID COLLATE DATABASE_DEFAULT
              AND PC.estado = 0
        ) C

        OUTER APPLY
        (
            SELECT COUNT(1) AS PedidosAsignadosHoy
            FROM dbo.PEDIDO_CONTROL PC2 WITH (UPDLOCK, HOLDLOCK)
            WHERE PC2.StaffID COLLATE DATABASE_DEFAULT =
                  A.StaffID COLLATE DATABASE_DEFAULT
              AND PC2.fecha_asignacion >= CONVERT(DATE, GETDATE())
              AND PC2.fecha_asignacion < DATEADD(DAY, 1, CONVERT(DATE, GETDATE()))
        ) D

        WHERE A.estado = 1
          AND ISNULL(A.deleted, 0) = 0
          AND A.rol = 2
          AND A.StaffID IS NOT NULL
          AND LTRIM(RTRIM(A.StaffID)) <> ''
          AND C.PedidosAbiertos < @MaxPedidosPorAgente

        ORDER BY
            C.PedidosAbiertos ASC,
            D.PedidosAsignadosHoy ASC,
            NEWID();

        IF @StaffID IS NULL
        BEGIN
            INSERT INTO dbo.PEDIDO_CONTROL
            (
                id_pedido_gestion,
                StaffID,
                estado,
                fecha_asignacion,
                observacion
            )
            VALUES
            (
                @id_pedido_gestion,
                NULL,
                0,
                SYSDATETIME(),
                N'Pendiente de asignación. Todos los agentes disponibles alcanzaron el límite de pedidos abiertos.'
            );

            FETCH NEXT FROM cur_pedidos
            INTO @id_pedido_gestion, @DeliveryType, @BranchId;

            CONTINUE;
        END;

        INSERT INTO dbo.PEDIDO_CONTROL
        (
            id_pedido_gestion,
            StaffID,
            estado,
            fecha_asignacion,
            observacion
        )
        VALUES
        (
            @id_pedido_gestion,
            @StaffID,
            0,
            SYSDATETIME(),
            N'Asignado automáticamente al agente con menor carga abierta y menor cantidad asignada en el día.'
        );

        FETCH NEXT FROM cur_pedidos
        INTO @id_pedido_gestion, @DeliveryType, @BranchId;
    END;

    CLOSE cur_pedidos;
    DEALLOCATE cur_pedidos;
END;

GO

-- ====================================================================
-- TR_PEDIDOS_ASIGNACION_AUTOMATICA
-- ====================================================================
CREATE OR ALTER TRIGGER [dbo].[TR_PEDIDOS_ASIGNACION_AUTOMATICA]
ON [dbo].[PEDIDO_CONTROL]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @LockResult INT;
    DECLARE @id_control_pedido BIGINT;
    DECLARE @id_pedido_gestion BIGINT;
    DECLARE @DeliveryType NVARCHAR(30);
    DECLARE @BranchId NVARCHAR(80);
    DECLARE @StaffID NVARCHAR(50);

    EXEC @LockResult = sp_getapplock
        @Resource = 'PEDIDOS_ASIGNACION_AUTOMATICA',
        @LockMode = 'Exclusive',
        @LockOwner = 'Transaction',
        @LockTimeout = 10000;

    IF @LockResult < 0
    BEGIN
        THROW 51000, 'No se pudo obtener bloqueo para asignación automática de pedidos.', 1;
    END;

    /*
        LÓGICA ORIGINAL RESTAURADA:

        - PICKUP:
          Se asigna a farmacia rol = 3 usando BranchId = StaffID.
          No valida estado, carga ni máximo.

        - DELIVERY / OTROS:
          Se asignan a agente rol = 2 disponible.
          Respeta máximo 5 pedidos abiertos.
    */
    DECLARE cur_pendientes CURSOR LOCAL FAST_FORWARD FOR
        SELECT
            PC.id_control_pedido,
            PC.id_pedido_gestion,
            PG.DeliveryType,
            PG.BranchId
        FROM dbo.PEDIDO_CONTROL PC
        INNER JOIN dbo.PEDIDO_GESTION PG
            ON PG.id_pedido_gestion = PC.id_pedido_gestion
        WHERE PC.estado = 0
          AND PC.StaffID IS NULL
        ORDER BY
            PC.fecha_asignacion ASC,
            PC.id_control_pedido ASC;

    OPEN cur_pendientes;

    FETCH NEXT FROM cur_pendientes
    INTO @id_control_pedido, @id_pedido_gestion, @DeliveryType, @BranchId;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @StaffID = NULL;

        /* ============================================================
           CASO 1: PICKUP
           ============================================================ */
        IF LOWER(LTRIM(RTRIM(ISNULL(@DeliveryType, '')))) = 'pickup'
        BEGIN
            SELECT TOP 1
                @StaffID = A.StaffID
            FROM dbo.AGENTE A WITH (UPDLOCK, HOLDLOCK)
            WHERE ISNULL(A.deleted, 0) = 0
              AND A.rol = 3
              AND A.StaffID IS NOT NULL
              AND LTRIM(RTRIM(A.StaffID)) <> ''
              AND LTRIM(RTRIM(A.StaffID)) COLLATE DATABASE_DEFAULT =
                  LTRIM(RTRIM(ISNULL(@BranchId, ''))) COLLATE DATABASE_DEFAULT
            ORDER BY A.id_usuario ASC;

            IF @StaffID IS NOT NULL
            BEGIN
                UPDATE dbo.PEDIDO_CONTROL
                SET
                    StaffID = @StaffID,
                    fecha_asignacion = SYSDATETIME(),
                    observacion = CONCAT(
                        N'Pedido pickup asignado automáticamente a su farmacia específica. BranchId/StaffID: ',
                        @StaffID,
                        N'.'
                    )
                WHERE id_control_pedido = @id_control_pedido
                  AND estado = 0
                  AND StaffID IS NULL;
            END
            ELSE
            BEGIN
                UPDATE dbo.PEDIDO_CONTROL
                SET
                    observacion = CONCAT(
                        N'Pedido pickup sigue pendiente. No existe farmacia configurada con rol = 3 y StaffID igual al BranchId: ',
                        ISNULL(@BranchId, N'SIN_BRANCHID'),
                        N'.'
                    )
                WHERE id_control_pedido = @id_control_pedido
                  AND estado = 0
                  AND StaffID IS NULL;
            END;

            FETCH NEXT FROM cur_pendientes
            INTO @id_control_pedido, @id_pedido_gestion, @DeliveryType, @BranchId;

            CONTINUE;
        END;

        /* ============================================================
           CASO 2: DELIVERY / OTROS
           ============================================================ */
        SELECT TOP 1
            @StaffID = A.StaffID
        FROM dbo.AGENTE A WITH (UPDLOCK, HOLDLOCK)

        OUTER APPLY
        (
            SELECT COUNT(1) AS PedidosAbiertos
            FROM dbo.PEDIDO_CONTROL PC2 WITH (UPDLOCK, HOLDLOCK)
            WHERE PC2.StaffID COLLATE DATABASE_DEFAULT =
                  A.StaffID COLLATE DATABASE_DEFAULT
              AND PC2.estado = 0
        ) C

        OUTER APPLY
        (
            SELECT COUNT(1) AS PedidosAsignadosHoy
            FROM dbo.PEDIDO_CONTROL PC3 WITH (UPDLOCK, HOLDLOCK)
            WHERE PC3.StaffID COLLATE DATABASE_DEFAULT =
                  A.StaffID COLLATE DATABASE_DEFAULT
              AND PC3.fecha_asignacion >= CONVERT(DATE, GETDATE())
              AND PC3.fecha_asignacion < DATEADD(DAY, 1, CONVERT(DATE, GETDATE()))
        ) D

        WHERE A.estado = 1
          AND ISNULL(A.deleted, 0) = 0
          AND A.rol = 2
          AND A.StaffID IS NOT NULL
          AND LTRIM(RTRIM(A.StaffID)) <> ''
          AND C.PedidosAbiertos < 5

        ORDER BY
            C.PedidosAbiertos ASC,
            D.PedidosAsignadosHoy ASC,
            NEWID();

        IF @StaffID IS NOT NULL
        BEGIN
            UPDATE dbo.PEDIDO_CONTROL
            SET
                StaffID = @StaffID,
                fecha_asignacion = SYSDATETIME(),
                observacion = N'Asignado automáticamente al agente con menor carga abierta y menor cantidad asignada en el día.'
            WHERE id_control_pedido = @id_control_pedido
              AND estado = 0
              AND StaffID IS NULL;
        END
        ELSE
        BEGIN
            UPDATE dbo.PEDIDO_CONTROL
            SET
                observacion = N'Pedido sigue pendiente. No hay agentes disponibles para asignación automática.'
            WHERE id_control_pedido = @id_control_pedido
              AND estado = 0
              AND StaffID IS NULL;
        END;

        FETCH NEXT FROM cur_pendientes
        INTO @id_control_pedido, @id_pedido_gestion, @DeliveryType, @BranchId;
    END;

    CLOSE cur_pendientes;
    DEALLOCATE cur_pendientes;

    EXEC sp_releaseapplock
        @Resource = 'PEDIDOS_ASIGNACION_AUTOMATICA',
        @LockOwner = 'Transaction';
END;


GO

-- ====================================================================
-- SP_PEDIDO_CONTROL_ASIGNAR_PENDIENTES
-- ====================================================================
CREATE OR ALTER PROCEDURE [dbo].[SP_PEDIDO_CONTROL_ASIGNAR_PENDIENTES]
(
    @cantidad INT = NULL,
    @StaffIDDestino NVARCHAR(50) = NULL,
    @id_usuario_admin INT = NULL,
    @mensaje NVARCHAR(500) OUTPUT,
    @resultado INT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @LockResult INT;
    DECLARE @id_control_pedido BIGINT;
    DECLARE @id_pedido_gestion BIGINT;
    DECLARE @DeliveryType NVARCHAR(30);
    DECLARE @BranchId NVARCHAR(80);
    DECLARE @StaffID NVARCHAR(50);

    DECLARE @asignados INT = 0;
    DECLARE @pickupAsignados INT = 0;
    DECLARE @deliveryAsignados INT = 0;
    DECLARE @sinAsignar INT = 0;

    BEGIN TRY
        SET @mensaje = N'';
        SET @resultado = 0;

        IF @cantidad IS NOT NULL AND @cantidad <= 0
        BEGIN
            SET @resultado = -1;
            SET @mensaje = N'La cantidad debe ser mayor a cero.';
            RETURN;
        END;

        EXEC @LockResult = sp_getapplock
            @Resource = 'PEDIDO_CONTROL_ASIGNAR_PENDIENTES',
            @LockMode = 'Exclusive',
            @LockOwner = 'Session',
            @LockTimeout = 10000;

        IF @LockResult < 0
        BEGIN
            SET @resultado = -1;
            SET @mensaje = N'No se pudo obtener bloqueo para asignar pedidos pendientes.';
            RETURN;
        END;

        /* StaffIDDestino manual solo aplica para pedidos NO pickup.
           Debe ser agente rol = 2 y estar disponible. */
        IF @StaffIDDestino IS NOT NULL AND LTRIM(RTRIM(@StaffIDDestino)) <> ''
        BEGIN
            SET @StaffIDDestino = LTRIM(RTRIM(@StaffIDDestino));

            IF NOT EXISTS
            (
                SELECT 1
                FROM dbo.AGENTE
                WHERE StaffID COLLATE DATABASE_DEFAULT = @StaffIDDestino COLLATE DATABASE_DEFAULT
                  AND estado = 1
                  AND ISNULL(deleted, 0) = 0
                  AND rol = 2
            )
            BEGIN
                EXEC sp_releaseapplock
                    @Resource = 'PEDIDO_CONTROL_ASIGNAR_PENDIENTES',
                    @LockOwner = 'Session';

                SET @resultado = -2;
                SET @mensaje = N'El StaffID destino no es válido, no está disponible o no es un agente rol 2.';
                RETURN;
            END;
        END
        ELSE
        BEGIN
            SET @StaffIDDestino = NULL;
        END;

        /*
            REGLA ORIGINAL RESTAURADA:

            - pickup:
              Se asigna a farmacia rol = 3 donde
              AGENTE.StaffID = PEDIDO_GESTION.BranchId.
              No valida estado, carga ni máximo.

            - delivery / otros:
              Se asignan a agentes rol = 2.
              Si @StaffIDDestino viene informado, se asignan a ese agente.
              Si no, se asignan automáticamente por menor carga.
        */
        DECLARE cur_pendientes CURSOR LOCAL FAST_FORWARD FOR
            SELECT TOP (ISNULL(@cantidad, 1000000))
                PC.id_control_pedido,
                PC.id_pedido_gestion,
                PG.DeliveryType,
                PG.BranchId
            FROM dbo.PEDIDO_CONTROL PC
            INNER JOIN dbo.PEDIDO_GESTION PG
                ON PG.id_pedido_gestion = PC.id_pedido_gestion
            WHERE PC.estado = 0
              AND PC.StaffID IS NULL
            ORDER BY
                PC.fecha_asignacion ASC,
                PC.id_control_pedido ASC;

        OPEN cur_pendientes;

        FETCH NEXT FROM cur_pendientes
        INTO @id_control_pedido, @id_pedido_gestion, @DeliveryType, @BranchId;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @StaffID = NULL;

            /* ============================================================
               CASO 1: PICKUP
               Siempre va a su farmacia específica.
               BranchId = AGENTE.StaffID
               AGENTE.rol = 3
               Sin validar carga, estado ni máximo.
               ============================================================ */
            IF LOWER(LTRIM(RTRIM(ISNULL(@DeliveryType, '')))) = 'pickup'
            BEGIN
                SELECT TOP 1
                    @StaffID = A.StaffID
                FROM dbo.AGENTE A WITH (UPDLOCK, HOLDLOCK)
                WHERE ISNULL(A.deleted, 0) = 0
                  AND A.rol = 3
                  AND A.StaffID IS NOT NULL
                  AND LTRIM(RTRIM(A.StaffID)) <> ''
                  AND LTRIM(RTRIM(A.StaffID)) COLLATE DATABASE_DEFAULT =
                      LTRIM(RTRIM(ISNULL(@BranchId, ''))) COLLATE DATABASE_DEFAULT
                ORDER BY A.id_usuario ASC;

                IF @StaffID IS NULL
                BEGIN
                    UPDATE dbo.PEDIDO_CONTROL
                    SET observacion = CONCAT(
                        N'Pedido pickup sigue pendiente. No existe farmacia configurada con rol = 3 y StaffID igual al BranchId: ',
                        ISNULL(@BranchId, N'SIN_BRANCHID'),
                        N'.'
                    )
                    WHERE id_control_pedido = @id_control_pedido
                      AND estado = 0
                      AND StaffID IS NULL;

                    SET @sinAsignar = @sinAsignar + 1;

                    FETCH NEXT FROM cur_pendientes
                    INTO @id_control_pedido, @id_pedido_gestion, @DeliveryType, @BranchId;

                    CONTINUE;
                END;

                UPDATE dbo.PEDIDO_CONTROL
                SET StaffID = @StaffID,
                    fecha_asignacion = SYSDATETIME(),
                    observacion = CONCAT(
                        N'Pedido pickup asignado automáticamente a su farmacia específica. BranchId/StaffID: ',
                        @StaffID,
                        N'.'
                    )
                WHERE id_control_pedido = @id_control_pedido
                  AND estado = 0
                  AND StaffID IS NULL;

                IF @@ROWCOUNT > 0
                BEGIN
                    SET @asignados = @asignados + 1;
                    SET @pickupAsignados = @pickupAsignados + 1;
                END;

                FETCH NEXT FROM cur_pendientes
                INTO @id_control_pedido, @id_pedido_gestion, @DeliveryType, @BranchId;

                CONTINUE;
            END;

            /* ============================================================
               CASO 2: DELIVERY / OTROS
               Asignación manual o automática a agentes rol = 2.
               Respeta disponibilidad y máximo 5 pedidos abiertos.
               ============================================================ */

            IF @StaffIDDestino IS NOT NULL
            BEGIN
                SET @StaffID = @StaffIDDestino;
            END
            ELSE
            BEGIN
                SELECT TOP 1
                    @StaffID = A.StaffID
                FROM dbo.AGENTE A WITH (UPDLOCK, HOLDLOCK)

                OUTER APPLY
                (
                    SELECT COUNT(1) AS PedidosAbiertos
                    FROM dbo.PEDIDO_CONTROL PC WITH (UPDLOCK, HOLDLOCK)
                    WHERE PC.StaffID COLLATE DATABASE_DEFAULT =
                          A.StaffID COLLATE DATABASE_DEFAULT
                      AND PC.estado = 0
                ) C

                OUTER APPLY
                (
                    SELECT COUNT(1) AS PedidosAsignadosHoy
                    FROM dbo.PEDIDO_CONTROL PC WITH (UPDLOCK, HOLDLOCK)
                    WHERE PC.StaffID COLLATE DATABASE_DEFAULT =
                          A.StaffID COLLATE DATABASE_DEFAULT
                      AND PC.fecha_asignacion >= CONVERT(DATE, GETDATE())
                      AND PC.fecha_asignacion <
                          DATEADD(DAY, 1, CONVERT(DATE, GETDATE()))
                ) D

                WHERE A.estado = 1
                  AND ISNULL(A.deleted, 0) = 0
                  AND A.rol = 2
                  AND A.StaffID IS NOT NULL
                  AND LTRIM(RTRIM(A.StaffID)) <> ''
                  AND C.PedidosAbiertos < 5

                ORDER BY
                    C.PedidosAbiertos ASC,
                    D.PedidosAsignadosHoy ASC,
                    NEWID();
            END;

            IF @StaffID IS NULL
            BEGIN
                UPDATE dbo.PEDIDO_CONTROL
                SET observacion = N'Pedido sigue pendiente. No hay agentes disponibles para asignación.'
                WHERE id_control_pedido = @id_control_pedido
                  AND estado = 0
                  AND StaffID IS NULL;

                SET @sinAsignar = @sinAsignar + 1;

                FETCH NEXT FROM cur_pendientes
                INTO @id_control_pedido, @id_pedido_gestion, @DeliveryType, @BranchId;

                CONTINUE;
            END;

            UPDATE dbo.PEDIDO_CONTROL
            SET StaffID = @StaffID,
                fecha_asignacion = SYSDATETIME(),
                observacion =
                    CASE
                        WHEN @StaffIDDestino IS NOT NULL
                            THEN CONCAT(N'Asignado manualmente a agente ', @StaffID, N'.')
                        ELSE
                            N'Asignado automáticamente al agente con menor carga abierta y menor cantidad asignada en el día.'
                    END
            WHERE id_control_pedido = @id_control_pedido
              AND estado = 0
              AND StaffID IS NULL;

            IF @@ROWCOUNT > 0
            BEGIN
                SET @asignados = @asignados + 1;
                SET @deliveryAsignados = @deliveryAsignados + 1;
            END;

            FETCH NEXT FROM cur_pendientes
            INTO @id_control_pedido, @id_pedido_gestion, @DeliveryType, @BranchId;
        END;

        CLOSE cur_pendientes;
        DEALLOCATE cur_pendientes;

        EXEC sp_releaseapplock
            @Resource = 'PEDIDO_CONTROL_ASIGNAR_PENDIENTES',
            @LockOwner = 'Session';

        SET @resultado = @asignados;

        SET @mensaje = CONCAT(
            N'Pedidos asignados: ', @asignados,
            N'. Pickup a farmacia: ', @pickupAsignados,
            N'. Delivery/agentes: ', @deliveryAsignados,
            N'. Sin asignar: ', @sinAsignar,
            N'.'
        );

    END TRY
    BEGIN CATCH
        IF CURSOR_STATUS('local', 'cur_pendientes') >= -1
        BEGIN
            CLOSE cur_pendientes;
            DEALLOCATE cur_pendientes;
        END;

        EXEC sp_releaseapplock
            @Resource = 'PEDIDO_CONTROL_ASIGNAR_PENDIENTES',
            @LockOwner = 'Session';

        SET @resultado = -99;
        SET @mensaje = ERROR_MESSAGE();
    END CATCH
END;

GO

-- ====================================================================
-- SP_PEDIDO_CONTROL_REASIGNAR_ABIERTOS_AGENTE
-- ====================================================================
CREATE OR ALTER PROCEDURE [dbo].[SP_PEDIDO_CONTROL_REASIGNAR_ABIERTOS_AGENTE]
(
    @StaffIDOrigen NVARCHAR(50),
    @mensaje NVARCHAR(500) OUTPUT,
    @resultado INT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @LockResult INT;
    DECLARE @id_control_pedido BIGINT;
    DECLARE @id_pedido_gestion BIGINT;
    DECLARE @DeliveryType NVARCHAR(30);
    DECLARE @BranchId NVARCHAR(80);
    DECLARE @StaffIDDestino NVARCHAR(50);

    DECLARE @reasignados INT = 0;
    DECLARE @sinAsignar INT = 0;
    DECLARE @pickupFarmacia INT = 0;

    BEGIN TRY
        SET @mensaje = N'';
        SET @resultado = 0;

        IF @StaffIDOrigen IS NULL OR LTRIM(RTRIM(@StaffIDOrigen)) = ''
        BEGIN
            SET @resultado = -1;
            SET @mensaje = N'Debe enviar un StaffID origen válido.';
            RETURN;
        END;

        SET @StaffIDOrigen = LTRIM(RTRIM(@StaffIDOrigen));

        EXEC @LockResult = sp_getapplock
            @Resource = 'PEDIDO_CONTROL_REASIGNAR_ABIERTOS_AGENTE',
            @LockMode = 'Exclusive',
            @LockOwner = 'Session',
            @LockTimeout = 10000;

        IF @LockResult < 0
        BEGIN
            SET @resultado = -2;
            SET @mensaje = N'No se pudo obtener bloqueo para reasignar pedidos abiertos.';
            RETURN;
        END;

        /*
            LÓGICA ORIGINAL RESTAURADA:

            - PICKUP:
              Se reasigna a farmacia rol = 3 donde
              AGENTE.StaffID = PEDIDO_GESTION.BranchId.
              No valida estado, carga, máximo ni disponibilidad.

            - DELIVERY / OTROS:
              Se reasigna a otro agente rol = 2 disponible,
              respetando máximo 5 pedidos abiertos.
        */

        DECLARE cur_pedidos CURSOR LOCAL FAST_FORWARD FOR
            SELECT
                PC.id_control_pedido,
                PC.id_pedido_gestion,
                PG.DeliveryType,
                PG.BranchId
            FROM dbo.PEDIDO_CONTROL PC
            INNER JOIN dbo.PEDIDO_GESTION PG
                ON PG.id_pedido_gestion = PC.id_pedido_gestion
            WHERE PC.estado = 0
              AND PC.StaffID COLLATE DATABASE_DEFAULT =
                  @StaffIDOrigen COLLATE DATABASE_DEFAULT
            ORDER BY
                PC.fecha_asignacion ASC,
                PC.id_control_pedido ASC;

        OPEN cur_pedidos;

        FETCH NEXT FROM cur_pedidos
        INTO
            @id_control_pedido,
            @id_pedido_gestion,
            @DeliveryType,
            @BranchId;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @StaffIDDestino = NULL;

            /* ============================================================
               CASO 1: PICKUP

               Siempre debe ir a su farmacia específica.

               PEDIDO_GESTION.BranchId = AGENTE.StaffID
               AGENTE.rol = 3

               No valida:
               - estado
               - carga
               - máximo de pedidos
               - disponibilidad
               ============================================================ */
            IF LOWER(LTRIM(RTRIM(ISNULL(@DeliveryType, '')))) = 'pickup'
            BEGIN
                SELECT TOP 1
                    @StaffIDDestino = A.StaffID
                FROM dbo.AGENTE A WITH (UPDLOCK, HOLDLOCK)
                WHERE ISNULL(A.deleted, 0) = 0
                  AND A.rol = 3
                  AND A.StaffID IS NOT NULL
                  AND LTRIM(RTRIM(A.StaffID)) <> ''
                  AND LTRIM(RTRIM(A.StaffID)) COLLATE DATABASE_DEFAULT =
                      LTRIM(RTRIM(ISNULL(@BranchId, ''))) COLLATE DATABASE_DEFAULT
                ORDER BY
                    A.id_usuario ASC;

                IF @StaffIDDestino IS NULL
                BEGIN
                    UPDATE dbo.PEDIDO_CONTROL
                    SET
                        StaffID = NULL,
                        observacion = CONCAT(
                            N'Pedido pickup quedó sin asignar. No existe farmacia configurada con rol = 3 y StaffID igual al BranchId: ',
                            ISNULL(@BranchId, N'SIN_BRANCHID'),
                            N'.'
                        )
                    WHERE id_control_pedido = @id_control_pedido
                      AND estado = 0
                      AND StaffID COLLATE DATABASE_DEFAULT =
                          @StaffIDOrigen COLLATE DATABASE_DEFAULT;

                    IF @@ROWCOUNT > 0
                        SET @sinAsignar = @sinAsignar + 1;

                    FETCH NEXT FROM cur_pedidos
                    INTO
                        @id_control_pedido,
                        @id_pedido_gestion,
                        @DeliveryType,
                        @BranchId;

                    CONTINUE;
                END;

                UPDATE dbo.PEDIDO_CONTROL
                SET
                    StaffID = @StaffIDDestino,
                    fecha_asignacion = SYSDATETIME(),
                    observacion = CONCAT(
                        N'Pedido pickup reasignado automáticamente a su farmacia específica. BranchId/StaffID: ',
                        @StaffIDDestino,
                        N'.'
                    )
                WHERE id_control_pedido = @id_control_pedido
                  AND estado = 0
                  AND StaffID COLLATE DATABASE_DEFAULT =
                      @StaffIDOrigen COLLATE DATABASE_DEFAULT;

                IF @@ROWCOUNT > 0
                BEGIN
                    SET @reasignados = @reasignados + 1;
                    SET @pickupFarmacia = @pickupFarmacia + 1;
                END;

                FETCH NEXT FROM cur_pedidos
                INTO
                    @id_control_pedido,
                    @id_pedido_gestion,
                    @DeliveryType,
                    @BranchId;

                CONTINUE;
            END;

            /* ============================================================
               CASO 2: DELIVERY / OTROS

               Reasignación normal a agentes rol = 2.

               Requisitos:
               - estado = 1
               - deleted = 0
               - rol = 2
               - StaffID válido
               - diferente del agente origen
               - máximo 5 pedidos abiertos

               Prioridad:
               1. Menos pedidos abiertos.
               2. Menos pedidos asignados hoy.
               3. Desempate aleatorio.
               ============================================================ */

            SELECT TOP 1
                @StaffIDDestino = A.StaffID
            FROM dbo.AGENTE A WITH (UPDLOCK, HOLDLOCK)

            OUTER APPLY
            (
                SELECT COUNT(1) AS PedidosAbiertos
                FROM dbo.PEDIDO_CONTROL PC WITH (UPDLOCK, HOLDLOCK)
                WHERE PC.StaffID COLLATE DATABASE_DEFAULT =
                      A.StaffID COLLATE DATABASE_DEFAULT
                  AND PC.estado = 0
            ) C

            OUTER APPLY
            (
                SELECT COUNT(1) AS PedidosAsignadosHoy
                FROM dbo.PEDIDO_CONTROL PC WITH (UPDLOCK, HOLDLOCK)
                WHERE PC.StaffID COLLATE DATABASE_DEFAULT =
                      A.StaffID COLLATE DATABASE_DEFAULT
                  AND PC.fecha_asignacion >= CONVERT(DATE, GETDATE())
                  AND PC.fecha_asignacion <
                      DATEADD(DAY, 1, CONVERT(DATE, GETDATE()))
            ) D

            WHERE A.estado = 1
              AND ISNULL(A.deleted, 0) = 0
              AND A.rol = 2
              AND A.StaffID IS NOT NULL
              AND LTRIM(RTRIM(A.StaffID)) <> ''
              AND A.StaffID COLLATE DATABASE_DEFAULT <>
                  @StaffIDOrigen COLLATE DATABASE_DEFAULT
              AND C.PedidosAbiertos < 5

            ORDER BY
                C.PedidosAbiertos ASC,
                D.PedidosAsignadosHoy ASC,
                NEWID();

            IF @StaffIDDestino IS NULL
            BEGIN
                UPDATE dbo.PEDIDO_CONTROL
                SET
                    StaffID = NULL,
                    observacion = CONCAT(
                        N'Pedido quedó sin asignar porque el agente ',
                        @StaffIDOrigen,
                        N' se desconectó y no había otros agentes disponibles.'
                    )
                WHERE id_control_pedido = @id_control_pedido
                  AND estado = 0
                  AND StaffID COLLATE DATABASE_DEFAULT =
                      @StaffIDOrigen COLLATE DATABASE_DEFAULT;

                IF @@ROWCOUNT > 0
                    SET @sinAsignar = @sinAsignar + 1;

                FETCH NEXT FROM cur_pedidos
                INTO
                    @id_control_pedido,
                    @id_pedido_gestion,
                    @DeliveryType,
                    @BranchId;

                CONTINUE;
            END;

            UPDATE dbo.PEDIDO_CONTROL
            SET
                StaffID = @StaffIDDestino,
                fecha_asignacion = SYSDATETIME(),
                observacion = CONCAT(
                    N'Reasignado automáticamente porque el agente ',
                    @StaffIDOrigen,
                    N' se desconectó. Nuevo agente: ',
                    @StaffIDDestino,
                    N'.'
                )
            WHERE id_control_pedido = @id_control_pedido
              AND estado = 0
              AND StaffID COLLATE DATABASE_DEFAULT =
                  @StaffIDOrigen COLLATE DATABASE_DEFAULT;

            IF @@ROWCOUNT > 0
                SET @reasignados = @reasignados + 1;

            FETCH NEXT FROM cur_pedidos
            INTO
                @id_control_pedido,
                @id_pedido_gestion,
                @DeliveryType,
                @BranchId;
        END;

        CLOSE cur_pedidos;
        DEALLOCATE cur_pedidos;

        EXEC sp_releaseapplock
            @Resource = 'PEDIDO_CONTROL_REASIGNAR_ABIERTOS_AGENTE',
            @LockOwner = 'Session';

        SET @resultado = @reasignados;

        SET @mensaje = CONCAT(
            N'Pedidos abiertos reasignados: ',
            @reasignados,
            N'. Pickup enviados a farmacia: ',
            @pickupFarmacia,
            N'. Pedidos dejados sin asignar: ',
            @sinAsignar,
            N'.'
        );

    END TRY
    BEGIN CATCH
        IF CURSOR_STATUS('local', 'cur_pedidos') >= -1
        BEGIN
            CLOSE cur_pedidos;
            DEALLOCATE cur_pedidos;
        END;

        EXEC sp_releaseapplock
            @Resource = 'PEDIDO_CONTROL_REASIGNAR_ABIERTOS_AGENTE',
            @LockOwner = 'Session';

        SET @resultado = -99;
        SET @mensaje = ERROR_MESSAGE();
    END CATCH;
END;



GO

-- ====================================================================
-- SP_PEDIDOS_ABIERTOS_POR_AGENTE
-- ====================================================================
CREATE OR ALTER PROCEDURE [dbo].[SP_PEDIDOS_ABIERTOS_POR_AGENTE]
(
    @StaffID NVARCHAR(50) = NULL,
    @fecha DATE = NULL,
    @RolUsuario INT = NULL,
    @SupervisorNombre NVARCHAR(300) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    SET @StaffID = NULLIF(LTRIM(RTRIM(@StaffID)), '');
    SET @SupervisorNombre = NULLIF(LTRIM(RTRIM(@SupervisorNombre)), '');

    ;WITH AGENTE_UNICO AS
    (
        SELECT
            A.*,
            ROW_NUMBER() OVER
            (
                PARTITION BY LTRIM(RTRIM(A.StaffID))
                ORDER BY
                    CASE
                        WHEN A.rol = 3 THEN 0
                        WHEN A.rol = 5 THEN 1
                        WHEN A.rol = 2 THEN 2
                        WHEN A.rol = 1 THEN 3
                        WHEN A.rol = 4 THEN 4
                        ELSE 9
                    END,
                    A.id_usuario DESC
            ) AS rn
        FROM dbo.AGENTE A
        WHERE ISNULL(A.deleted, 0) = 0
          AND A.StaffID IS NOT NULL
          AND LTRIM(RTRIM(A.StaffID)) <> ''
    ),
    DETALLE_UNICO AS
    (
        SELECT
            X.id_pedido_gestion_detalle,
            X.id_pedido_gestion,
            X.IdDetalleWeb,
            X.Sku,
            X.Nombre,
            X.Quantity,
            X.UnitPrice,
            X.Subtotal,
            X.IsCanje,
            X.CanjePromocion,
            X.DescuentoTipo,
            X.fecha_registro
        FROM
        (
            SELECT
                D.id_pedido_gestion_detalle,
                D.id_pedido_gestion,
                D.IdDetalleWeb,
                D.Sku,
                D.Nombre,
                D.Quantity,
                D.UnitPrice,
                D.Subtotal,
                D.IsCanje,
                D.CanjePromocion,
                D.DescuentoTipo,
                D.fecha_registro,
                ROW_NUMBER() OVER
                (
                    PARTITION BY
                        D.id_pedido_gestion,
                        ISNULL(D.IdDetalleWeb, 0),
                        ISNULL(D.Sku, ''),
                        ISNULL(D.Nombre, ''),
                        ISNULL(CONVERT(NVARCHAR(50), D.Quantity), ''),
                        ISNULL(CONVERT(NVARCHAR(50), D.UnitPrice), ''),
                        ISNULL(CONVERT(NVARCHAR(50), D.Subtotal), '')
                    ORDER BY D.id_pedido_gestion_detalle ASC
                ) AS rn
            FROM dbo.PEDIDO_GESTION_DETALLE D
        ) X
        WHERE X.rn = 1
    ),
    SOLICITUD_UNICA AS
    (
        SELECT
            X.IdSolicitudTarjeta,
            X.OrderCode,
            X.CardSku,
            X.FullName,
            X.IdentityDocument,
            X.Email,
            X.Phone,
            X.Birthdate,
            X.LocationDepartment,
            X.LocationCity,
            X.LocationAddress
        FROM
        (
            SELECT
                S.IdSolicitudTarjeta,
                S.OrderCode,
                S.CardSku,
                S.FullName,
                S.IdentityDocument,
                S.Email,
                S.Phone,
                S.Birthdate,
                S.LocationDepartment,
                S.LocationCity,
                S.LocationAddress,
                ROW_NUMBER() OVER
                (
                    PARTITION BY LTRIM(RTRIM(S.OrderCode))
                    ORDER BY S.IdSolicitudTarjeta DESC
                ) AS rn
            FROM dbo.SOLICITUDES_TARJETA_PLUS S
            WHERE S.OrderCode IS NOT NULL
              AND LTRIM(RTRIM(S.OrderCode)) <> ''
        ) X
        WHERE X.rn = 1
    )

    SELECT
        -- Control
        PC.id_control_pedido,
        PC.StaffID,

        CASE
            WHEN PC.StaffID IS NULL OR LTRIM(RTRIM(PC.StaffID)) = '' THEN 'Sin asignar'
            ELSE ISNULL(A.nombre, 'Agente no encontrado')
        END AS NombreAgente,

        A.rol AS RolAsignado,

        CASE
            WHEN A.rol = 1 THEN 'Administrador'
            WHEN A.rol = 2 THEN 'Agente'
            WHEN A.rol = 3 THEN 'Agente de farmacia'
            WHEN A.rol = 4 THEN 'Vista total'
            WHEN A.rol = 5 THEN 'Supervisor'
            ELSE 'Sin asignar'
        END AS RolAsignadoDescripcion,

        PC.estado AS estado_control,

        CASE
            WHEN PC.estado = 0 THEN 'Abierto'
            WHEN PC.estado = 1 THEN 'Cerrado'
            WHEN PC.estado = 2 THEN 'Cancelado'
            WHEN PC.estado = 3 THEN 'En Preparación'
            WHEN PC.estado = 4 THEN 'Listo para Despacho'
            WHEN PC.estado = 5 THEN 'En Ruta'
            ELSE 'Desconocido'
        END AS estado_control_descripcion,

        PC.fecha_asignacion,
        PC.fecha_cierre,
        PC.fecha_cancelacion,
        PC.observacion,

        -- Encabezado
        PG.id_pedido_gestion,
        PG.IdPedidoWeb,
        PG.OrderIdWeb,
        PG.OrderCode,
        PG.OrderNumber,
        PG.CustomerName,
        PG.CustomerPhone,
        PG.CustomerEmail,
        PG.CustomerIdentityDocument,
        PG.DeliveryType,
        PG.RecipientName,
        PG.DeliveryAddress,
        PG.DeliveryCity,
        PG.DeliveryDepartment,
        PG.DeliveryPhone,
        PG.BranchId,
        ZON.NAME AS BranchName,
        PG.ContactName,
        PG.ContactPhone,
        FORMAT(PG.Subtotal, '0.##') AS PedidoSubtotal,
        FORMAT(PG.Shipping, '0.##') AS Shipping,
        FORMAT(PG.Discount, '0.##') AS Discount,
        FORMAT(PG.Total, '0.##') AS Total,
        PG.Currency,

        CASE LTRIM(RTRIM(ISNULL(PG.PaymentMethod, '')))
            WHEN 'online_visa' THEN 'Pago en línea con Visa (Place to pay)'
            WHEN 'at_branch' THEN 'Pago en sucursal'
            WHEN 'at_branch_cash' THEN 'Pago en sucursal - Efectivo'
            WHEN 'at_branch_card' THEN 'Pago en sucursal - Tarjeta'
            WHEN 'amex_link' THEN 'AMEX/Mastercard - Link de pago'
            WHEN 'amex_pos' THEN 'AMEX/Mastercard - Terminal POS'
            WHEN 'cash_transfer' THEN 'Efectivo o transferencia'
            ELSE ISNULL(PG.PaymentMethod, '')
        END AS PaymentMethod,

        PG.PaymentStatus,
        PG.HasTransfer,
        PG.CallcenterRequired,
        PG.CustomerNotes,
        PG.CreatedAtWeb,
        PG.fecha_recepcion_local,
        PG.fecha_finalizacion,

        -- Detalle
        D.id_pedido_gestion_detalle,
        D.IdDetalleWeb,
        D.Sku,
        D.Nombre AS ProductoNombre,
        FORMAT(D.Quantity, '0.##') AS Quantity,
        FORMAT(D.UnitPrice, '0.##') AS UnitPrice,
        FORMAT(D.Subtotal, '0.##') AS ProductoSubtotal,
        D.IsCanje,
        D.CanjePromocion,
        D.DescuentoTipo,
        D.fecha_registro AS FechaRegistroDetalle,

        /* ============================================================
           DATOS TARJETA PLUS
           ============================================================ */

        STP.OrderCode AS SolicitudOrderCode,
        STP.CardSku,

        CASE LTRIM(RTRIM(ISNULL(STP.CardSku, '')))
            WHEN 'FF1005363' THEN 'Afiliacion'
            WHEN 'FF1005364' THEN 'Reposicion'
            ELSE NULL
        END AS TipoTarjeta,

        STP.FullName,
        STP.IdentityDocument,
        STP.Email,
        STP.Phone,
        STP.Birthdate,
        STP.LocationDepartment,
        STP.LocationCity,
        STP.LocationAddress

    FROM dbo.PEDIDO_CONTROL PC

    INNER JOIN dbo.PEDIDO_GESTION PG
        ON PC.id_pedido_gestion = PG.id_pedido_gestion

    LEFT JOIN dbo.VW_FARMACIAS_SUPERVISOR ZON
        ON LTRIM(RTRIM(ZON.STOREID)) COLLATE DATABASE_DEFAULT =
           LTRIM(RTRIM(PG.BranchId)) COLLATE DATABASE_DEFAULT

    LEFT JOIN AGENTE_UNICO A
        ON A.StaffID COLLATE DATABASE_DEFAULT =
           PC.StaffID COLLATE DATABASE_DEFAULT
       AND A.rn = 1

    LEFT JOIN DETALLE_UNICO D
        ON PG.id_pedido_gestion = D.id_pedido_gestion

    LEFT JOIN SOLICITUD_UNICA STP
        ON LTRIM(RTRIM(STP.OrderCode)) COLLATE DATABASE_DEFAULT =
           LTRIM(RTRIM(PG.OrderCode)) COLLATE DATABASE_DEFAULT
       AND EXISTS
       (
           SELECT 1
           FROM dbo.PEDIDO_GESTION_DETALLE DT
           WHERE DT.id_pedido_gestion = PG.id_pedido_gestion
             AND LTRIM(RTRIM(DT.Sku)) IN ('FF1005363', 'FF1005364')
       )

    WHERE
        PC.estado IN (0, 1, 2, 3, 4, 5)

        AND
        (
            (
                @fecha IS NULL
                AND PC.fecha_asignacion >= DATEADD(DAY, -1, CAST(GETDATE() AS DATE))
                AND PC.fecha_asignacion < DATEADD(DAY, 1, CAST(GETDATE() AS DATE))
            )
            OR
            (
                @fecha IS NOT NULL
                AND PC.fecha_asignacion >= @fecha
                AND PC.fecha_asignacion < DATEADD(DAY, 1, @fecha)
            )
        )

        AND
        (
            -- ROL 4 = VISTA TOTAL
            (
                @RolUsuario = 4
                AND
                (
                    @StaffID IS NULL
                    OR PC.StaffID COLLATE DATABASE_DEFAULT =
                       @StaffID COLLATE DATABASE_DEFAULT
                )
            )

            OR

            -- ROL 1 = ADMINISTRADOR
            (
                @RolUsuario = 1
                AND LOWER(LTRIM(RTRIM(ISNULL(PG.DeliveryType, '')))) <> 'pickup'
                AND
                (
                    PC.StaffID IS NULL
                    OR A.rol IS NULL
                    OR A.rol <> 3
                )
                AND
                (
                    @StaffID IS NULL
                    OR PC.StaffID COLLATE DATABASE_DEFAULT =
                       @StaffID COLLATE DATABASE_DEFAULT
                )
            )

            OR

            -- ROL 5 = SUPERVISOR
            (
                @RolUsuario = 5
                AND @SupervisorNombre IS NOT NULL
                AND EXISTS
                (
                    SELECT 1
                    FROM dbo.VW_FARMACIAS_SUPERVISOR FS
                    WHERE FS.STOREID COLLATE DATABASE_DEFAULT =
                          PC.StaffID COLLATE DATABASE_DEFAULT
                      AND LTRIM(RTRIM(FS.Supervisor)) COLLATE DATABASE_DEFAULT =
                          LTRIM(RTRIM(@SupervisorNombre)) COLLATE DATABASE_DEFAULT
                      AND
                      (
                          @StaffID IS NULL
                          OR FS.STOREID COLLATE DATABASE_DEFAULT =
                             @StaffID COLLATE DATABASE_DEFAULT
                      )
                )
            )

            OR

            -- ROL 2 Y ROL 3
            (
                ISNULL(@RolUsuario, 0) NOT IN (1, 4, 5)
                AND @StaffID IS NOT NULL
                AND PC.StaffID COLLATE DATABASE_DEFAULT =
                    @StaffID COLLATE DATABASE_DEFAULT
            )
        )

    ORDER BY
        CASE
            WHEN PC.StaffID IS NULL OR LTRIM(RTRIM(PC.StaffID)) = '' THEN 0
            ELSE 1
        END ASC,
        PC.estado ASC,
        PC.fecha_asignacion ASC,
        PG.id_pedido_gestion ASC,
        D.id_pedido_gestion_detalle ASC;
END;





GO

