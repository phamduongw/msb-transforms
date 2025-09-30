BEGIN
    DBMS_SCHEDULER.create_job(
        job_name         => 'T24RAWOGG.DAILY_PURGE_OP_TYPE_D_JOB',
        job_type         => 'PLSQL_BLOCK',
        job_action       => q'[
            BEGIN
                DELETE FROM FMSB_ARR_CD     WHERE OP_TYPE = 'D';
                DELETE FROM FMSB_ARR_LNMEMO WHERE OP_TYPE = 'D';
                DELETE FROM FMSB_BIL_LNMEMO WHERE OP_TYPE = 'D';
                DELETE FROM FMSB_AIT_LNTNEW WHERE OP_TYPE = 'D';
                DELETE FROM FMSB_ARC_LNTNEW WHERE OP_TYPE = 'D';
                DELETE FROM FMSB_ARR_LNTNEW WHERE OP_TYPE = 'D';
                DELETE FROM F_DAT_MAPPED    WHERE OP_TYPE = 'D';
                DELETE FROM F_POR_MAPPED    WHERE OP_TYPE = 'D';
                DELETE FROM F_PST_MAPPED    WHERE OP_TYPE = 'D';
                DELETE FROM F_SUP_MAPPED    WHERE OP_TYPE = 'D';
                DELETE FROM F_TMV_MAPPED    WHERE OP_TYPE = 'D';
                DELETE FROM FMSB_AAC_MAPPED WHERE OP_TYPE = 'D';
                DELETE FROM FMSB_AC_MAPPED  WHERE OP_TYPE = 'D';
                DELETE FROM FMSB_ACC_MAPPED WHERE OP_TYPE = 'D';
                DELETE FROM FMSB_ADL_MAPPED WHERE OP_TYPE = 'D';
                DELETE FROM FMSB_AIT_MAPPED WHERE OP_TYPE = 'D';
                DELETE FROM FMSB_ARC_MAPPED WHERE OP_TYPE = 'D';
                DELETE FROM FMSB_ARR_MAPPED WHERE OP_TYPE = 'D';
                DELETE FROM FMSB_ASC_MAPPED WHERE OP_TYPE = 'D';
                DELETE FROM FMSB_ATA_MAPPED WHERE OP_TYPE = 'D';
                DELETE FROM FMSB_BIL_MAPPED WHERE OP_TYPE = 'D';
                DELETE FROM FMSB_BIT_MAPPED WHERE OP_TYPE = 'D';
                DELETE FROM FMSB_CAT_MAPPED WHERE OP_TYPE = 'D';
                DELETE FROM FMSB_CHG_MAPPED WHERE OP_TYPE = 'D';
                DELETE FROM FMSB_ECB_MAPPED WHERE OP_TYPE = 'D';
                DELETE FROM FMSB_FT_MAPPED  WHERE OP_TYPE = 'D';
                DELETE FROM FMSB_FX_MAPPED  WHERE OP_TYPE = 'D';
                DELETE FROM FMSB_LMT_MAPPED WHERE OP_TYPE = 'D';
                DELETE FROM FMSB_REC_MAPPED WHERE OP_TYPE = 'D';
                DELETE FROM FMSB_STM_MAPPED WHERE OP_TYPE = 'D';
                DELETE FROM FMSB_TR_MAPPED  WHERE OP_TYPE = 'D';
                COMMIT;
            END;
        ]',
        start_date       => SYSTIMESTAMP,
        repeat_interval  => 'FREQ=DAILY;BYHOUR=5;BYMINUTE=0;BYSECOND=0',
        enabled          => FALSE,
        auto_drop        => FALSE
    );
END;
