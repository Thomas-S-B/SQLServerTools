--#############################################################################################################
--
--Configuration
--
--#############################################################################################################
DECLARE @Filepath VARCHAR(1000) = N'\\domain\blah\blah\Mydata.txt'
DECLARE @Fieldseparator CHAR(1) = ',';
DECLARE @Rowseparator CHAR(1) = CHAR(10);




--Cleanup from previous runs
IF OBJECT_ID('tempdb..#MyTextImport') IS NOT NULL
   DROP TABLE #MyTextImport;

--Create table for output
DECLARE @MyRows TABLE
   (MyCol1 VARCHAR(8000)
   ,MyCol2 VARCHAR(8000)
   ,MyCol3 VARCHAR(8000)
   ,MyCol4 VARCHAR(8000)
   );

--Build SQL
DECLARE @Generated_SQL VARCHAR(8000) = ' 
    CREATE TABLE #MyTextImport (
        MyCol1 VARCHAR(8000),
        MyCol2 VARCHAR(8000),
        MyCol3 VARCHAR(8000),
        MyCol4 VARCHAR(8000)
    );

    BULK INSERT #MyTextImport
        FROM ''' + @Filepath + '''
        WITH (FirstRow = 1, FieldTerminator = ''' + @Fieldseparator
   + ''', RowTerminator = ''' + @Rowseparator + ''');

    SELECT * FROM #MyTextImport';

--Insert data in generated table
INSERT   INTO @MyRows
         EXEC (@Generated_SQL
             );

--Output data
SELECT   *
FROM     @MyRows


--Cleanup
IF OBJECT_ID('tempdb..#MyTextImport') IS NOT NULL
   DROP TABLE #MyTextImport;
