SELECT
    plan_handle
   ,creation_time
   ,last_execution_time
   ,execution_count
   ,QT.text
   --QS.*
   --,QT.*
FROM 
   sys.dm_exec_query_stats AS QS
   CROSS APPLY sys.dm_exec_sql_text (QS.[sql_handle]) AS QT
WHERE QT.text LIKE 'declare @p5 dbo.IDLIST%'
ORDER BY QS.last_execution_time DESC
