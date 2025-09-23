-- ACC
BEGIN
    DBMS_SCHEDULER.create_job(
        job_name   => 'T24RAWOGG.T24_LNTNEW_ACTIVITY_GEN_FROM_ACC_JOB',
        job_type   => 'PLSQL_BLOCK',
        job_action => q'[ 
            BEGIN
                EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ''.,''';
                LOOP
                    T24_LNTNEW_ACTIVITY_PKG.GEN_FROM_ACC_PROC;
                END LOOP;
            END;
        ]',
        start_date => SYSTIMESTAMP,
        enabled    => FALSE,
        auto_drop  => FALSE
    );

    -- DBMS_SCHEDULER.set_attribute(
    --     name      => 'T24RAWOGG.T24_LNTNEW_ACTIVITY_GEN_FROM_ACC_JOB',
    --     attribute => 'instance_id',
    --     value     => 1
    -- );
END;

-- ARR
BEGIN
    DBMS_SCHEDULER.create_job(
        job_name   => 'T24RAWOGG.T24_LNTNEW_ACTIVITY_GEN_FROM_ARR_JOB',
        job_type   => 'PLSQL_BLOCK',
        job_action => q'[
            BEGIN
                EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ''.,''';
                LOOP
                    T24_LNTNEW_ACTIVITY_PKG.GEN_FROM_ARR_PROC;
                END LOOP;
            END;
        ]',
        start_date => SYSTIMESTAMP,
        enabled    => FALSE,
        auto_drop  => FALSE
    );

    -- DBMS_SCHEDULER.set_attribute(
    --     name      => 'T24RAWOGG.T24_LNTNEW_ACTIVITY_GEN_FROM_ARR_JOB',
    --     attribute => 'instance_id',
    --     value     => 1
    -- );
END;

-- AIT
BEGIN
    DBMS_SCHEDULER.create_job(
        job_name   => 'T24RAWOGG.T24_LNTNEW_ACTIVITY_GEN_FROM_AIT_JOB',
        job_type   => 'PLSQL_BLOCK',
        job_action => q'[
            BEGIN
                EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ''.,''';
                LOOP
                    T24_LNTNEW_ACTIVITY_PKG.GEN_FROM_AIT_PROC;
                END LOOP;
            END;
        ]',
        start_date => SYSTIMESTAMP,
        enabled    => FALSE,
        auto_drop  => FALSE
    );

    -- DBMS_SCHEDULER.set_attribute(
    --     name      => 'T24RAWOGG.T24_LNTNEW_ACTIVITY_GEN_FROM_AIT_JOB',
    --     attribute => 'instance_id',
    --     value     => 1
    -- );
END;

-- ASC
BEGIN
    DBMS_SCHEDULER.create_job(
        job_name   => 'T24RAWOGG.T24_LNTNEW_ACTIVITY_GEN_FROM_ASC_JOB',
        job_type   => 'PLSQL_BLOCK',
        job_action => q'[
            BEGIN
                EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ''.,''';
                LOOP
                    T24_LNTNEW_ACTIVITY_PKG.GEN_FROM_ASC_PROC;
                END LOOP;
            END;
        ]',
        start_date => SYSTIMESTAMP,
        enabled    => FALSE,
        auto_drop  => FALSE
    );

    -- DBMS_SCHEDULER.set_attribute(
    --     name      => 'T24RAWOGG.T24_LNTNEW_ACTIVITY_GEN_FROM_ASC_JOB',
    --     attribute => 'instance_id',
    --     value     => 1
    -- );
END;

-- AIT
BEGIN
    DBMS_SCHEDULER.create_job(
        job_name   => 'T24RAW.T24_LNTNEW_ACTIVITY_GEN_FROM_AIT_JOB',
        job_type   => 'PLSQL_BLOCK',
        job_action => q'[
            BEGIN
                EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ''.,''';
                LOOP
                    T24_LNTNEW_ACTIVITY_PKG.GEN_FROM_AIT_PROC;
                END LOOP;
            END;
        ]',
        start_date => SYSTIMESTAMP,
        enabled    => FALSE,
        auto_drop  => FALSE
    );
END;

-- ASC
BEGIN
    DBMS_SCHEDULER.create_job(
        job_name   => 'T24RAW.T24_LNTNEW_ACTIVITY_GEN_FROM_ASC_JOB',
        job_type   => 'PLSQL_BLOCK',
        job_action => q'[
            BEGIN
                EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ''.,''';
                LOOP
                    T24_LNTNEW_ACTIVITY_PKG.GEN_FROM_ASC_PROC;
                END LOOP;
            END;
        ]',
        start_date => SYSTIMESTAMP,
        enabled    => FALSE,
        auto_drop  => FALSE
    );
END;

-- DROP
BEGIN DBMS_SCHEDULER.drop_job('T24RAWOGG.T24_LNTNEW_ACTIVITY_GEN_FROM_ACC_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.drop_job('T24RAWOGG.T24_LNTNEW_ACTIVITY_GEN_FROM_ARR_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.drop_job('T24RAWOGG.T24_LNTNEW_ACTIVITY_GEN_FROM_AIT_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.drop_job('T24RAWOGG.T24_LNTNEW_ACTIVITY_GEN_FROM_ASC_JOB', TRUE); END;

-- STOP
BEGIN DBMS_SCHEDULER.stop_job('T24RAWOGG.T24_LNTNEW_ACTIVITY_GEN_FROM_ACC_JOB', FALSE); END;
BEGIN DBMS_SCHEDULER.stop_job('T24RAWOGG.T24_LNTNEW_ACTIVITY_GEN_FROM_ARR_JOB', FALSE); END;
BEGIN DBMS_SCHEDULER.stop_job('T24RAWOGG.T24_LNTNEW_ACTIVITY_GEN_FROM_AIT_JOB', FALSE); END;
BEGIN DBMS_SCHEDULER.stop_job('T24RAWOGG.T24_LNTNEW_ACTIVITY_GEN_FROM_ASC_JOB', FALSE); END;

-- RUN
BEGIN DBMS_SCHEDULER.run_job('T24RAWOGG.T24_LNTNEW_ACTIVITY_GEN_FROM_ACC_JOB', FALSE); END;
BEGIN DBMS_SCHEDULER.run_job('T24RAWOGG.T24_LNTNEW_ACTIVITY_GEN_FROM_ARR_JOB', FALSE); END;
BEGIN DBMS_SCHEDULER.run_job('T24RAWOGG.T24_LNTNEW_ACTIVITY_GEN_FROM_AIT_JOB', FALSE); END;
BEGIN DBMS_SCHEDULER.run_job('T24RAWOGG.T24_LNTNEW_ACTIVITY_GEN_FROM_ASC_JOB', FALSE); END;


-- STATUS
SELECT JOB_NAME, STATE, LAST_START_DATE, RUN_COUNT, FAILURE_COUNT
FROM DBA_SCHEDULER_JOBS
WHERE OWNER = 'T24RAWOGG' AND JOB_NAME LIKE '%LNTNEW%';

-- ERROR
SELECT JOB_NAME, STATUS, ACTUAL_START_DATE, RUN_DURATION, ADDITIONAL_INFO
FROM DBA_SCHEDULER_JOB_RUN_DETAILS
WHERE OWNER = 'T24RAWOGG' AND JOB_NAME LIKE '%LNTNEW%' AND STATUS = 'FAILED'
AND ACTUAL_START_DATE > TO_TIMESTAMP('2025-09-12 00:00:00.000', 'YYYY-MM-DD HH24:MI:SS.FF3')
ORDER BY ACTUAL_START_DATE DESC;
