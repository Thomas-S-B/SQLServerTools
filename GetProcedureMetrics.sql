SELECT   d2.name
        ,d.object_id
        ,d.database_id
        ,OBJECT_NAME(d.object_id, d.database_id) 'procname'
        ,d.cached_time
        ,d.last_execution_time
        ,d.total_elapsed_time
        ,d.total_elapsed_time / d.execution_count AS avg_elapsed_time
        ,d.last_elapsed_time
        ,d.execution_count
FROM     sys.dm_exec_procedure_stats AS d --WHERE    OBJECT_NAME(d.object_id, d.database_id) LIKE '%MY PROCEDURENAME%'
INNER JOIN sys.databases AS d2 ON d2.database_id = d.database_id
ORDER BY d2.name
        ,OBJECT_NAME(d.object_id, d.database_id)
        ,d.last_execution_time

--ORDER BY [total_worker_time] DESC;
