--###################################################################################################
-- Dieser SQL verschickt per Mail alle Aufträge als grafischen Zeitstrahl
--
-- Konfiguriert kann im Teil 'Konfiguration' werden
--
--###################################################################################################

 

SET NOCOUNT ON
 

DECLARE @DT DATETIME
DECLARE @StartDatum DATETIME
DECLARE @EndeDatum DATETIME
DECLARE @MindestLaufzeitInSekunden INT
DECLARE @EmailEmpfaenger VARCHAR(500)
DECLARE @EmailNurBeiFehlerEmpfaenger VARCHAR(500)
DECLARE @Tage INT
DECLARE @Stunden INT
DECLARE @Servername VARCHAR(50)
 

--###################################################################################################
-- Konfiguration
--###################################################################################################

--Wer soll eine Mail bekommen?
SET @EmailEmpfaenger = 'Jenny.Doe@abc.com;John.Doe@abc.com'

--Wer soll nur bei einem fehlerhaften Auftrag eine Mail bekommen?
SET @EmailNurBeiFehlerEmpfaenger = ''

--Wie viele Tage soll in die Vergangenheit gegangen werden?
SET @Tage = 1

--Wie viele Stunden soll in die Vergangenheit gegangen werden?
SET @Stunden = 0

--Wie lange soll ein Auftrag mindestens gedauert haben, damit er angezeigt wird?
SET @MindestLaufzeitInSekunden = 0


SET @StartDatum = DateAdd(hh, -(@Stunden), GETDATE() - @Tage)
SET @EndeDatum = GETDATE()

--###################################################################################################
-- Textliterale
--###################################################################################################
DECLARE @TEXT_ERFOLGREICH VARCHAR(20)
SET @TEXT_ERFOLGREICH = 'Erfolgreich'

 

--###################################################################################################
-- Farben
--###################################################################################################
DECLARE @FARBE_FEHLER VARCHAR(10)
SET @FARBE_FEHLER = '#FF4136'

DECLARE @FARBE_ERFOLGREICH VARCHAR(10)
SET @FARBE_ERFOLGREICH = '#2ECC40'

DECLARE @FARBE_NEUVERSUCH VARCHAR(10)
SET @FARBE_NEUVERSUCH = '#FFDC00'

DECLARE @FARBE_ABGEBROCHEN VARCHAR(10)
SET @FARBE_ABGEBROCHEN = '#AAAAAA'

DECLARE @FARBE_UNDEFINIERT VARCHAR(10)
SET @FARBE_UNDEFINIERT = '#111111'

DECLARE @FARBE_LAEUFT VARCHAR(10)
SET @FARBE_LAEUFT = '#7FDBFF'

DECLARE @FARBE_NEUSTART VARCHAR(10)
SET @FARBE_NEUSTART = '#FF851B'
 

--###################################################################################################
-- Aufräumen, falls vorher was hängen blieb
--###################################################################################################
IF OBJECT_ID('tempdb..#AuftragsLaufzeiten') IS NOT NULL
   DROP TABLE #AuftragsLaufzeiten;
IF OBJECT_ID('tempdb..##ZeitstrahlGraph') IS NOT NULL
   DROP TABLE ##ZeitstrahlGraph;
 

--###################################################################################################
-- Tabelle für die HTML anlegen
--###################################################################################################
CREATE TABLE ##ZeitstrahlGraph
   (ID INT IDENTITY(1, 1)
           NOT NULL
   ,HTML VARCHAR(8000) NULL                         --8000, damit es auch mit Servern < 2008R2 funktioniert
   )

 
