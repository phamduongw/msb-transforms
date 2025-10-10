-- T24_TMTRAN_GEN_FROM_STM_JOB
BEGIN
    DBMS_SCHEDULER.create_job(
            job_name => 'T24_TMTRAN_GEN_FROM_STM_JOB',
            job_type => 'PLSQL_BLOCK',
            job_action => q'[
            BEGIN
                EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ''.,''';
                LOOP
                    T24_TMTRAN_PKG.GEN_FROM_STM_PROC;
                END LOOP;
            END;
        ]',
            start_date => SYSTIMESTAMP,
            enabled => FALSE,
            auto_drop => FALSE
    );
END;
