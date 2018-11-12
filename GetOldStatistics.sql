--##############################################################################################
--#
--# This SQL delivers all statistics older than x days and with at least x rows, ordered by age and rowcount descending.
--# Please look at the configuration.
--#
--##############################################################################################
 
DECLARE @MIN_AGE INT
DECLARE @MIN_ROWCOUNT INT
 
 
--##############################################################################################
--
-- Configuration
--
SET @MIN_AGE = 0 --Statistic must be older than x days
SET @MIN_ROWCOUNT = 10 --The table must be have at least x rows
--##############################################################################################
 
 
SELECT SCH.name AS SchemeName
   ,OBJ.name AS TableName
   ,STA.name AS StatisticName
   ,COALESCE(CONVERT(VARCHAR(25), STATS_DATE(STA.object_id, STA.stats_id), 120), 'Noch nie') AS LastStatisticUpdate
   ,TABLEROWCOUNT.TableRowCount
   ,DATEDIFF(d, ISNULL(STATS_DATE(STA.object_id, STA.stats_id), { D N'1900-01-01' }), GETDATE()) AS LastStatisticUpdateXDays
 
FROM sys.stats AS STA
     INNER JOIN sys.objects AS OBJ ON STA.object_id = OBJ.object_id
     INNER JOIN sys.schemas AS SCH ON OBJ.schema_id = SCH.schema_id
     INNER JOIN sys.tables AS T ON T.name = OBJ.name
     INNER JOIN sys.partitions AS P ON P.object_id = T.object_id
                                       AND P.index_id IN (0, 1)
 
     --Rowcount
     INNER JOIN(SELECT SCHEMA_NAME(T.schema_id) AS SchemeName
                   ,T.name AS TableName
                   ,SUM(P.rows) AS TableRowCount
                FROM sys.tables AS T
                     JOIN sys.partitions AS P ON T.object_id = P.object_id
                                                 AND P.index_id IN (0, 1)
                GROUP BY SCHEMA_NAME(T.schema_id)
                   ,T.name
                HAVING SUM(P.rows) > @MIN_ROWCOUNT) AS TABLEROWCOUNT ON TABLEROWCOUNT.TableName = OBJ.name
 
WHERE OBJ.type IN ('U', 'V') -- Only user tables and views
      AND DATEDIFF(d, ISNULL(STATS_DATE(STA.object_id, STA.stats_id), { D N'1900-01-01' }), GETDATE()) > @MIN_AGE
      AND STA.auto_created = 0
 
ORDER BY LastStatisticUpdateXDays DESC
   ,TABLEROWCOUNT.TableRowCount DESC