--###################################################################################################
-- Tabelle der Aufträge anlegen
--###################################################################################################
SELECT   AUFTRAEGE.*
INTO     #AuftragsLaufzeiten
FROM     (
--Gelaufene Aufträge, welche abgeschlossen sind
          SELECT  job.name AS JobName
                 ,cat.name AS CatName
                 ,CONVERT(DATETIME, CONVERT(CHAR(8), his.run_date, 112) + ' '
                  + STUFF(STUFF(RIGHT('000000'
                                      + CONVERT(VARCHAR(8), his.run_time), 6),
                                5, 0, ':'), 3, 0, ':'), 120) AS SDT
                 ,DATEADD(s,
                          ((his.run_duration / 10000) % 100 * 3600)
                          + ((his.run_duration / 100) % 100 * 60)
                          + his.run_duration % 100,
                          CONVERT(DATETIME, CONVERT(CHAR(8), his.run_date, 112)
                          + ' ' + STUFF(STUFF(RIGHT('000000'
                                                    + CONVERT(VARCHAR(8), his.run_time),
                                                    6), 5, 0, ':'), 3, 0, ':'), 120)) AS EDT
                 ,job.description
                 ,his.run_status
                 ,CASE WHEN his.run_status = 0 THEN @FARBE_FEHLER               
                       WHEN his.run_status = 1 THEN @FARBE_ERFOLGREICH
                       WHEN his.run_status = 2 THEN @FARBE_NEUVERSUCH
                       WHEN his.run_status = 3 THEN @FARBE_ABGEBROCHEN
                       ELSE @FARBE_UNDEFINIERT
                  END AS JobStatus
                 ,CASE WHEN his.run_status = 0 THEN his.message           -- 0 = Fehler (rot)
                       WHEN his.run_status = 1 THEN @TEXT_ERFOLGREICH   -- 1 = Erfolgreich (grün)
                       WHEN his.run_status = 2 THEN his.message                 -- 2 = Neuversuch (gelb)
                       WHEN his.run_status = 3 THEN his.message                 -- 3 = Abgebrochen (grau)
                       ELSE his.message                                                                                                     -- undefinierter Status (schwarz)
                  END AS JobMeldung
          FROM    msdb.dbo.sysjobs AS job
          LEFT JOIN msdb.dbo.sysjobhistory AS his ON his.job_id = job.job_id
          INNER JOIN msdb.dbo.syscategories AS cat ON job.category_id = cat.category_id
          WHERE   CONVERT(DATETIME, CONVERT(CHAR(8), his.run_date, 112) + ' '
                  + STUFF(STUFF(RIGHT('000000'
                                      + CONVERT(VARCHAR(8), his.run_time), 6),
                                5, 0, ':'), 3, 0, ':'), 120) BETWEEN @StartDatum
                                                             AND
                                                              @EndeDatum
                  AND his.step_id = 0 -- step_id = 0 ist der eigentliche Auftrag, step_id > 0 sind die Einzelschritte davon
                  AND ((his.run_duration / 10000) % 100 * 3600)
                  + ((his.run_duration / 100) % 100 * 60) + his.run_duration
                  % 100 >= @MindestLaufzeitInSekunden
          UNION ALL

--Aktuell laufende Aufträge
          SELECT  JOB.name AS JobName
                 ,cat.name AS CatName
                 ,ja.start_execution_date AS SDT
                 ,GETDATE() AS EDT
                 ,JOB.description
                 ,HIS.run_status
                 ,CASE WHEN HIS.run_status = 0 THEN @FARBE_FEHLER
                       WHEN HIS.run_status = 1 THEN @FARBE_ERFOLGREICH
                       WHEN HIS.run_status = 2 THEN @FARBE_NEUVERSUCH
                       WHEN HIS.run_status = 3 THEN @FARBE_ABGEBROCHEN
                       WHEN HIS.run_status IS NULL THEN @FARBE_LAEUFT
                       ELSE @FARBE_UNDEFINIERT
                  END AS JobStatus
                 ,CASE WHEN HIS.run_status = 0 THEN HIS.message          -- 0 = Fehler (rot)
                       WHEN HIS.run_status = 1 THEN @TEXT_ERFOLGREICH   -- 1 = Erfolgreich (grün)
                       WHEN HIS.run_status = 2 THEN HIS.message               -- 2 = Neuversuch (gelb)
                       WHEN HIS.run_status = 3 THEN HIS.message               -- 3 = Abgebrochen (grau)
                       WHEN HIS.run_status IS NULL THEN 'Läuft aktuell'
                       ELSE HIS.message                                                                                                     -- undefinierter Status (schwarz)
                  END AS JobMeldung
          FROM    msdb.dbo.sysjobactivity ja
          LEFT JOIN msdb.dbo.sysjobhistory AS HIS ON ja.job_history_id = HIS.instance_id
          JOIN    msdb.dbo.sysjobs AS JOB ON ja.job_id = JOB.job_id
          JOIN    msdb.dbo.sysjobsteps js ON ja.job_id = js.job_id
                                             AND ISNULL(ja.last_executed_step_id,
                                                        0) + 1 = js.step_id
          LEFT JOIN msdb.dbo.syscategories AS cat ON JOB.category_id = cat.category_id
          WHERE   ja.session_id = (SELECT TOP 1
                                          session_id
                                   FROM   msdb.dbo.syssessions
                                   ORDER BY agent_start_date DESC
                                  )
                  AND ja.start_execution_date IS NOT NULL
                  AND ja.stop_execution_date IS NULL
         ) AS AUFTRAEGE
