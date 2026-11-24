USE [msdb]
GO

/* ============================================================
   JOB: SincronizarFarmaciaStaffID

   Corre una vez al dia (6:00 AM) y ejecuta
   dbo.SP_AGENTE_SINCRONIZAR_FARMACIA_STAFFID sobre PedidosWeb,
   corrigiendo el StaffID de agentes de farmacia que se
   trasladaron de sucursal segun HQ.

   Ajusta @active_start_time (formato HHMMSS) si prefieres otra
   hora.
   ============================================================ */

BEGIN TRANSACTION
DECLARE @ReturnCode INT = 0;
DECLARE @jobId BINARY(16);

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name = N'[Uncategorized (Local)]' AND category_class = 1)
BEGIN
    EXEC @ReturnCode = msdb.dbo.sp_add_category @class = N'JOB', @type = N'LOCAL', @name = N'[Uncategorized (Local)]';
END

EXEC @ReturnCode = msdb.dbo.sp_add_job
    @job_name = N'SincronizarFarmaciaStaffID',
    @enabled = 1,
    @notify_level_eventlog = 0,
    @notify_level_email = 0,
    @notify_level_netsend = 0,
    @notify_level_page = 0,
    @delete_level = 0,
    @description = N'Corrige el StaffID de agentes de farmacia que cambiaron de sucursal segun HQ (SP_AGENTE_SINCRONIZAR_FARMACIA_STAFFID).',
    @category_name = N'[Uncategorized (Local)]',
    @owner_login_name = N'sa',
    @job_id = @jobId OUTPUT;

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep
    @job_id = @jobId,
    @step_name = N'sincronizar',
    @step_id = 1,
    @cmdexec_success_code = 0,
    @on_success_action = 1,
    @on_fail_action = 2,
    @retry_attempts = 0,
    @retry_interval = 0,
    @os_run_priority = 0,
    @subsystem = N'TSQL',
    @command = N'
DECLARE @mensaje NVARCHAR(500), @actualizados INT;
EXEC dbo.SP_AGENTE_SINCRONIZAR_FARMACIA_STAFFID
    @mensaje = @mensaje OUTPUT,
    @actualizados = @actualizados OUTPUT;
',
    @database_name = N'PedidosWeb',
    @flags = 0;

EXEC @ReturnCode = msdb.dbo.sp_update_job
    @job_id = @jobId,
    @start_step_id = 1;

DECLARE @sch INT;

EXEC @ReturnCode = msdb.dbo.sp_add_schedule
    @schedule_name = N'diario 6am',
    @enabled = 1,
    @freq_type = 4,              -- diario
    @freq_interval = 1,          -- cada 1 dia
    @freq_subday_type = 1,       -- una sola vez en el dia
    @active_start_time = 060000, -- 06:00:00
    @schedule_id = @sch OUTPUT;

EXEC @ReturnCode = msdb.dbo.sp_attach_schedule
    @job_id = @jobId,
    @schedule_id = @sch;

EXEC @ReturnCode = msdb.dbo.sp_add_jobserver
    @job_id = @jobId,
    @server_name = N'(local)';

COMMIT TRANSACTION
GO
