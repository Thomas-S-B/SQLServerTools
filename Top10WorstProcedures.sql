SELECT TOP 10
         d.object_id
        ,d.database_id
        ,OBJECT_NAME(d.object_id, d.database_id) AS 'proc name'
        ,d.cached_time
        ,d.last_execution_time
        ,d.total_elapsed_time
        ,d.total_elapsed_time / d.execution_count AS avg_elapsed_time
        ,d.last_elapsed_time
        ,d.execution_count
		    ,d.total_worker_time
FROM     sys.dm_exec_procedure_stats AS d
ORDER BY avg_elapsed_time DESC;