ORDER BY AUFTRAEGE.JobName
 

IF NOT EXISTS ( SELECT  1
                FROM    #AuftragsLaufzeiten )
   GOTO NichtsZuTun
 
 
--###################################################################################################
-- Hinweis Fehler
--###################################################################################################
DECLARE @FEHLERANZAHL AS INTEGER
DECLARE @FEHLERVORHANDEN_TEXT AS VARCHAR(50)
SET @FEHLERANZAHL = (SELECT COUNT(*) FROM #AuftragsLaufzeiten WHERE run_status=0)
IF @FEHLERANZAHL > 0
   SET @FEHLERVORHANDEN_TEXT = 'Es sind ' + CONVERT(varchar(4), @FEHLERANZAHL) +' fehlerhafte Aufträge vorhanden.'
ELSE
   SET @FEHLERVORHANDEN_TEXT = ''
 
   
 
--###################################################################################################
-- Html Zeitstrahl - Kopf
-- Wird in mehrere Inserts aufgeteilt, da per Standrd Text maxmial 256 Zeichen
--###################################################################################################
INSERT   INTO ##ZeitstrahlGraph
         (HTML
         )
SELECT   '<html>
                <head>
                               <style>
                                  .google-visualization-tooltip {
                                                  width: 400px !important;
                                                  height: 200px !important;
                                                  border-radius: 8px !important;
                                                  border: 2px solid rgb(1, 1, 1) !important;
                                                  background-color: rgb(50, 50, 50) !important;
                                                  color: rgb(230, 230, 230) !important;
                                                  font-size: 14px !important;
                                                  font-family: Helvetica !important;
                                                  box-shadow: 7px 5px 7px 0px rgba(50, 50, 50, 0.75) !important;
                                                  padding: 6px 6px 6px 6px !important;
                                                  opacity: 0.85 !important;                      }
'
 
INSERT   INTO ##ZeitstrahlGraph
         (HTML
         )
SELECT   '
                               #legende ul, li {
                                               margin: 0px;
                                               list-style: none;
                                               display: inline-block;
                                               font-size: 14px;
                                               font-family: Helvetica;
                                               padding: 0px 0px 5px 0px;
                               }
 
                               .rectangleBasis,
                               .legendeErfolg,
                               .legendeLaeuft,
                               .legendeFehler,
                               .legendeNeuversuch,
                               .legendeAbgebrochen,
                               .legendeServerneustart,
                               .legendeUndefiniert {
                                               float: left;
                                               width: 30px;
                                               height: 15px;
                                               margin: 0px 3px 0px 15px;
                               }
                               .legendeErfolg {
                                               background: '+ @FARBE_ERFOLGREICH + ';
                               }
                               .legendeLaeuft {
                                               background: '+ @FARBE_LAEUFT + ';
                               }
                               .legendeFehler {
                                               background: '+ @FARBE_FEHLER + ';
                               }
                               .legendeNeuversuch {
                                               background: '+ @FARBE_NEUVERSUCH + ';
                               }
                               .legendeAbgebrochen {
                                               background: '+ @FARBE_ABGEBROCHEN + ';
                               }
                               .legendeServerneustart {
                                               background: '+ @FARBE_NEUSTART + ';
                               }
                               .legendeUndefiniert {
                                               background: '+ @FARBE_UNDEFINIERT + ';
                               }
'

INSERT   INTO ##ZeitstrahlGraph
         (HTML)
SELECT   '</style>'
 
 
INSERT   INTO ##ZeitstrahlGraph
         (HTML
         )
SELECT   '<!--<META HTTP-EQUIV="refresh" CONTENT="3">-->
                <script type="text/javascript" src="https://www.google.com/jsapi?autoload={''modules'':[{''name'':''visualization'', ''version'':''1'',''packages'':[''timeline'']}]}"></script>'
INSERT   INTO ##ZeitstrahlGraph
         (HTML
         )
SELECT   '    <script type="text/javascript">
                google.setOnLoadCallback(drawChart);
                function drawChart() {'
INSERT   INTO ##ZeitstrahlGraph
         (HTML
         )
SELECT   '              var container = document.getElementById(''Zeitstrahl'');
                var chart = new google.visualization.Timeline(container);
                var dataTable = google.visualization.arrayToDataTable(['
 
INSERT   INTO ##ZeitstrahlGraph
         (HTML
         )
SELECT   '[''Category'', ''Name'', {role: ''style''}, ''Start'', ''End''],'
 
--###################################################################################################
-- Html Zeitstrahl - Daten Aufträge
--###################################################################################################
INSERT   INTO ##ZeitstrahlGraph
         (HTML
         )
SELECT   '                             [ ' + '''' + JobName + ''','''', ''' + JobStatus + ''', '
         + 'new Date(' + CAST(DATEPART(YEAR, SDT) AS VARCHAR(4)) + ', '
         + CAST(DATEPART(MONTH, SDT) - 1 AS VARCHAR(4)) --Javascriptmonate beginnen mit 0
         + ', ' + CAST(DATEPART(DAY, SDT) AS VARCHAR(4)) + ', '
         + CAST(DATEPART(HOUR, SDT) AS VARCHAR(4)) + ', '
         + CAST(DATEPART(MINUTE, SDT) AS VARCHAR(4)) + ', '
         + CAST(DATEPART(SECOND, SDT) AS VARCHAR(4)) + '), ' + 'new Date('
         + CAST(DATEPART(YEAR, EDT) AS VARCHAR(4)) + ', '
         + CAST(DATEPART(MONTH, EDT) - 1 AS VARCHAR(4)) --Javascriptmonate beginnen mit 0
         + ', ' + CAST(DATEPART(DAY, EDT) AS VARCHAR(4)) + ', '
         + CAST(DATEPART(HOUR, EDT) AS VARCHAR(4)) + ', '
         + CAST(DATEPART(MINUTE, EDT) AS VARCHAR(4)) + ', '
         + CAST(DATEPART(SECOND, EDT) AS VARCHAR(4)) + ') ],' --+ char(10)
FROM     #AuftragsLaufzeiten
 
--###################################################################################################
-- Html Zeitstrahl - Daten Letzter Serverneustart
--###################################################################################################
DECLARE @ServerNeustart AS DATETIME
SET @ServerNeustart = (SELECT login_time FROM sys.dm_exec_sessions WHERE session_id=1) --AND login_time >= @StartDatum)
 
INSERT   INTO ##ZeitstrahlGraph
         (HTML
         )
SELECT   '                             [ ' + '''' + 'Letzter Serverneustart' + ''','''', ''' + @FARBE_NEUSTART + ''', '
         + 'new Date(' + CAST(DATEPART(YEAR, @ServerNeustart) AS VARCHAR(4)) + ', '
         + CAST(DATEPART(MONTH, @ServerNeustart) - 1 AS VARCHAR(4)) --Javascriptmonate beginnen mit 0
         + ', ' + CAST(DATEPART(DAY, @ServerNeustart) AS VARCHAR(4)) + ', '
         + CAST(DATEPART(HOUR, @ServerNeustart) AS VARCHAR(4)) + ', '
         + CAST(DATEPART(MINUTE, @ServerNeustart) AS VARCHAR(4)) + ', '
         + CAST(DATEPART(SECOND, @ServerNeustart) AS VARCHAR(4)) + '), ' + 'new Date('
         + CAST(DATEPART(YEAR, @ServerNeustart) AS VARCHAR(4)) + ', '
         + CAST(DATEPART(MONTH, @ServerNeustart) - 1 AS VARCHAR(4)) --Javascriptmonate beginnen mit 0
         + ', ' + CAST(DATEPART(DAY, @ServerNeustart) AS VARCHAR(4)) + ', '
         + CAST(DATEPART(HOUR, @ServerNeustart) AS VARCHAR(4)) + ', '
         + CAST(DATEPART(MINUTE, @ServerNeustart) AS VARCHAR(4)) + ', '
         + CAST(DATEPART(SECOND, @ServerNeustart) AS VARCHAR(4)) + ') ],' --+ char(10)
WHERE @ServerNeustart >= @StartDatum
 
--###################################################################################################
-- Html Zeitstrahl - Fuss
--###################################################################################################
INSERT   INTO ##ZeitstrahlGraph
         (HTML
         )
SELECT   '              ]);
                var options =
                {
                               timeline:                 {
                                                                              groupByRowLabel: true,
                                                                              colorByRowLabel: false,
                                                                              singleColor: false,
                                                                              rowLabelStyle: {fontName: ''Helvetica'', fontSize: 11 },
                                                                              barLabelStyle: {fontName: ''Helvetica'', fontSize: 7 }                                                                       
                                                                              },
        hAxis: {format: "dd.MM.yyyy - HH:mm"}
                };
                chart.draw(dataTable, options);
'
 
 
--###################################################################################################
-- Html Zeitstrahl - Tooltip - Zusätzliche Daten
--###################################################################################################
INSERT   INTO ##ZeitstrahlGraph
         (HTML
         )
SELECT   'var dataTableZusaetzlicheDaten = google.visualization.arrayToDataTable(['
 
 
INSERT   INTO ##ZeitstrahlGraph
         (HTML
         )
SELECT   '[''Zusatz1''],'
 
 
--Aufträge
INSERT   INTO ##ZeitstrahlGraph
         (HTML
         )
SELECT   '[' + '''' + LEFT(REPLACE(COALESCE(JobMeldung, ''), '''', ''), 200) + '''],'
FROM     #AuftragsLaufzeiten
 
--Serverneustart
INSERT   INTO ##ZeitstrahlGraph
         (HTML
         )
SELECT   '[' + '''' + '' + '''],'
FROM sys.dm_exec_sessions
WHERE session_id =1
AND login_time >= @StartDatum
 
 
INSERT   INTO ##ZeitstrahlGraph
         (HTML)
SELECT   '              ]);'
 
 
INSERT   INTO ##ZeitstrahlGraph
         (HTML
         )
SELECT   '                                             google.visualization.events.addListener(chart, ''onmouseover'', function (e) {
                                                               setTooltipContent(dataTable, e.row);
                                               });
                                               function setTooltipContent(dataTable, row) {
                                                               if (row != null) {
                                                                              var content = ''<div class="custom-tooltip" ><h3>'' + dataTable.getValue(row, 0) + ''</h3>'' +
                                                                                              ''</div>'' +
                                                                                              ''<div>Von '' + formatDate(dataTable.getValue(row, 3)) + '' bis '' + formatDate(dataTable.getValue(row, 4)) + ''</div>'' +
                                                                                              ''<br/><div>Dauer: '' + (dateDiff(dataTable.getValue(row, 3), dataTable.getValue(row, 4))) + ''</div>'' +
                                                                                              ''<br/><div>'' + (dataTableZusaetzlicheDaten.getValue(row, 0)) + ''</div>''
                                                                                              ;
                                                                              var tooltip = document.getElementsByClassName("google-visualization-tooltip")[0];
                                                                              tooltip.innerHTML = content;
                                                               }
                                               }
                                               '
 
