SELECT SS.stats_id,
       OBJECT_NAME(SS.object_id) AS 'Table',
       AC.name AS 'Spalte',
       SS.name,
       SS.filter_definition,
       SHR.last_updated,
       SHR.rows,
       SHR.rows_sampled,
       SHR.steps,
       SHR.unfiltered_rows,
       SHR.modification_counter,
       (SHR.rows_sampled * 100) / SHR.rows AS Stichprobe_Prozent
FROM sys.stats AS SS
    INNER JOIN sys.stats_columns AS SC ON SS.stats_id = SC.stats_id AND SS.object_id = SC.object_id
    INNER JOIN sys.all_columns AS AC ON AC.column_id = SC.column_id AND AC.object_id = SC.object_id
    CROSS APPLY sys.dm_db_stats_properties(SS.object_id, SS.stats_id) AS SHR
WHERE (SHR.rows_sampled * 100) / SHR.rows < 100
