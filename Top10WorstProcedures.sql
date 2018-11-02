SELECT TOP(10)
         ps.object_id
        ,db.name AS db_name
        ,OBJECT_NAME(ps.object_id, ps.database_id) AS proc_name
        ,ps.cached_time
        ,ps.last_execution_time
        ,ps.total_elapsed_time
        ,ps.total_elapsed_time / ps.execution_count AS avg_elapsed_time
        ,ps.last_elapsed_time
        ,ps.execution_count
        ,ps.total_worker_time
FROM     sys.dm_exec_procedure_stats AS ps
  INNER JOIN sys.databases AS db ON db.database_id = ps.database_id
ORDER BY avg_elapsed_time DESC;
