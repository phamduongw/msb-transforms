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

-- ARR
BEGIN
    DBMS_SCHEDULER.create_job(
        job_name   => 'T24RAWOGG.T24_LNTNEW_ACTIVITY_GEN_FROM_ARR_JOB',
        job_type   => 'PLSQL_BLOCK',
        job_action => q'[
            BEGIN
                EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ''.,''';
                LOOP
                    T24RAWOGG.T24_LNTNEW_ACTIVITY_PKG.GEN_FROM_ARR_PROC;
                END LOOP;
            END;
        ]',
        start_date => SYSTIMESTAMP,
        enabled    => FALSE,
        auto_drop  => FALSE
    );

    DBMS_SCHEDULER.set_attribute(
        name      => 'T24RAWOGG.T24_LNTNEW_ACTIVITY_GEN_FROM_ARR_JOB',
        attribute => 'instance_id',
        value     => 1
    );
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
                    T24RAWOGG.T24_LNTNEW_ACTIVITY_PKG.GEN_FROM_AIT_PROC;
                END LOOP;
            END;
        ]',
        start_date => SYSTIMESTAMP,
        enabled    => FALSE,
        auto_drop  => FALSE
    );

    DBMS_SCHEDULER.set_attribute(
        name      => 'T24RAWOGG.T24_LNTNEW_ACTIVITY_GEN_FROM_AIT_JOB',
        attribute => 'instance_id',
        value     => 1
    );
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
                    T24RAWOGG.T24_LNTNEW_ACTIVITY_PKG.GEN_FROM_ASC_PROC;
                END LOOP;
            END;
        ]',
        start_date => SYSTIMESTAMP,
        enabled    => FALSE,
        auto_drop  => FALSE
    );

    DBMS_SCHEDULER.set_attribute(
        name      => 'T24RAWOGG.T24_LNTNEW_ACTIVITY_GEN_FROM_ASC_JOB',
        attribute => 'instance_id',
        value     => 1
    );
END;
