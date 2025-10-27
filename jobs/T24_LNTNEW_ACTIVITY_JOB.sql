-- ACC
BEGIN
    DBMS_SCHEDULER.create_job(
        job_name   => 'T24RAWOGG.T24_LNTNEW_ACTIVITY_GEN_FROM_ACC_JOB',
        job_type   => 'PLSQL_BLOCK',
        job_action => q'[ 
            BEGIN
                EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ''.,''';
                LOOP
                    T24RAWOGG.T24_LNTNEW_ACTIVITY_PKG.GEN_FROM_ACC_PROC;
                END LOOP;
            END;
        ]',
        start_date => SYSTIMESTAMP,
        enabled    => FALSE,
        auto_drop  => FALSE
    );

    DBMS_SCHEDULER.set_attribute(
        name      => 'T24RAWOGG.T24_LNTNEW_ACTIVITY_GEN_FROM_ACC_JOB',
        attribute => 'instance_id',
        value     => 1
    );
END;

-- ARR, AIT, ASC, AAC, ATA
BEGIN
    DBMS_SCHEDULER.create_job(
        job_name   => 'T24RAWOGG.T24_LNTNEW_ACTIVITY_GEN_FROM_ARR_AIT_ASC_AAC_ATA_JOB',
        job_type   => 'PLSQL_BLOCK',
        job_action => q'[
            BEGIN
                EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ''.,''';
                LOOP
                    T24RAWOGG.T24_LNTNEW_ACTIVITY_PKG.GEN_FROM_ARR_AIT_ASC_AAC_ATA_PROC;
                END LOOP;
            END;
        ]',
        start_date => SYSTIMESTAMP,
        enabled    => FALSE,
        auto_drop  => FALSE
    );

    DBMS_SCHEDULER.set_attribute(
        name      => 'T24RAWOGG.T24_LNTNEW_ACTIVITY_GEN_FROM_ARR_AIT_ASC_AAC_ATA_JOB',
        attribute => 'instance_id',
        value     => 1
    );
END;


-- T24_LNTNEW_ACTIVITY_JOB
BEGIN DBMS_SCHEDULER.drop_job('T24RAWOGG.T24_LNTNEW_ACTIVITY_GEN_FROM_ACC_JOB', FALSE); END;
BEGIN DBMS_SCHEDULER.drop_job('T24RAWOGG.T24_LNTNEW_ACTIVITY_GEN_FROM_ARR_AIT_ASC_AAC_ATA_JOB', FALSE); END;

BEGIN DBMS_SCHEDULER.stop_job('T24RAWOGG.T24_LNTNEW_ACTIVITY_GEN_FROM_ACC_JOB', FALSE); END;
BEGIN DBMS_SCHEDULER.stop_job('T24RAWOGG.T24_LNTNEW_ACTIVITY_GEN_FROM_ARR_AIT_ASC_AAC_ATA_JOB', FALSE); END;

BEGIN DBMS_SCHEDULER.run_job('T24RAWOGG.T24_LNTNEW_ACTIVITY_GEN_FROM_ACC_JOB', FALSE); END;
BEGIN DBMS_SCHEDULER.run_job('T24RAWOGG.T24_LNTNEW_ACTIVITY_GEN_FROM_ARR_AIT_ASC_AAC_ATA_JOB', FALSE); END;
