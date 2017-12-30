DECLARE @command VARCHAR(1000)
SELECT @command
    = 'USE [?] SELECT ''[?]'', db_id(parsename(base_object_name, 3)) AS dbid
     , object_id(base_object_name) AS objid
     , base_object_name
from sys.synonyms;'
EXEC sys.sp_MSforeachdb @command
