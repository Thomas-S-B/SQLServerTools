-- Query and analyze a tracefile from SQL Profiler
SELECT *
FROM::fn_trace_gettable('Path_to_your_tracefile_from_sql_profiler.trc', DEFAULT)
ORDER BY Duration -- Or you can ORDER BY starttime etc.

