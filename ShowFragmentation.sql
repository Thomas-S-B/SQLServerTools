SELECT   dbschemas.name AS 'Schema'
        ,dbtables.name AS 'Tabelle'
        ,dbindexes.name AS 'Index'
        ,indexstats.avg_fragmentation_in_percent
        ,indexstats.avg_fragment_size_in_pages 
        ,indexstats.fragment_count 
        ,indexstats.page_count
        ,dbindexes.fill_factor 
        ,dbtables.type_desc 
       -- ,*
FROM     sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, NULL) AS indexstats
INNER JOIN sys.tables dbtables ON dbtables.object_id = indexstats.object_id
INNER JOIN sys.schemas dbschemas ON dbtables.schema_id = dbschemas.schema_id
INNER JOIN sys.indexes AS dbindexes ON dbindexes.object_id = indexstats.object_id
                                       AND indexstats.index_id = dbindexes.index_id
WHERE    indexstats.database_id = DB_ID()
AND indexstats.page_count > 100 AND indexstats.avg_fragmentation_in_percent >10
ORDER BY  fill_factor, indexstats.avg_fragmentation_in_percent