INSERT   INTO ##ZeitstrahlGraph
         (HTML
         )
SELECT   '
                                               function formatDate(d) {
                                                               return ("0" + d.getDate()).slice(-2) + "." + ("0" + (d.getMonth() + 1)).slice(-2) + "." + d.getFullYear() + " " + ("0" + d.getHours()).slice(-2) + ":" + ("0" + d.getMinutes()).slice(-2) + ":" + ("0" + d.getSeconds()).slice(-2);
                                               }
                                               function dateDiff(dateNow, dateFuture) {
                                                               var seconds = Math.floor((dateFuture - (dateNow)) / 1000);
                                                               var minutes = Math.floor(seconds / 60);
                                                               var hours = Math.floor(minutes / 60);
                                                               var days = Math.floor(hours / 24);
                                                               hours = hours - (days * 24);
                                                               minutes = minutes - (days * 24 * 60) - (hours * 60);
                                                               seconds = seconds - (days * 24 * 60 * 60) - (hours * 60 * 60) - (minutes * 60);
                                                               return ("0" + days).slice(-2) + '':'' +("0" + hours).slice(-2) + '':'' + ("0" + minutes).slice(-2) + '':'' + ("0" + seconds).slice(-2)
                                               }
                                               '
 
 
--###################################################################################################
-- Html Zeitstrahl - Fussende
--###################################################################################################
INSERT   INTO ##ZeitstrahlGraph
         (HTML
         )
