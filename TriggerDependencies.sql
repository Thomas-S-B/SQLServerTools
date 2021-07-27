SET NOCOUNT ON;

DECLARE @trigger_id BIGINT
   ,@trigger_name NVARCHAR(100)
   ,@trigger_table_view_name NVARCHAR(80)
   ,@trigger_table_schema NVARCHAR(50)
   ,@trigger_text VARCHAR(8000)
   ,@trigger_schema_table_view NVARCHAR(200)
   ,@table_view_name NVARCHAR(80)
   ,@table_schema NVARCHAR(50)
   ,@schema_table_view NVARCHAR(200)


PRINT '-------------------------------------------------------------------------------------------------';
PRINT '-------------------------------- Tables/views and their triggers --------------------------------';
PRINT '------------------ Lists all tables which have triggers using other tables ----------------------';
PRINT '-------------------------------------------------------------------------------------------------';
PRINT ' ';

DECLARE trigger_cursor CURSOR FORWARD_ONLY FAST_FORWARD LOCAL FOR
    SELECT ROW_NUMBER() OVER (ORDER BY SYS_OBJ.name) AS trigger_id
       ,SYS_OBJ.name AS trigger_name
       ,OBJECT_NAME(SYS_OBJ.parent_obj) AS table_name
       ,SYS_SCHEMAS.name AS table_schema
       ,SYS_COMMENTS.text
    FROM sys.sysobjects AS SYS_OBJ
         INNER JOIN sys.tables AS SYS_TABLES ON SYS_TABLES.object_id = SYS_OBJ.parent_obj
         INNER JOIN sys.schemas AS SYS_SCHEMAS ON SYS_SCHEMAS.schema_id = SYS_TABLES.schema_id
         INNER JOIN sys.syscomments AS SYS_COMMENTS ON SYS_COMMENTS.id = SYS_OBJ.id
    WHERE SYS_OBJ.type = 'TR'
    ORDER BY trigger_name
 

OPEN trigger_cursor

FETCH NEXT FROM trigger_cursor

INTO @trigger_id
   ,@trigger_name
   ,@trigger_table_view_name
   ,@trigger_table_schema
   ,@trigger_text

WHILE @@FETCH_STATUS = 0
    BEGIN

-- Check tables and views, used in triggersource
       DECLARE tables_views_cursor CURSOR FORWARD_ONLY FAST_FORWARD LOCAL FOR
            SELECT TABLE_NAME
               ,TABLE_SCHEMA
            FROM INFORMATION_SCHEMA.TABLES
            WHERE TABLE_TYPE = 'BASE TABLE'
                  OR TABLE_TYPE = 'VIEW'
            ORDER BY TABLE_NAME

        OPEN tables_views_cursor
        FETCH NEXT FROM tables_views_cursor
        INTO @table_view_name
           ,@table_schema

        IF @@FETCH_STATUS <> 0 PRINT '        ### NO DEPENDENCIES ###'

        WHILE @@FETCH_STATUS = 0
            BEGIN
                SELECT @trigger_schema_table_view = @trigger_table_schema + N'.' + @trigger_table_view_name
                SELECT @schema_table_view = @table_schema + N'.' + @table_view_name


                IF CHARINDEX(@schema_table_view, @trigger_schema_table_view) < 1
                    BEGIN
                        IF CHARINDEX(@schema_table_view, @trigger_text) > 0
                            BEGIN
                                PRINT @trigger_schema_table_view + ' ----- the trigger ' + @trigger_name + '(id = ' + CAST(@trigger_id AS VARCHAR(MAX)) + ') uses also table -----> ' + @schema_table_view
                                PRINT ' '
                            END
                    END

                FETCH NEXT FROM tables_views_cursor
                INTO @table_view_name
                   ,@table_schema
            END

        CLOSE tables_views_cursor
        DEALLOCATE tables_views_cursor

        FETCH NEXT FROM trigger_cursor

        INTO @trigger_id
           ,@trigger_name
           ,@trigger_table_view_name
           ,@trigger_table_schema
           ,@trigger_text
    END


CLOSE trigger_cursor;
DEALLOCATE trigger_cursor;
