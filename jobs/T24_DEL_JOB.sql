-- FMSB_ARR_LNMEMO
BEGIN
    DBMS_SCHEDULER.create_job(
        job_name   => 'T24RAW.FMSB_ARR_LNMEMO_DEL_JOB',
        job_type   => 'PLSQL_BLOCK',
        job_action => q'[
            BEGIN
                LOOP
                    DELETE FROM FMSB_ARR_LNMEMO WHERE OP_TYPE = 'D';
                    COMMIT;
                END LOOP;
            END;
        ]',
        start_date => SYSTIMESTAMP,
        enabled    => FALSE,
        auto_drop  => FALSE
    );
END;

-- FMSB_BIL_LNMEMO
BEGIN
    DBMS_SCHEDULER.create_job(
        job_name   => 'T24RAW.FMSB_BIL_LNMEMO_DEL_JOB',
        job_type   => 'PLSQL_BLOCK',
        job_action => q'[
            BEGIN
                LOOP
                    DELETE FROM FMSB_BIL_LNMEMO WHERE OP_TYPE = 'D';
                    COMMIT;
                END LOOP;
            END;
        ]',
        start_date => SYSTIMESTAMP,
        enabled    => FALSE,
        auto_drop  => FALSE
    );
END;

-- FMSB_AIT_LNTNEW
BEGIN
    DBMS_SCHEDULER.create_job(
        job_name   => 'T24RAW.FMSB_AIT_LNTNEW_DEL_JOB',
        job_type   => 'PLSQL_BLOCK',
        job_action => q'[
            BEGIN
                LOOP
                    DELETE FROM FMSB_AIT_LNTNEW WHERE OP_TYPE = 'D';
                    COMMIT;
                END LOOP;
            END;
        ]',
        start_date => SYSTIMESTAMP,
        enabled    => FALSE,
        auto_drop  => FALSE
    );
END;

-- FMSB_ARC_LNTNEW
BEGIN
    DBMS_SCHEDULER.create_job(
        job_name   => 'T24RAW.FMSB_ARC_LNTNEW_DEL_JOB',
        job_type   => 'PLSQL_BLOCK',
        job_action => q'[
            BEGIN
                LOOP
                    DELETE FROM FMSB_ARC_LNTNEW WHERE OP_TYPE = 'D';
                    COMMIT;
                END LOOP;
            END;
        ]',
        start_date => SYSTIMESTAMP,
        enabled    => FALSE,
        auto_drop  => FALSE
    );
END;

-- FMSB_ARR_LNTNEW
BEGIN
    DBMS_SCHEDULER.create_job(
        job_name   => 'T24RAW.FMSB_ARR_LNTNEW_DEL_JOB',
        job_type   => 'PLSQL_BLOCK',
        job_action => q'[
            BEGIN
                LOOP
                    DELETE FROM FMSB_ARR_LNTNEW WHERE OP_TYPE = 'D';
                    COMMIT;
                END LOOP;
            END;
        ]',
        start_date => SYSTIMESTAMP,
        enabled    => FALSE,
        auto_drop  => FALSE
    );
END;

-- F_DAT_MAPPED
BEGIN
    DBMS_SCHEDULER.create_job(
        job_name   => 'T24RAW.F_DAT_MAPPED_DEL_JOB',
        job_type   => 'PLSQL_BLOCK',
        job_action => q'[
            BEGIN
                LOOP
                    DELETE FROM F_DAT_MAPPED WHERE OP_TYPE = 'D';
                    COMMIT;
                END LOOP;
            END;
        ]',
        start_date => SYSTIMESTAMP,
        enabled    => FALSE,
        auto_drop  => FALSE
    );
END;

-- F_POR_MAPPED
BEGIN
    DBMS_SCHEDULER.create_job(
        job_name   => 'T24RAW.F_POR_MAPPED_DEL_JOB',
        job_type   => 'PLSQL_BLOCK',
        job_action => q'[
            BEGIN
                LOOP
                    DELETE FROM F_POR_MAPPED WHERE OP_TYPE = 'D';
                    COMMIT;
                END LOOP;
            END;
        ]',
        start_date => SYSTIMESTAMP,
        enabled    => FALSE,
        auto_drop  => FALSE
    );
END;