SELECT   '}
                </script>
                </head>
                <body>' + '<font face="Helvetica" size="3" ><b>' + @@servername
         + ' Auftr&auml;ge' + ' von ' + CONVERT(VARCHAR(20), @StartDatum, 120)
         + ' bis ' + CONVERT(VARCHAR(20), @EndeDatum, 120) +
         + CASE WHEN @FEHLERANZAHL = 0 THEN ''
            ELSE
                '. ' + @FEHLERVORHANDEN_TEXT
           END
         + CASE WHEN @MindestLaufzeitInSekunden = 0 THEN ''
                ELSE ' (Auftr&auml;ge länger '
                     + CAST(@MindestLaufzeitInSekunden AS VARCHAR(10))
                     + ' Sekunden)'
           END
         + '</b></font>
                               <p/>
'
 
INSERT   INTO ##ZeitstrahlGraph
         (HTML
         )
SELECT   '
                <div id="legende">
                               <ul>
                               Legende:
                                               <li>
                                                               <div class="legendeErfolg"></div>= Erfolgreich
                                               </li>
                                               <li>
                                                               <div class="legendeLaeuft"></div>= L&auml;uft aktuell
                                               </li>
                                               <li>
                                                               <div class="legendeFehler"></div>= Fehlerhaft
                                               </li>
                                               <li>
                                                               <div class="legendeNeuversuch"></div>= Neuversuch
                                               </li>
                                               <li>
                                                               <div class="legendeAbgebrochen"></div>= Abgebrochen
                                               </li>
                                               <li>
                                                               <div class="legendeServerneustart"></div>= Letzter Serverneustart
                                               '
                                              
