BEGIN
    DBMS_SCHEDULER.create_job(
        job_name         => 'T24RAWOGG.DAILY_PURGE_ORPHANED_DATA_JOB',
        job_type         => 'PLSQL_BLOCK',
        job_action       => q'[
            BEGIN
                DELETE FROM T24_LNMEMO_ACTIVITY_ACC_ARR_ECB
                WHERE CAPTURED_TIME < TRUNC(SYSTIMESTAMP);
                
                DELETE FROM T24_LNMEMO_ACTIVITY_BIL
                WHERE CAPTURED_TIME < TRUNC(SYSTIMESTAMP);

                DELETE FROM T24_LNMEMO_ACTIVITY_LMT
                WHERE CAPTURED_TIME < TRUNC(SYSTIMESTAMP);

                COMMIT;
            END;
        ]',
        start_date       => SYSTIMESTAMP,
        repeat_interval  => 'FREQ=DAILY;BYHOUR=5;BYMINUTE=0;BYSECOND=0',
        enabled          => FALSE,
        auto_drop        => FALSE
    );
END;
