-- Cleansup histories to a size of the last 60 days
-- Perhaps necessary if browsing of the history runs into an "Out of memory"

-- Cleanup backuphistory
--DECLARE @dt DATETIME
--SET @dt = GETDATE() - 60
--EXEC msdb.dbo.sp_delete_backuphistory @dt
--GO

-- Cleanup jobhistory
--DECLARE @dt DATETIME
--SET @dt = GETDATE() - 60
--EXEC msdb.dbo.sp_purge_jobhistory  @oldest_date=@dt
--GO

-- Cleanup maintenance log
DECLARE @dt DATETIME
SET @dt = GETDATE() - 60
EXEC msdb..sp_maintplan_delete_log null,null,@dt
GO
