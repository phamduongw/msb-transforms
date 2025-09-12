-- DROP JOB
BEGIN DBMS_SCHEDULER.drop_job('T24RAWOGG_T24_LNTNEW_ACTIVITY_GEN_FROM_ACC_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.drop_job('T24RAWOGG_T24_LNTNEW_ACTIVITY_GEN_FROM_ARR_JOB', TRUE); END;

-- T24_LNTNEW_ACTIVITY_GEN_FROM_ACC_JOB
BEGIN
    DBMS_SCHEDULER.create_job(
            job_name => 'T24RAWOGG_T24_LNTNEW_ACTIVITY_GEN_FROM_ACC_JOB',
            job_type => 'PLSQL_BLOCK',
            job_action => q'[
            BEGIN
                EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ''.,''';
                LOOP
                    T24_LNTNEW_ACTIVITY_PKG.GEN_FROM_ACC_PROC;
                END LOOP;
            END;
        ]',
            start_date => SYSTIMESTAMP,
            enabled => FALSE,
            auto_drop => FALSE
    );
END;

-- T24_LNTNEW_ACTIVITY_GEN_FROM_ARR_JOB
BEGIN
    DBMS_SCHEDULER.create_job(
            job_name => 'T24RAWOGG_T24_LNTNEW_ACTIVITY_GEN_FROM_ARR_JOB',
            job_type => 'PLSQL_BLOCK',
            job_action => q'[
            BEGIN
                EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ''.,''';
                LOOP
                    T24_LNTNEW_ACTIVITY_PKG.GEN_FROM_ARR_PROC;
                END LOOP;
            END;
        ]',
            start_date => SYSTIMESTAMP,
            enabled => FALSE,
            auto_drop => FALSE
    );
END;


-- START JOB
BEGIN DBMS_SCHEDULER.run_job('T24RAWOGG_T24_LNTNEW_ACTIVITY_GEN_FROM_ACC_JOB', FALSE); END;
BEGIN DBMS_SCHEDULER.run_job('T24RAWOGG_T24_LNTNEW_ACTIVITY_GEN_FROM_ARR_JOB', FALSE); END;

-- STOP JOB
BEGIN DBMS_SCHEDULER.stop_job('T24RAWOGG_T24_LNTNEW_ACTIVITY_GEN_FROM_ACC_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.stop_job('T24RAWOGG_T24_LNTNEW_ACTIVITY_GEN_FROM_ARR_JOB', TRUE); END;