PURGE RECYCLEBIN;

BEGIN
   DBMS_STATS.GATHER_SCHEMA_STATS(
      ownname          => 'T24RAWOGG',
      estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE,
      method_opt       => 'FOR ALL COLUMNS SIZE AUTO',
      cascade          => TRUE,
      degree           => DBMS_STATS.DEFAULT_DEGREE
   );
END;
