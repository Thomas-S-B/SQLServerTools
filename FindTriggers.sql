SELECT   OBJ.name
        ,COM.text
		    ,*
FROM     sys.objects AS OBJ
INNER JOIN sys.syscomments AS COM ON OBJ.object_id = COM.id
WHERE    OBJ.type = 'TR'
--AND COM.text LIKE '%exec ABCDEF%'

