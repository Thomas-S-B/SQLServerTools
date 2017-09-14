SELECT   COUNT(dbid) AS NumberOfConnections
        ,loginame AS LoginName
FROM     sys.sysprocesses
WHERE    dbid > 0
GROUP BY loginame
ORDER BY NumberOfConnections DESC, LoginName
