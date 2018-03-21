--###################################################################################################
-- This send an email with the heaviest haelngren updates, which takes 20 or more seconds
--
-- See configuration-part
--###################################################################################################

DECLARE @bodyMsg nvarchar(max)
DECLARE @subject nvarchar(max)
DECLARE @tableHTML nvarchar(max)

SET @subject = 'Halengren Top-Duration'
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
    font-size: 11px !important;
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

N'<H3>Hallengren Top-Durations &gt;= 20 seconds:</H3>' +
N'<table id="box-table" >' +
N'<tr>

<th>Schema</th>
<th>Object</th>
<th>Index</th>
<th>Statistic</th>
<th>Start</th>
<th>End</th>
<th>Duration (s)</th>
<th>Command</th>
</tr>' +

CAST ( (
SELECT td = CAST(SchemaName AS VARCHAR(100)),'',
             td = ObjectName,'',
             td = COALESCE(IndexName, CONVERT(VARCHAR(300),IndexName,120), '') ,'',
             td = COALESCE(StatisticsName, CONVERT(VARCHAR(300),StatisticsName,120), '') ,'',
             td = COALESCE(starttime, CONVERT(VARCHAR(30),starttime,120), '') ,'',
             td = COALESCE(EndTime, CONVERT(VARCHAR(30),EndTime,120), '') ,'',
             td = CONVERT(VARCHAR(30),DATEDIFF(ss,starttime, endtime),120) ,'',
             td = COALESCE(command, CONVERT(VARCHAR(30),command,120), '') ,''
       FROM [master].[dbo].[CommandLog]
             --WHERE DATEDIFF(Mi,starttime, endtime) >= 1
             WHERE DATEDIFF(ss,starttime, endtime) >= 20
             AND StartTime > DATEADD(dd, DATEDIFF(dd, 0, getdate()), 0)  --Nur vom aktuellen Datum (ohne Zeit)
                                --AND StatisticsName IS NOT NULL
             ORDER BY DATEDIFF(ss,starttime, endtime) DESC
FOR XML PATH('tr'), TYPE
) AS NVARCHAR(MAX) ) +
N'</table>'

EXEC msdb.dbo.sp_send_dbmail @recipients='joe.doq@compuserve.com',
@subject = @subject,
@body = @tableHTML,
@body_format = 'HTML' ;
