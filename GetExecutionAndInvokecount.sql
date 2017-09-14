SELECT 
    OBJECT_NAME(st.objectid,st.dbid) AS ObjectName,
    cp.usecounts AS ExecutionCount,
    st.TEXT AS QueryText,
    qp.query_plan AS QueryPlan,
*
FROM 
    sys.dm_exec_cached_plans AS cp
    CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS qp
    CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) AS st
WHERE 
    cp.objtype = 'Proc'
    AND OBJECT_NAME(st.objectid,st.dbid) LIKE '%NAME_OF_MY_PROCEDUREg%'
