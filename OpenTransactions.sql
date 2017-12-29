SELECT TRANS.session_id AS [SESSION ID],
       ES.host_name AS [HOST NAME],
       ES.login_name AS [Login NAME],
       TRANS.transaction_id AS [TRANSACTION ID],
       TAS.name AS [TRANSACTION NAME],
       TAS.transaction_begin_time AS [TRANSACTION BEGIN TIME],
       TDS.database_id AS [DATABASE ID],
       DBS.name AS [DATABASE NAME],
       ES.program_name,

       --https://docs.microsoft.com/de-de/sql/relational-databases/system-dynamic-management-views/sys-dm-tran-active-transactions-transact-sql
       CASE
           WHEN TAS.transaction_state = 0 THEN
               'Die Transaktion wurde noch nicht vollständig initialisiert.'
           WHEN TAS.transaction_state = 1 THEN
               'Die Transaktion wurde initialisiert, aber noch nicht gestartet.'
           WHEN TAS.transaction_state = 2 THEN
               'Die Transaktion ist aktiv.'
           WHEN TAS.transaction_state = 3 THEN
               'Die Transaktion wurde beendet. Diese Einstellung wird für schreibgeschützte Transaktionen verwendet.'
           WHEN TAS.transaction_state = 4 THEN
               'Der Commitprozess wurde für die verteilte Transaktion initiiert. Diese Einstellung wird nur für verteilte Transaktionen verwendet. Die verteilte Transaktion ist noch aktiv, doch ist keine weitere Verarbeitung möglich.'
           WHEN TAS.transaction_state = 5 THEN
               'Die Transaktion hat den Status "Vorbereitet" und wartet auf Auflösung.'
           WHEN TAS.transaction_state = 6 THEN
               'Die Transaktion ein Commit ausgeführt wurde.'
           WHEN TAS.transaction_state = 7 THEN
               'Es wird ein Rollback für die Transaktion durchgeführt.'
           WHEN TAS.transaction_state = 8 THEN
               'Die Transaktion wurde ein Rollback.'
           ELSE
               'UNBEKANNT'
       END AS TRANSAKTIONS_STATUS,
       
	   CASE
           WHEN TAS.transaction_type = 1 THEN
               'Lese-/Schreibtransaktion'
           WHEN TAS.transaction_type = 2 THEN
               'Schreibgeschützte Transaktion'
           WHEN TAS.transaction_type = 3 THEN
               'Systemtransaktion'
           WHEN TAS.transaction_type = 4 THEN
               'Verteilte Transaktion'
           ELSE
               'UNBEKANNT'
       END AS TRANSAKTIONS_TYP,

	   DATEDIFF(millisecond, TAS.transaction_begin_time, GETDATE()) AS DAUER_IN_MS
	   ,ES.session_id
       --,*
FROM sys.dm_tran_active_transactions AS TAS
    INNER JOIN sys.dm_tran_session_transactions AS TRANS
        ON (TRANS.transaction_id = TAS.transaction_id)
    LEFT JOIN sys.dm_tran_database_transactions AS TDS
        ON (TAS.transaction_id = TDS.transaction_id)
    LEFT JOIN sys.databases AS DBS
        ON TDS.database_id = DBS.database_id
    LEFT JOIN sys.dm_exec_sessions AS ES
        ON TRANS.session_id = ES.session_id
WHERE ES.session_id IS NOT NULL

--ORDER BY [DATABASE NAME], ES.program_name
ORDER BY DAUER_IN_MS DESC
