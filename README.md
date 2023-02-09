# SQLServerTools
This repo is the home of various SQL-Server-Tools for MS SQL-Server

- [MailJobTimeLine_DE.sql](../master/MailJobTimeLine_DE.sql) - This SQL (german, theres also a not actual english version [MailJobTimeLine.sql](../master/MailJobTimeLine.sql)) sends an email with all jobs displayed in a graphical timeline:
[Exampletimeline](https://thomas-s-b.github.io/Timline_Example.html)
![TimelinePicture](https://github.com/Thomas-S-B/SQLServerTools/blob/master/Images/Timeline_sql.jpg) 

- [GetExecutionPlans.sql](../master/GetExecutionPlans.sql) - Find executionplans
- [GetProcedureMetrics.sql](../master/GetProcedureMetrics.sql) - Get proceduremetrics
- [GetErrorLog.sql](../master/GetErrorLog.sql) - Get/Read errorlog
- [GetIndexFragmentation.sql](../master/GetIndexFragmentation.sql) - Get index fragmentaion
- [GetExecutionAndInvokecount.sql](../master/GetExecutionAndInvokecount.sql) - Get executionplans and count of invoke
- [FREEPROCCACHE.sql](../master/FREEPROCCACHE.sql) - Delete executionplan of specific object, see also [GetExecutionAndInvokecount.sql](../master/GetExecutionAndInvokecount.sql) to get the planhandle
- [GetConnections.sql](../master/GetConnections.sql) - Get current connections
- [FindTriggers.sql](../master/FindTriggers.sql) - Find triggers
- [Top10WorstProcedures.sql](../master/Top10WorstProcedures.sql) - The TOP 10 of the worst procedures
- [SelectFlatFiles.sql](../master/SelectFlatFiles.sql) - Run selects against flatfiles from a filesystem
- [ChangeOptionsInDatabases.sql](../master/ChangeOptionsInDatabases.sql) - Executes an SQL on all or selected Databases
- [CleanupHistories.sql](../master/CleanupHistories.sql) - Cleans up histories
- [OpenTransactions.sql](../master/OpenTransactions.sql) - Shows all current transactions
- [ShowFragmentation.sql](../master/ShowFragmentation.sql) - Shows fragmentation, customize where-clause
- [GetSynonyms.sql](../master/GetSynonyms.sql) - Get all synonyms of all databases
- [DeleteExecutionPlan.sql](../master/DeleteExecutionPlan.sql) - Delete specific executionplans
- [GetStatisticSamples.sql](../master/GetStatisticSamples.sql) - Get all statistics with a sample size < 100%
- [HallengrenHeaviestMail.sql](../master/HallengrenHeaviestMail.sql) - Sends an mail with the heaviest statisticsupdates of an hallengren maintenance
- [MailFragmentation.sql](../master/MailFragmentation.sql) - Sends an mail with all indexes > 100 pages and >= 5% fragmentation
- [GetOldStatistics.sql](../master/GetOldStatistics.sql) - Get old statistics
- [TriggerDependencies.sql](../master/TriggerDependencies.sql) - Find dependencies to other tables in triggers
- [AnalyzeTraceFileFromSQLProfiler.sql](../master/AnalyzeTraceFileFromSQLProfiler.sql) - Query and analyze a tracefile from SQL Profiler
