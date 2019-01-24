   SELECT 'SELECT setval(''' || c.relname || ''', 1, false);'
     FROM PG_CLASS  AS c
LEFT JOIN PG_USER   AS u ON c.relowner = u.usesysid
    WHERE c.relkind = 'S'
 ORDER BY c.relname
;