INSERT   INTO ##ZeitstrahlGraph
         (HTML
         )
SELECT   '              ('
                                                   + CONVERT(char(20), @ServerNeustart,113)
                          + ')
                                                  '
                                              
INSERT   INTO ##ZeitstrahlGraph
         (HTML
         )
SELECT        
                                               '</li>
                                               <li>
                                                               <div class="legendeUndefiniert"></div>= Undefiniert
                                               </li>
                               </ul>
                </div>
'
 
 
--###################################################################################################
-- Zeitstrahl/Ende abschnitt
--###################################################################################################
DECLARE @Zeitstrahlbreite AS INTEGER
IF @Tage < 1
   SET @Zeitstrahlbreite = 1800
ELSE
   SET @Zeitstrahlbreite = @Tage * 1800
  
INSERT   INTO ##ZeitstrahlGraph
         (HTML
         )
SELECT   '
                               <div id="Zeitstrahl" style="width: ' + CAST(@Zeitstrahlbreite AS VARCHAR(10))
         + 'px; height: 950px;"></div>
                </body>
</html>'
 
 
--###################################################################################################
-- Ausgabe als Email
--###################################################################################################
DECLARE @emailBodyText NVARCHAR(MAX); 
SET @emailBodyText = 'Zeitstrahl der Aufträge von '
   + CONVERT(VARCHAR(20), @StartDatum, 120) + ' bis '
   + CONVERT(VARCHAR(20), @EndeDatum, 120) + ' siehe Anhang.'