-- F_PST_MAPPED
BEGIN
    DBMS_SCHEDULER.create_job(
        job_name   => 'T24RAW.F_PST_MAPPED_DEL_JOB',
        job_type   => 'PLSQL_BLOCK',
        job_action => q'[
            BEGIN
                LOOP
                    DELETE FROM F_PST_MAPPED WHERE OP_TYPE = 'D';
                    COMMIT;
                END LOOP;
            END;
        ]',
        start_date => SYSTIMESTAMP,
        enabled    => FALSE,
        auto_drop  => FALSE
    );
END;

-- F_SUP_MAPPED
BEGIN
    DBMS_SCHEDULER.create_job(
        job_name   => 'T24RAW.F_SUP_MAPPED_DEL_JOB',
        job_type   => 'PLSQL_BLOCK',
        job_action => q'[
            BEGIN
                LOOP
                    DELETE FROM F_SUP_MAPPED WHERE OP_TYPE = 'D';
                    COMMIT;
                END LOOP;
            END;
        ]',
        start_date => SYSTIMESTAMP,
        enabled    => FALSE,
        auto_drop  => FALSE
    );
END;

-- F_TMV_MAPPED
BEGIN
    DBMS_SCHEDULER.create_job(
        job_name   => 'T24RAW.F_TMV_MAPPED_DEL_JOB',
        job_type   => 'PLSQL_BLOCK',
        job_action => q'[
            BEGIN
                LOOP
                    DELETE FROM F_TMV_MAPPED WHERE OP_TYPE = 'D';
                    COMMIT;
                END LOOP;
            END;
        ]',
        start_date => SYSTIMESTAMP,
        enabled    => FALSE,
        auto_drop  => FALSE
    );
END;

-- FMSB_AAC_MAPPED
BEGIN
    DBMS_SCHEDULER.create_job(
        job_name   => 'T24RAW.FMSB_AAC_MAPPED_DEL_JOB',
        job_type   => 'PLSQL_BLOCK',
        job_action => q'[
            BEGIN
                LOOP
                    DELETE FROM FMSB_AAC_MAPPED WHERE OP_TYPE = 'D';
                    COMMIT;
                END LOOP;
            END;
        ]',
        start_date => SYSTIMESTAMP,
        enabled    => FALSE,
        auto_drop  => FALSE
    );
END;

-- FMSB_AC_MAPPED
BEGIN
    DBMS_SCHEDULER.create_job(
        job_name   => 'T24RAW.FMSB_AC_MAPPED_DEL_JOB',
        job_type   => 'PLSQL_BLOCK',
        job_action => q'[
            BEGIN
                LOOP
                    DELETE FROM FMSB_AC_MAPPED WHERE OP_TYPE = 'D';
                    COMMIT;
                END LOOP;
            END;
        ]',
        start_date => SYSTIMESTAMP,
        enabled    => FALSE,
        auto_drop  => FALSE
    );
END;

-- FMSB_ACC_MAPPED
BEGIN
    DBMS_SCHEDULER.create_job(
        job_name   => 'T24RAW.FMSB_ACC_MAPPED_DEL_JOB',
        job_type   => 'PLSQL_BLOCK',
        job_action => q'[
            BEGIN
                LOOP
                    DELETE FROM FMSB_ACC_MAPPED WHERE OP_TYPE = 'D';
                    COMMIT;
                END LOOP;
            END;
        ]',
        start_date => SYSTIMESTAMP,
        enabled    => FALSE,
        auto_drop  => FALSE
    );
END;

-- FMSB_ADL_MAPPED
BEGIN
    DBMS_SCHEDULER.create_job(
        job_name   => 'T24RAW.FMSB_ADL_MAPPED_DEL_JOB',
        job_type   => 'PLSQL_BLOCK',
        job_action => q'[
            BEGIN
                LOOP
                    DELETE FROM FMSB_ADL_MAPPED WHERE OP_TYPE = 'D';
                    COMMIT;
                END LOOP;
            END;
        ]',
        start_date => SYSTIMESTAMP,
        enabled    => FALSE,
        auto_drop  => FALSE
    );
END;

-- FMSB_AIT_MAPPED
BEGIN
    DBMS_SCHEDULER.create_job(
        job_name   => 'T24RAW.FMSB_AIT_MAPPED_DEL_JOB',
        job_type   => 'PLSQL_BLOCK',
        job_action => q'[
            BEGIN
                LOOP
                    DELETE FROM FMSB_AIT_MAPPED WHERE OP_TYPE = 'D';
                    COMMIT;
                END LOOP;
            END;
        ]',
        start_date => SYSTIMESTAMP,
        enabled    => FALSE,
        auto_drop  => FALSE
    );
END;

