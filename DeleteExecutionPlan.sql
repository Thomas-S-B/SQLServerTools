--Find planhandle
SELECT   qs.plan_handle
        ,qs.creation_time
        ,qs.last_execution_time
        ,qs.execution_count
        ,qt.text
FROM     sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
WHERE    qt.text LIKE '%YOUR_TOKEN%'

--And then delete the executionplan with the found plan_handle
DBCC FREEPROCCACHE (FOUND_PLAN_HANDLE_FROM_PREVIOUS_SELECT)
