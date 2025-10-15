-- ACC
BEGIN
    DBMS_SCHEDULER.create_job(
        job_name   => 'T24RAWOGG.T24_DDTNEW_ACTIVITY_GEN_FROM_ACC_ARR_ECB_JOB',
        job_type   => 'PLSQL_BLOCK',
        job_action => q'[
            BEGIN
                EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ''.,''';
                LOOP
                    T24RAWOGG.T24_DDTNEW_ACTIVITY_PKG.GEN_FROM_ACC_ARR_ECB_PROC;
                END LOOP;
            END;
        ]',
        start_date => SYSTIMESTAMP,
        enabled    => FALSE,
        auto_drop  => FALSE
    );

    DBMS_SCHEDULER.set_attribute(
        name      => 'T24RAWOGG.T24_DDTNEW_ACTIVITY_GEN_FROM_ACC_ARR_ECB_JOB',
        attribute => 'instance_id',
        value     => 1
    );
END;



-- DROP
BEGIN DBMS_SCHEDULER.drop_job('T24RAWOGG.T24_DDTNEW_ACTIVITY_GEN_FROM_ACC_ARR_ECB_JOB', TRUE); END;

-- STOP
BEGIN DBMS_SCHEDULER.stop_job('T24RAWOGG.T24_DDTNEW_ACTIVITY_GEN_FROM_ACC_ARR_ECB_JOB', FALSE); END;

-- RUN
BEGIN DBMS_SCHEDULER.run_job('T24RAWOGG.T24_DDTNEW_ACTIVITY_GEN_FROM_ACC_ARR_ECB_JOB', FALSE); END;