-- FMSB_ARC_MAPPED
BEGIN
    DBMS_SCHEDULER.create_job(
        job_name   => 'T24RAW.FMSB_ARC_MAPPED_DEL_JOB',
        job_type   => 'PLSQL_BLOCK',
        job_action => q'[
            BEGIN
                LOOP
                    DELETE FROM FMSB_ARC_MAPPED WHERE OP_TYPE = 'D';
                    COMMIT;
                END LOOP;
            END;
        ]',
        start_date => SYSTIMESTAMP,
        enabled    => FALSE,
        auto_drop  => FALSE
    );
END;

-- FMSB_ARR_MAPPED
BEGIN
    DBMS_SCHEDULER.create_job(
        job_name   => 'T24RAW.FMSB_ARR_MAPPED_DEL_JOB',
        job_type   => 'PLSQL_BLOCK',
        job_action => q'[
            BEGIN
                LOOP
                    DELETE FROM FMSB_ARR_MAPPED WHERE OP_TYPE = 'D';
                    COMMIT;
                END LOOP;
            END;
        ]',
        start_date => SYSTIMESTAMP,
        enabled    => FALSE,
        auto_drop  => FALSE
    );
END;

-- FMSB_ASC_MAPPED
BEGIN
    DBMS_SCHEDULER.create_job(
        job_name   => 'T24RAW.FMSB_ASC_MAPPED_DEL_JOB',
        job_type   => 'PLSQL_BLOCK',
        job_action => q'[
            BEGIN
                LOOP
                    DELETE FROM FMSB_ASC_MAPPED WHERE OP_TYPE = 'D';
                    COMMIT;
                END LOOP;
            END;
        ]',
        start_date => SYSTIMESTAMP,
        enabled    => FALSE,
        auto_drop  => FALSE
    );
END;

-- FMSB_ATA_MAPPED
BEGIN
    DBMS_SCHEDULER.create_job(
        job_name   => 'T24RAW.FMSB_ATA_MAPPED_DEL_JOB',
        job_type   => 'PLSQL_BLOCK',
        job_action => q'[
            BEGIN
                LOOP
                    DELETE FROM FMSB_ATA_MAPPED WHERE OP_TYPE = 'D';
                    COMMIT;
                END LOOP;
            END;
        ]',
        start_date => SYSTIMESTAMP,
        enabled    => FALSE,
        auto_drop  => FALSE
    );
END;

-- FMSB_BIL_MAPPED
BEGIN
    DBMS_SCHEDULER.create_job(
        job_name   => 'T24RAW.FMSB_BIL_MAPPED_DEL_JOB',
        job_type   => 'PLSQL_BLOCK',
        job_action => q'[
            BEGIN
                LOOP
                    DELETE FROM FMSB_BIL_MAPPED WHERE OP_TYPE = 'D';
                    COMMIT;
                END LOOP;
            END;
        ]',
        start_date => SYSTIMESTAMP,
        enabled    => FALSE,
        auto_drop  => FALSE
    );
END;

-- FMSB_BIT_MAPPED
BEGIN
    DBMS_SCHEDULER.create_job(
        job_name   => 'T24RAW.FMSB_BIT_MAPPED_DEL_JOB',
        job_type   => 'PLSQL_BLOCK',
        job_action => q'[
            BEGIN
                LOOP
                    DELETE FROM FMSB_BIT_MAPPED WHERE OP_TYPE = 'D';
                    COMMIT;
                END LOOP;
            END;
        ]',
        start_date => SYSTIMESTAMP,
        enabled    => FALSE,
        auto_drop  => FALSE
    );
END;

-- FMSB_CAT_MAPPED
BEGIN
    DBMS_SCHEDULER.create_job(
        job_name   => 'T24RAW.FMSB_CAT_MAPPED_DEL_JOB',
        job_type   => 'PLSQL_BLOCK',
        job_action => q'[
            BEGIN
                LOOP
                    DELETE FROM FMSB_CAT_MAPPED WHERE OP_TYPE = 'D';
                    COMMIT;
                END LOOP;
            END;
        ]',
        start_date => SYSTIMESTAMP,
        enabled    => FALSE,
        auto_drop  => FALSE
    );
END;

-- FMSB_CHG_MAPPED
BEGIN
    DBMS_SCHEDULER.create_job(
        job_name   => 'T24RAW.FMSB_CHG_MAPPED_DEL_JOB',
        job_type   => 'PLSQL_BLOCK',
        job_action => q'[
            BEGIN
                LOOP
                    DELETE FROM FMSB_CHG_MAPPED WHERE OP_TYPE = 'D';
                    COMMIT;
                END LOOP;
            END;
        ]',
        start_date => SYSTIMESTAMP,
        enabled    => FALSE,
        auto_drop  => FALSE
    );
