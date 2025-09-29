



CREATE OR REPLACE PACKAGE T24_TMTRAN_PKG IS



    PROCEDURE GEN_FROM_STM_PROC;

    PROCEDURE GEN_FROM_FT_PROC;

    PROCEDURE GEN_FROM_ACC_PROC;

    PROCEDURE GEN_FROM_POR_PROC;

    PROCEDURE GEN_FROM_FX_PROC;

    PROCEDURE GEN_FROM_TR_PROC;




END T24_TMTRAN_PKG;



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

-- T24_TMTRAN_GEN_FROM_FT_JOB
BEGIN
    DBMS_SCHEDULER.create_job(
            job_name => 'T24_TMTRAN_GEN_FROM_FT_JOB',
            job_type => 'PLSQL_BLOCK',
            job_action => q'[
            BEGIN
                EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ''.,''';
                LOOP
                    T24_TMTRAN_PKG.GEN_FROM_FT_PROC;
                END LOOP;
            END;
        ]',
            start_date => SYSTIMESTAMP,
            enabled => FALSE,
            auto_drop => FALSE
    );
END;

-- T24_TMTRAN_GEN_FROM_AC_JOB
BEGIN
    DBMS_SCHEDULER.create_job(
            job_name => 'T24_TMTRAN_GEN_FROM_AC_JOB',
            job_type => 'PLSQL_BLOCK',
            job_action => q'[
            BEGIN
                EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ''.,''';
                LOOP
                    T24_TMTRAN_PKG.GEN_FROM_AC_PROC;
                END LOOP;
            END;
        ]',
            start_date => SYSTIMESTAMP,
            enabled => FALSE,
            auto_drop => FALSE
    );
END;


-- T24_TMTRAN_GEN_FROM_POR_JOB
BEGIN
    DBMS_SCHEDULER.create_job(
            job_name => 'T24_TMTRAN_GEN_FROM_POR_JOB',
            job_type => 'PLSQL_BLOCK',
            job_action => q'[
            BEGIN
                EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ''.,''';
                LOOP
                    T24_TMTRAN_PKG.GEN_FROM_POR_PROC;
                END LOOP;
            END;
        ]',
            start_date => SYSTIMESTAMP,
            enabled => FALSE,
            auto_drop => FALSE
    );
END;


-- T24_TMTRAN_GEN_FROM_FX_JOB
BEGIN
    DBMS_SCHEDULER.create_job(
            job_name => 'T24_TMTRAN_GEN_FROM_FX_JOB',
            job_type => 'PLSQL_BLOCK',
            job_action => q'[
            BEGIN
                EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ''.,''';
                LOOP
                    T24_TMTRAN_PKG.GEN_FROM_FX_PROC;
                END LOOP;
            END;
        ]',
            start_date => SYSTIMESTAMP,
            enabled => FALSE,
            auto_drop => FALSE
    );
END;


-- T24_TMTRAN_GEN_FROM_TR_JOB
BEGIN
    DBMS_SCHEDULER.create_job(
            job_name => 'T24_TMTRAN_GEN_FROM_TR_JOB',
            job_type => 'PLSQL_BLOCK',
            job_action => q'[
            BEGIN
                EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ''.,''';
                LOOP
                    T24_TMTRAN_PKG.GEN_FROM_TR_PROC;
                END LOOP;
            END;
        ]',
            start_date => SYSTIMESTAMP,
            enabled => FALSE,
            auto_drop => FALSE
    );
END;