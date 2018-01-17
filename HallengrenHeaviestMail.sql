--###################################################################################################
-- This send an email with the heaviest statisticupdates, which takes 1 or more minutes
--
-- See configuration-part
--###################################################################################################

DECLARE @bodyMsg nvarchar(max)
DECLARE @subject nvarchar(max)
DECLARE @tableHTML nvarchar(max)

SET @subject = 'Hallengren heavy statisticsupdates'


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

td, th { border: 1px solid #CCC; height: 25px; }

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

N'<H3>Statisticupdates Hallengren &gt;= 1 Minute:</H3>' +
N'<table id="box-table" >' +
N'<tr>
<th>SchemaName</th>
<th>ObjectName</th>
<th>StatisticsName</th>
<th>Start</th>
<th>Ende</th>
<th>Dauer in Minuten</th>
</tr>' +

CAST ( (

SELECT           td = CAST(SchemaName AS VARCHAR(100)),'',
                 td = ObjectName,'',
                 td = CONVERT(VARCHAR(300),StatisticsName,120) ,'',
                 td = CONVERT(VARCHAR(30),starttime,120) ,'',
                 td = CONVERT(VARCHAR(30),EndTime,120) ,'',
                 td = CONVERT(VARCHAR(30),DATEDIFF(Mi,starttime, endtime),120) ,''
FROM [master].[dbo].[CommandLog]
WHERE DATEDIFF(Mi,starttime, endtime) >= 1
      AND StartTime > DATEADD(dd, DATEDIFF(dd, 0, getdate()), 0)           --Get current date withozt time
      AND StatisticsName IS NOT NULL
ORDER BY DATEDIFF(Mi,starttime, endtime) DESC
FOR XML PATH('tr'), TYPE
) AS NVARCHAR(MAX) ) +
N'</table>'


EXEC msdb.dbo.sp_send_dbmail @recipients='john.doe@aol.com;sue.moe@compuserve.com',
@subject = @subject,
@body = @tableHTML,
@body_format = 'HTML' ;