END;

-- FMSB_ECB_MAPPED
BEGIN
    DBMS_SCHEDULER.create_job(
        job_name   => 'T24RAW.FMSB_ECB_MAPPED_DEL_JOB',
        job_type   => 'PLSQL_BLOCK',
        job_action => q'[
            BEGIN
                LOOP
                    DELETE FROM FMSB_ECB_MAPPED WHERE OP_TYPE = 'D';
                    COMMIT;
                END LOOP;
            END;
        ]',
        start_date => SYSTIMESTAMP,
        enabled    => FALSE,
        auto_drop  => FALSE
    );
END;

-- FMSB_FT_MAPPED
BEGIN
    DBMS_SCHEDULER.create_job(
        job_name   => 'T24RAW.FMSB_FT_MAPPED_DEL_JOB',
        job_type   => 'PLSQL_BLOCK',
        job_action => q'[
            BEGIN
                LOOP
                    DELETE FROM FMSB_FT_MAPPED WHERE OP_TYPE = 'D';
                    COMMIT;
                END LOOP;
            END;
        ]',
        start_date => SYSTIMESTAMP,
        enabled    => FALSE,
        auto_drop  => FALSE
    );
END;

-- FMSB_FX_MAPPED
BEGIN
    DBMS_SCHEDULER.create_job(
        job_name   => 'T24RAW.FMSB_FX_MAPPED_DEL_JOB',
        job_type   => 'PLSQL_BLOCK',
        job_action => q'[
            BEGIN
                LOOP
                    DELETE FROM FMSB_FX_MAPPED WHERE OP_TYPE = 'D';
                    COMMIT;
                END LOOP;
            END;
        ]',
        start_date => SYSTIMESTAMP,
        enabled    => FALSE,
        auto_drop  => FALSE
    );
END;

-- FMSB_LMT_MAPPED
BEGIN
    DBMS_SCHEDULER.create_job(
        job_name   => 'T24RAW.FMSB_LMT_MAPPED_DEL_JOB',
        job_type   => 'PLSQL_BLOCK',
        job_action => q'[
            BEGIN
                LOOP
                    DELETE FROM FMSB_LMT_MAPPED WHERE OP_TYPE = 'D';
                    COMMIT;
                END LOOP;
            END;
        ]',
        start_date => SYSTIMESTAMP,
        enabled    => FALSE,
        auto_drop  => FALSE
    );
END;

-- FMSB_REC_MAPPED
BEGIN
    DBMS_SCHEDULER.create_job(
        job_name   => 'T24RAW.FMSB_REC_MAPPED_DEL_JOB',
        job_type   => 'PLSQL_BLOCK',
        job_action => q'[
            BEGIN
                LOOP
                    DELETE FROM FMSB_REC_MAPPED WHERE OP_TYPE = 'D';
                    COMMIT;
                END LOOP;
            END;
        ]',
        start_date => SYSTIMESTAMP,
        enabled    => FALSE,
        auto_drop  => FALSE
    );
END;

-- FMSB_STM_MAPPED
BEGIN
    DBMS_SCHEDULER.create_job(
        job_name   => 'T24RAW.FMSB_STM_MAPPED_DEL_JOB',
        job_type   => 'PLSQL_BLOCK',
        job_action => q'[
            BEGIN
                LOOP
                    DELETE FROM FMSB_STM_MAPPED WHERE OP_TYPE = 'D';
                    COMMIT;
                END LOOP;
            END;
        ]',
        start_date => SYSTIMESTAMP,
        enabled    => FALSE,
        auto_drop  => FALSE
    );
END;

-- FMSB_TR_MAPPED
BEGIN
    DBMS_SCHEDULER.create_job(
        job_name   => 'T24RAW.FMSB_TR_MAPPED_DEL_JOB',
        job_type   => 'PLSQL_BLOCK',
        job_action => q'[
            BEGIN
                LOOP
                    DELETE FROM FMSB_TR_MAPPED WHERE OP_TYPE = 'D';
                    COMMIT;
                END LOOP;
            END;
        ]',
        start_date => SYSTIMESTAMP,
        enabled    => FALSE,
        auto_drop  => FALSE
    );
END;

