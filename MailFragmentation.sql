--###################################################################################################
-- Sending an mail with all indexes > 100 pages and >=5% fragmentation
--
--###################################################################################################

DECLARE @bodyMsg nvarchar(max)
DECLARE @subject nvarchar(max)
DECLARE @tableHTML nvarchar(max)

SET @subject = db_name() + ' indexes > 100 pages and >=5% fragmentation'

SET @tableHTML =
N'<style type="text/css">
h3
{
font-family: Helvetica !important;
font-size: 18px !important;
text-align: left;
}

table { 
    color: #333;
    font-family: Helvetica, Arial, sans-serif;
    border-collapse:
    collapse; border-spacing: 0;
}

td, th { border: 1px solid #CCC; height: 25px; padding: 5px;}

th { 
    background: #F3F3F3;
    font-weight: bold;
}

td { 
    background: #FAFAFA;
    text-align: center;
    padding: 2px;
}

tr:nth-child(even) td { background: #F1F1F1; }  
tr:nth-child(odd) td { background: #FEFEFE; } 
tr td:hover { background: #888; color: #FFF; } 
</style>'+
N'<H3>' + db_name() + ' indexes > 100 pages and >=5% fragmentation' +
N' (time ' + CONVERT(char(19), GetDate(),121) + '):</H3>' +
N'<table id="box-table" >' +
N'<tr>
<th>Index</th>
<th>avg_fragmentation_in_percent</th>
<th>avg_fragment_size_in_pages</th>
<th>page_count</th>
<th>fill_factor</th>
</tr>' +
CAST ( (

SELECT  td = CAST(dbschemas.name + '.' + dbtables.name + '  ' + ISNULL(dbindexes.name, 'HEAP') AS VARCHAR(100)),'',
        td = CAST(indexstats.avg_fragmentation_in_percent AS VARCHAR(100)),'',
        td = CAST(indexstats.avg_fragment_size_in_pages AS VARCHAR(100)),'',
        td = indexstats.page_count,'',
        td = dbindexes.fill_factor,''

FROM     sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, NULL) AS indexstats
INNER JOIN sys.tables dbtables ON dbtables.object_id = indexstats.object_id
INNER JOIN sys.schemas dbschemas ON dbtables.schema_id = dbschemas.schema_id
INNER JOIN sys.indexes AS dbindexes ON dbindexes.object_id = indexstats.object_id
                                       AND indexstats.index_id = dbindexes.index_id
WHERE    indexstats.database_id = DB_ID()
AND indexstats.page_count > 50 AND indexstats.avg_fragmentation_in_percent >= 5
ORDER BY  indexstats.avg_fragmentation_in_percent DESC

FOR XML PATH('tr'), TYPE
) AS NVARCHAR(MAX) ) +
N'</table>'
 

EXEC msdb.dbo.sp_send_dbmail @recipients='John.Doe@aol.com',
@subject = @subject,
@body = @tableHTML,
@body_format = 'HTML' ;
