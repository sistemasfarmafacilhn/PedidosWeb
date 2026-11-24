USE [PedidosWeb]
GO

/* ============================================================
   TABLA: NOTIFICACION_MEDICATEL_PEDIDO

   Cola de envio a la API de Medicatel para avisar que un pedido
   se cerro o se cancelo (mismo patron que NOTIFICACION_SUPERVISOR_PEDIDO).

   Guarda UNA fila por pedido (id_control_pedido es UNIQUE). El envio
   es asincrono y el estado/agente asignado puede volver a cambiar
   despues de ya haberse enviado, asi que esta fila se ACTUALIZA
   (no se duplica) cada vez que algo relevante cambia:

     - estado_control (cerrado <-> cancelado)
     - StaffID_asignado / fecha_asignacion
     - StaffID_cierre_cancelacion / fecha_cierre_cancelacion
     - motivo_cancelacion

   Los campos que permiten "parametrizar" el reenvio son:

     - pendiente_envio: 1 = hay que enviarla (o reenviarla) a Medicatel.
       Cuando ya se envio queda en 0. Si luego algo relevante cambia,
       se vuelve a poner en 1 para que el proceso de envio la recoja
       de nuevo.

     - version_envio: se incrementa cada vez que pendiente_envio pasa
       de 0 a 1 por un cambio real. Sirve para que el payload que se
       manda a Medicatel indique si es el primer envio o una
       actualizacion (version_envio = 2, 3, ...), y para auditoria.

     - intentos / error_envio: igual que en NOTIFICACION_SUPERVISOR_PEDIDO,
       se resetean a 0 / NULL cada vez que pendiente_envio vuelve a 1,
       para no heredar el conteo de fallos de un envio anterior ya
       superado.

   (La logica que llena/actualiza esta tabla -trigger o SP- se arma
   en un paso aparte; esto es solo la tabla.)
   ============================================================ */

IF OBJECT_ID('dbo.NOTIFICACION_MEDICATEL_PEDIDO', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.NOTIFICACION_MEDICATEL_PEDIDO
    (
        id_notificacion_medicatel   BIGINT IDENTITY(1,1) PRIMARY KEY,

        -- Identificadores del pedido (los mismos que Medicatel nos envio)
        id_pedido_gestion           BIGINT NOT NULL,
        id_control_pedido           BIGINT NOT NULL,
        IdPedidoWeb                 BIGINT NOT NULL,
        OrderCode                   NVARCHAR(50) NULL,

        -- Estado final que se reporta (1 = Cerrado, 2 = Cancelado)
        estado_control              INT NOT NULL,
        estado_control_descripcion  NVARCHAR(50) NOT NULL,

        -- Agente asignado al pedido
        StaffID_asignado            NVARCHAR(50) NULL,
        fecha_asignacion            DATETIME2(7) NULL,

        -- Quien y cuando cerro/cancelo
        StaffID_cierre_cancelacion  NVARCHAR(50) NULL,
        fecha_cierre_cancelacion    DATETIME2(7) NOT NULL,

        -- Solo aplica si estado_control = Cancelado
        motivo_cancelacion          NVARCHAR(300) NULL,

        -- Control de envio / reenvio hacia Medicatel
        version_envio               INT NOT NULL DEFAULT (1),
        pendiente_envio             BIT NOT NULL DEFAULT (1),
        enviado                     BIT NOT NULL DEFAULT (0),
        fecha_envio                 DATETIME2(7) NULL,
        intentos                    INT NOT NULL DEFAULT (0),
        error_envio                 NVARCHAR(1000) NULL,

        -- Auditoria
        fecha_creacion              DATETIME2(7) NOT NULL DEFAULT (SYSDATETIME()),
        fecha_actualizacion         DATETIME2(7) NOT NULL DEFAULT (SYSDATETIME()),

        CONSTRAINT UQ_NOTIFICACION_MEDICATEL_PEDIDO_CONTROL
            UNIQUE (id_control_pedido),

        CONSTRAINT CK_NOTIFICACION_MEDICATEL_ESTADO
            CHECK (estado_control IN (1, 2))
    );

    CREATE INDEX IX_NOTIFICACION_MEDICATEL_PENDIENTES
        ON dbo.NOTIFICACION_MEDICATEL_PEDIDO (pendiente_envio)
        WHERE pendiente_envio = 1;
END;
GO
