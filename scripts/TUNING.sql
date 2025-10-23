PURGE RECYCLEBIN;

ALTER INDEX T24RAWOGG.IDX_FMSB_BIL_LNMEMO_ARRANGEMENT_ID REBUILD ONLINE NOLOGGING;

BEGIN DBMS_STATS.GATHER_TABLE_STATS(
      ownname          => 'T24RAWOGG',
      tabname          => 'FMSB_ACC_MAPPED',
      estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE,
      method_opt       => 'FOR ALL COLUMNS SIZE SKEWONLY',
      degree           => 64,
      cascade          => TRUE,
      no_invalidate    => FALSE
   );
END;

BEGIN DBMS_STATS.GATHER_SCHEMA_STATS(
      ownname          => 'T24RAWOGG',
      estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE,
      method_opt       => 'FOR ALL COLUMNS SIZE SKEWONLY',
      degree           => 16,
      cascade          => TRUE,
      no_invalidate    => FALSE
   );
END;

SELECT LIMIT_KEY, COUNT(*) AS CNT
FROM V_FMSB_ACC_MAPPED
GROUP BY LIMIT_KEY
HAVING COUNT(*) > 1
ORDER BY CNT DESC;

ALTER PACKAGE T24RAWOGG.T24_LNMEMO_ACTIVITY_PKG COMPILE;
