--Example: Sets AUTO_CLOSE to OFF on all databases with AUTO_CLOSE = ON
DECLARE @cursor_DBs CURSOR
DECLARE @MyDBs VARCHAR(500)
DECLARE @error_msg VARCHAR(500)
DECLARE @MyErrors TABLE
   (myErrorMessage VARCHAR(1000)
   )
DECLARE @SQL VARCHAR(8000) 


--Create cursor over all relevant databases
SET 
@cursor_DBs = CURSOR FOR
SELECT   d.name 
FROM sys.databases AS d
WHERE d.is_auto_close_on = 1


--Execute SQL on all databases
OPEN @cursor_DBs
FETCH NEXT
FROM @cursor_DBs INTO @MyDBs
WHILE @@FETCH_STATUS = 0
BEGIN
   BEGIN TRY 
      SET @SQL = '' 
      SELECT   @SQL = @SQL + 'ALTER DATABASE ' + @MyDBs
               + ' SET AUTO_CLOSE OFF;' 
      EXEC(@SQL)
   END TRY
   BEGIN CATCH
	    --There was an error and log it
      INSERT   INTO @MyErrors
      VALUES   (@MyDBs + ' -- ' + ERROR_MESSAGE())
   END CATCH 

   FETCH NEXT
   FROM @cursor_DBs INTO @MyDBs
END


SELECT   *
FROM     @MyErrors AS me
ORDER BY me.myErrorMessage

--Cleanup
CLOSE @cursor_DBs
DEALLOCATE @cursor_DBs