-- DROP
BEGIN DBMS_SCHEDULER.drop_job('T24RAW.FMSB_ARR_LNMEMO_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.drop_job('T24RAW.FMSB_BIL_LNMEMO_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.drop_job('T24RAW.FMSB_AIT_LNTNEW_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.drop_job('T24RAW.FMSB_ARC_LNTNEW_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.drop_job('T24RAW.FMSB_ARR_LNTNEW_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.drop_job('T24RAW.F_DAT_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.drop_job('T24RAW.F_POR_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.drop_job('T24RAW.F_PST_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.drop_job('T24RAW.F_SUP_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.drop_job('T24RAW.F_TMV_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.drop_job('T24RAW.FMSB_AAC_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.drop_job('T24RAW.FMSB_AC_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.drop_job('T24RAW.FMSB_ACC_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.drop_job('T24RAW.FMSB_ADL_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.drop_job('T24RAW.FMSB_AIT_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.drop_job('T24RAW.FMSB_ARC_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.drop_job('T24RAW.FMSB_ARR_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.drop_job('T24RAW.FMSB_ASC_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.drop_job('T24RAW.FMSB_ATA_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.drop_job('T24RAW.FMSB_BIL_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.drop_job('T24RAW.FMSB_BIT_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.drop_job('T24RAW.FMSB_CAT_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.drop_job('T24RAW.FMSB_CHG_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.drop_job('T24RAW.FMSB_ECB_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.drop_job('T24RAW.FMSB_FT_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.drop_job('T24RAW.FMSB_FX_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.drop_job('T24RAW.FMSB_LMT_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.drop_job('T24RAW.FMSB_REC_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.drop_job('T24RAW.FMSB_STM_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.drop_job('T24RAW.FMSB_TR_MAPPED_DEL_JOB', TRUE); END;

-- STOP
BEGIN DBMS_SCHEDULER.stop_job('T24RAW.FMSB_ARR_LNMEMO_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.stop_job('T24RAW.FMSB_BIL_LNMEMO_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.stop_job('T24RAW.FMSB_AIT_LNTNEW_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.stop_job('T24RAW.FMSB_ARC_LNTNEW_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.stop_job('T24RAW.FMSB_ARR_LNTNEW_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.stop_job('T24RAW.F_DAT_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.stop_job('T24RAW.F_POR_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.stop_job('T24RAW.F_PST_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.stop_job('T24RAW.F_SUP_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.stop_job('T24RAW.F_TMV_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.stop_job('T24RAW.FMSB_AAC_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.stop_job('T24RAW.FMSB_AC_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.stop_job('T24RAW.FMSB_ACC_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.stop_job('T24RAW.FMSB_ADL_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.stop_job('T24RAW.FMSB_AIT_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.stop_job('T24RAW.FMSB_ARC_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.stop_job('T24RAW.FMSB_ARR_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.stop_job('T24RAW.FMSB_ASC_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.stop_job('T24RAW.FMSB_ATA_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.stop_job('T24RAW.FMSB_BIL_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.stop_job('T24RAW.FMSB_BIT_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.stop_job('T24RAW.FMSB_CAT_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.stop_job('T24RAW.FMSB_CHG_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.stop_job('T24RAW.FMSB_ECB_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.stop_job('T24RAW.FMSB_FT_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.stop_job('T24RAW.FMSB_FX_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.stop_job('T24RAW.FMSB_LMT_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.stop_job('T24RAW.FMSB_REC_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.stop_job('T24RAW.FMSB_STM_MAPPED_DEL_JOB', TRUE); END;
BEGIN DBMS_SCHEDULER.stop_job('T24RAW.FMSB_TR_MAPPED_DEL_JOB', TRUE); END;

-- RUN
BEGIN DBMS_SCHEDULER.run_job('T24RAW.FMSB_ARR_LNMEMO_DEL_JOB', FALSE); END;
BEGIN DBMS_SCHEDULER.run_job('T24RAW.FMSB_BIL_LNMEMO_DEL_JOB', FALSE); END;
BEGIN DBMS_SCHEDULER.run_job('T24RAW.FMSB_AIT_LNTNEW_DEL_JOB', FALSE); END;
BEGIN DBMS_SCHEDULER.run_job('T24RAW.FMSB_ARC_LNTNEW_DEL_JOB', FALSE); END;
BEGIN DBMS_SCHEDULER.run_job('T24RAW.FMSB_ARR_LNTNEW_DEL_JOB', FALSE); END;
BEGIN DBMS_SCHEDULER.run_job('T24RAW.F_DAT_MAPPED_DEL_JOB', FALSE); END;
BEGIN DBMS_SCHEDULER.run_job('T24RAW.F_POR_MAPPED_DEL_JOB', FALSE); END;
BEGIN DBMS_SCHEDULER.run_job('T24RAW.F_PST_MAPPED_DEL_JOB', FALSE); END;
BEGIN DBMS_SCHEDULER.run_job('T24RAW.F_SUP_MAPPED_DEL_JOB', FALSE); END;
BEGIN DBMS_SCHEDULER.run_job('T24RAW.F_TMV_MAPPED_DEL_JOB', FALSE); END;
BEGIN DBMS_SCHEDULER.run_job('T24RAW.FMSB_AAC_MAPPED_DEL_JOB', FALSE); END;
BEGIN DBMS_SCHEDULER.run_job('T24RAW.FMSB_AC_MAPPED_DEL_JOB', FALSE); END;
BEGIN DBMS_SCHEDULER.run_job('T24RAW.FMSB_ACC_MAPPED_DEL_JOB', FALSE); END;
BEGIN DBMS_SCHEDULER.run_job('T24RAW.FMSB_ADL_MAPPED_DEL_JOB', FALSE); END;
BEGIN DBMS_SCHEDULER.run_job('T24RAW.FMSB_AIT_MAPPED_DEL_JOB', FALSE); END;
BEGIN DBMS_SCHEDULER.run_job('T24RAW.FMSB_ARC_MAPPED_DEL_JOB', FALSE); END;
BEGIN DBMS_SCHEDULER.run_job('T24RAW.FMSB_ARR_MAPPED_DEL_JOB', FALSE); END;
BEGIN DBMS_SCHEDULER.run_job('T24RAW.FMSB_ASC_MAPPED_DEL_JOB', FALSE); END;
BEGIN DBMS_SCHEDULER.run_job('T24RAW.FMSB_ATA_MAPPED_DEL_JOB', FALSE); END;
BEGIN DBMS_SCHEDULER.run_job('T24RAW.FMSB_BIL_MAPPED_DEL_JOB', FALSE); END;
BEGIN DBMS_SCHEDULER.run_job('T24RAW.FMSB_BIT_MAPPED_DEL_JOB', FALSE); END;
BEGIN DBMS_SCHEDULER.run_job('T24RAW.FMSB_CAT_MAPPED_DEL_JOB', FALSE); END;
BEGIN DBMS_SCHEDULER.run_job('T24RAW.FMSB_CHG_MAPPED_DEL_JOB', FALSE); END;
BEGIN DBMS_SCHEDULER.run_job('T24RAW.FMSB_ECB_MAPPED_DEL_JOB', FALSE); END;
BEGIN DBMS_SCHEDULER.run_job('T24RAW.FMSB_FT_MAPPED_DEL_JOB', FALSE); END;
BEGIN DBMS_SCHEDULER.run_job('T24RAW.FMSB_FX_MAPPED_DEL_JOB', FALSE); END;
BEGIN DBMS_SCHEDULER.run_job('T24RAW.FMSB_LMT_MAPPED_DEL_JOB', FALSE); END;
BEGIN DBMS_SCHEDULER.run_job('T24RAW.FMSB_REC_MAPPED_DEL_JOB', FALSE); END;
BEGIN DBMS_SCHEDULER.run_job('T24RAW.FMSB_STM_MAPPED_DEL_JOB', FALSE); END;
BEGIN DBMS_SCHEDULER.run_job('T24RAW.FMSB_TR_MAPPED_DEL_JOB', FALSE); END;

-- STATUS
SELECT JOB_NAME, STATE, LAST_START_DATE, RUN_COUNT, FAILURE_COUNT
FROM DBA_SCHEDULER_JOBS
WHERE OWNER = 'T24RAW' AND JOB_NAME LIKE '%DEL_JOB';

-- ERROR
SELECT JOB_NAME, STATUS, ACTUAL_START_DATE, RUN_DURATION, ADDITIONAL_INFO
FROM DBA_SCHEDULER_JOB_RUN_DETAILS
WHERE OWNER = 'T24RAW' AND JOB_NAME LIKE '%DEL_JOB'
  AND STATUS = 'FAILED'
  AND ACTUAL_START_DATE > TO_TIMESTAMP('2025-09-12 00:00:00.000', 'YYYY-MM-DD HH24:MI:SS.FF3')
ORDER BY ACTUAL_START_DATE DESC;