DECLARE @emailSubjectText NVARCHAR(MAX); 
SET @emailSubjectText = @@servername + ' Aufträge von '
   + CONVERT(VARCHAR(20), @StartDatum, 120) + ' bis '
   + CONVERT(VARCHAR(20), @EndeDatum, 120)
   + ' ' + @FEHLERVORHANDEN_TEXT
DECLARE @emailHTMLDateinameText NVARCHAR(MAX); 
SET @emailHTMLDateinameText = @@servername + ' Aufträge von '
   + CONVERT(VARCHAR(20), @StartDatum, 120) + ' bis '
   + CONVERT(VARCHAR(20), @EndeDatum, 120) + '.html'
SET @emailHTMLDateinameText = REPLACE(@emailHTMLDateinameText, ':', '_')
 
DECLARE @emailWichtigkeit NVARCHAR(10); 
IF @FEHLERANZAHL > 0
   SET @emailWichtigkeit = 'High'
ELSE
   SET @emailWichtigkeit = 'Normal'
 
IF @EmailEmpfaenger <> ''
   EXECUTE msdb.dbo.sp_send_dbmail @recipients = @EmailEmpfaenger,
      @subject = @emailSubjectText, @body = @emailBodyText,
      @body_format = 'HTML' -- oder TEXT
      , @importance = @emailWichtigkeit
      , @sensitivity = 'Normal' --Normal Personal Private Confidential
      , @execute_query_database = 'master', @query_result_header = 0,       --@query_result_header = 0 ist wichtig, da sonst "HTML----" aus der Query in den html-Code gelangt
      @query = 'set nocount on; SELECT HTML FROM ##ZeitstrahlGraph ORDER BY ID',
      @query_result_no_padding = 1
      --,@query_no_truncate= 1
      , @attach_query_result_as_file = 1,
      @query_attachment_filename = @emailHTMLDateinameText
 
IF @FEHLERANZAHL > 0 AND @EmailNurBeiFehlerEmpfaenger <> ''
   EXECUTE msdb.dbo.sp_send_dbmail @recipients = @EmailNurBeiFehlerEmpfaenger,
      @subject = @emailSubjectText, @body = @emailBodyText,
      @body_format = 'HTML' -- oder TEXT
      , @importance = @emailWichtigkeit
      , @sensitivity = 'Normal' --Normal Personal Private Confidential
      , @execute_query_database = 'master', @query_result_header = 0,       --@query_result_header = 0 ist wichtig, da sonst "HTML----" aus der Query in den html-Code gelangt
      @query = 'set nocount on; SELECT HTML FROM ##ZeitstrahlGraph ORDER BY ID',
      @query_result_no_padding = 1
      --,@query_no_truncate= 1
      , @attach_query_result_as_file = 1,
      @query_attachment_filename = @emailHTMLDateinameText
 
 
GOTO Aufraeumen
 
--###################################################################################################
-- Nur für alle Fälle
--###################################################################################################
NichtsZuTun:
 
PRINT 'Keine Aufträge gefunden (Kann auch ein Fehler sein)'
 
--###################################################################################################
-- Aufräumen
--###################################################################################################
Aufraeumen:
IF OBJECT_ID('tempdb..#AuftragsLaufzeiten') IS NOT NULL
   DROP TABLE #AuftragsLaufzeiten;
IF OBJECT_ID('tempdb..##ZeitstrahlGraph') IS NOT NULL
   DROP TABLE ##ZeitstrahlGraph;

