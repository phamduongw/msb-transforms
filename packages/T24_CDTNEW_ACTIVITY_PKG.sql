CREATE OR REPLACE PACKAGE T24RAWOGG.T24_CDTNEW_ACTIVITY_PKG IS

    PROCEDURE GEN_FROM_ACC_PROC;

    PROCEDURE GEN_FROM_ARR_PROC;

END T24_CDTNEW_ACTIVITY_PKG;

CREATE OR REPLACE PACKAGE BODY T24RAWOGG.T24_CDTNEW_ACTIVITY_PKG IS
---------------------------------------------------------------------------
-- GEN_FROM_ACC_PROC
---------------------------------------------------------------------------
    PROCEDURE GEN_FROM_ACC_PROC IS
        V_DUMMY          NUMBER;
        V_WINDOW_ID_LIST T_WINDOW_ID_ARRAY;
        V_TODAY          VARCHAR2(8); 
    BEGIN
        SELECT 1 INTO V_DUMMY
        FROM T24_CDTNEW_ACTIVITY_ACC
        WHERE ROWNUM = 1;

        DELETE /*+ PARALLEL(CDC, 8) */ FROM T24_CDTNEW_ACTIVITY_ACC CDC
        WHERE EXISTS (
            SELECT 1
            FROM V_FMSB_ACC_MAPPED ACC
            WHERE ACC.RECID = CDC.RECID
            AND CDC.WINDOW_ID <= ACC.WINDOW_ID
        )
        -- AND ROWNUM <= 5000
        RETURNING CDC.WINDOW_ID BULK COLLECT INTO V_WINDOW_ID_LIST;

        SYS.DBMS_SESSION.SLEEP(0.2);
        SELECT /*+ RESULT_CACHE */ TODAY INTO V_TODAY
        FROM F_DAT_MAPPED
        WHERE RECID = 'VN0011000';

        INSERT INTO T24_CDTNEW_ACTIVITY (
            BANKNO, ACCTNO, ACTYPE, ACNAME, CIFNO, TYPE, BRN, STATUS,
            CDNUM, ORGBAL, CBAL, HOLD, ACCINT, WDRWH, RNWCTR, PENAMT,
            ISSDT, MATDT, CDTERM, CDTCOD, RENEW, DACTN, RATE, CURTYP, CDMUID, RS2DT7,
            WINDOW_ID, COMMIT_TS, REPLICAT_TS, MAPPED_TS, CALL_CDC
        )
        WITH PRECOMPUTED AS (
            SELECT /*+ MATERIALIZE */
                ACC.RECID           AS ACC_RECID,
                ARR.RECID           AS ARR_RECID,
                ACC.ACNAME          AS ACNAME,
                ACC.CUSTOMER        AS CIFNO,
                ARR.ACTIVE_PRODUCT  AS TYPE,
                ACC.CO_CODE         AS BRN,
                ARR.ARR_STATUS      AS STATUS,
                ARR.START_DATE      AS ISSDT, 
                ADL.MATURITY_DATE   AS MATDT,
                ARR.CURRENCY        AS CURTYP,
                ACC.INPUTTER        AS CDMUID,
                ADL.RENEWAL_DATE    AS RS2DT7,
                ACC.WINDOW_ID       AS WINDOW_ID,
                ACC.COMMIT_TS       AS COMMIT_TS,
                ACC.REPLICAT_TS     AS REPLICAT_TS,
                ACC.MAPPED_TS       AS MAPPED_TS
            FROM TABLE(V_WINDOW_ID_LIST) V
            JOIN V_FMSB_ACC_MAPPED ACC ON ACC.WINDOW_ID = V.COLUMN_VALUE
            JOIN V_FMSB_ARR_CD ARR ON ARR.LINKED_APPL_ID = ACC.RECID
            LEFT JOIN V_FMSB_ADL_MAPPED ADL ON ADL.RECID = ARR.RECID
            WHERE ARR.START_DATE >= TO_DATE(V_TODAY,'YYYYMMDD')
        ),
        AIT_AGGREGATED AS(
            SELECT 
                ID_COMP_1, 
                MAX(ID_COMP_3) AS MAX_ID_COMP_3
            FROM V_FMSB_AIT_CDTNEW AIT
            WHERE EXISTS (
                SELECT 1 FROM PRECOMPUTED PRE
                WHERE PRE.ARR_RECID = AIT.ID_COMP_1)
            AND AIT.ID_COMP_3 <= V_TODAY || '.9999'
            GROUP BY ID_COMP_1 
        ),
        ATA_AGGREGATED AS(
            SELECT 
                ID_COMP_1, 
                MIN(ID_COMP_3) AS MIN_ID_COMP_3
            FROM V_FMSB_ATA_MAPPED ATA
            WHERE EXISTS (
                SELECT 1 FROM PRECOMPUTED PRE
                WHERE PRE.ARR_RECID = ATA.ID_COMP_1)
            GROUP BY ID_COMP_1
        ),
        CHG_AGGREGATED AS(
            SELECT 
                ID_COMP_1, 
                MAX(ID_COMP_3) AS MAX_ID_COMP_3
            FROM V_FMSB_CHG_MAPPED CHG
            WHERE EXISTS (
                SELECT 1 FROM PRECOMPUTED PRE
                WHERE PRE.ARR_RECID = CHG.ID_COMP_1)
            GROUP BY ID_COMP_1
        )
        SELECT
            27 AS BANKNO,
            TO_NUMBER(PRE.ACC_RECID) AS ACCTNO,
            'T' AS ACTYPE,
            TRIM(PRE.ACNAME) AS ACNAME,
            PRE.CIFNO AS CIFNO,
            PRE.TYPE AS TYPE,
            PRE.BRN AS BRN,
            CASE
                WHEN PRE.STATUS IN ('CLOSE', 'PENDING.CLOSURE', 'CANCELLED') THEN 2
                ELSE 4
            END AS STATUS,
            TO_NUMBER(PRE.ACC_RECID) AS CDNUM,
            ATA.AMOUNT AS ORGBAL,
            0 AS CBAL,
            0 AS HOLD,
            0 AS ACCINT,
            0 AS WDRWH,
            0 AS RNWCTR,
            0 AS PENAMT,
            TO_NUMBER(TO_CHAR(PRE.ISSDT, 'YYYYDDD')) AS ISSDT,
            TO_NUMBER(TO_CHAR(PRE.MATDT, 'YYYYDDD')) AS MATDT,
            SUBSTR( NVL(AIT.PERIODIC_PERIOD, ATA.TERM), 1, LENGTH(NVL(AIT.PERIODIC_PERIOD, ATA.TERM)) - 1) AS CDTERM,
            SUBSTR( NVL(AIT.PERIODIC_PERIOD, ATA.TERM), -1) AS CDTCOD,
            CASE
                WHEN CHG.CHANGE_PERIOD IS NOT NULL OR CHG.CHANGE_DATE IS NOT NULL THEN 'Y'
                ELSE 'N'
            END AS RENEW,
            '' AS DACTN,
            TO_NUMBER(AIT.EFFECTIVE_RATE)/100 AS RATE,
            PRE.CURTYP AS CURTYP,
            SUBSTR(
                PRE.CDMUID,
                INSTR(PRE.CDMUID, '_', 1, 1) + 1,
                INSTR(PRE.CDMUID, '_', 1, 2) - INSTR(PRE.CDMUID, '_', 1, 1) - 1
            ) AS CDMUID,
            TO_NUMBER(TO_CHAR(PRE.RS2DT7, 'YYYYDDD')) AS RS2DT7,
            PRE.WINDOW_ID,
            PRE.COMMIT_TS,
            PRE.REPLICAT_TS,
            PRE.MAPPED_TS,
            'ACC'
        FROM PRECOMPUTED PRE
        LEFT JOIN AIT_AGGREGATED AIT_AGG ON AIT_AGG.ID_COMP_1 = PRE.ARR_RECID
        LEFT JOIN V_FMSB_AIT_CDTNEW AIT ON AIT.ID_COMP_1 = AIT_AGG.ID_COMP_1 AND AIT.ID_COMP_3 = AIT_AGG.MAX_ID_COMP_3
        LEFT JOIN ATA_AGGREGATED ATA_AGG ON ATA_AGG.ID_COMP_1 = PRE.ARR_RECID
        LEFT JOIN V_FMSB_ATA_MAPPED ATA ON ATA.ID_COMP_1 = ATA_AGG.ID_COMP_1 AND ATA.ID_COMP_3 = ATA_AGG.MIN_ID_COMP_3
        LEFT JOIN CHG_AGGREGATED CHG_AGG ON CHG_AGG.ID_COMP_1 = PRE.ARR_RECID
        LEFT JOIN V_FMSB_CHG_MAPPED CHG ON CHG.ID_COMP_1 = CHG_AGG.ID_COMP_1 AND CHG.ID_COMP_3 = CHG_AGG.MAX_ID_COMP_3;

        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN;
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END GEN_FROM_ACC_PROC;

---------------------------------------------------------------------------
-- GEN_FROM_ARR_PROC
---------------------------------------------------------------------------
    PROCEDURE GEN_FROM_ARR_PROC IS
        V_DUMMY          NUMBER;
        V_WINDOW_ID_LIST T_WINDOW_ID_ARRAY;
        V_TODAY          VARCHAR2(8);
    BEGIN
        SELECT 1 INTO V_DUMMY
        FROM T24_CDTNEW_ACTIVITY_ARR
        WHERE ROWNUM = 1;

        DELETE /*+ PARALLEL(CDC, 8) */ FROM T24_CDTNEW_ACTIVITY_ARR CDC
        WHERE EXISTS (
             SELECT 1
            FROM V_FMSB_ARR_CD ARR
            WHERE ARR.RECID = CDC.RECID
            AND CDC.WINDOW_ID <= ARR.WINDOW_ID
        )
        -- AND ROWNUM <= 5000
        RETURNING CDC.WINDOW_ID BULK COLLECT INTO V_WINDOW_ID_LIST;

        SYS.DBMS_SESSION.SLEEP(0.2);
        SELECT /*+ RESULT_CACHE */ TODAY INTO V_TODAY
        FROM F_DAT_MAPPED
        WHERE RECID = 'VN0011000';

        INSERT INTO T24_CDTNEW_ACTIVITY (
            BANKNO, ACCTNO, ACTYPE, ACNAME, CIFNO, TYPE, BRN, STATUS,
            CDNUM, ORGBAL, CBAL, HOLD, ACCINT, WDRWH, RNWCTR, PENAMT,
            ISSDT, MATDT, CDTERM, CDTCOD, RENEW, DACTN, RATE, CURTYP, CDMUID, RS2DT7,
            WINDOW_ID, COMMIT_TS, REPLICAT_TS, MAPPED_TS, CALL_CDC
        )
        WITH PRECOMPUTED AS (
            SELECT /*+ MATERIALIZE */
                ARR.LINKED_APPL_ID  AS ARR_LINKED_APPL_ID,
                ARR.RECID           AS ARR_RECID,
                ACC.ACNAME          AS ACNAME,
                ACC.CUSTOMER        AS CIFNO,
                ARR.ACTIVE_PRODUCT  AS TYPE,
                ACC.CO_CODE         AS BRN,
                ARR.ARR_STATUS      AS STATUS,
                ARR.START_DATE      AS ISSDT,
                ADL.MATURITY_DATE   AS MATDT,
                ARR.CURRENCY        AS CURTYP,
                ACC.INPUTTER        AS CDMUID,
                ADL.RENEWAL_DATE    AS RS2DT7,
                ARR.WINDOW_ID       AS WINDOW_ID,
                ARR.COMMIT_TS       AS COMMIT_TS,
                ARR.REPLICAT_TS     AS REPLICAT_TS,
                ARR.MAPPED_TS       AS MAPPED_TS
            FROM TABLE(V_WINDOW_ID_LIST) V
            JOIN V_FMSB_ARR_CD ARR ON ARR.WINDOW_ID = V.COLUMN_VALUE
            JOIN V_FMSB_ACC_MAPPED ACC ON ACC.RECID = ARR.LINKED_APPL_ID
            LEFT JOIN V_FMSB_ADL_MAPPED ADL ON ADL.RECID = ARR.RECID
            WHERE ARR.START_DATE >= TO_DATE(V_TODAY,'YYYYMMDD')
        ),
        AIT_AGGREGATED AS(
            SELECT 
                ID_COMP_1, 
                MAX(ID_COMP_3) AS MAX_ID_COMP_3
            FROM V_FMSB_AIT_CDTNEW AIT
            WHERE EXISTS (
                SELECT 1 FROM PRECOMPUTED PRE
                WHERE PRE.ARR_RECID = AIT.ID_COMP_1)
            AND AIT.ID_COMP_3 <= V_TODAY || '.9999'
            GROUP BY ID_COMP_1
        ),
        ATA_AGGREGATED AS(
            SELECT 
                ID_COMP_1, 
                MIN(ID_COMP_3) AS MIN_ID_COMP_3
            FROM V_FMSB_ATA_MAPPED ATA
            WHERE EXISTS (
                SELECT 1 FROM PRECOMPUTED PRE
                WHERE PRE.ARR_RECID = ATA.ID_COMP_1)
            GROUP BY ID_COMP_1
        ),
        CHG_AGGREGATED AS(
            SELECT 
                ID_COMP_1, 
                MAX(ID_COMP_3) AS MAX_ID_COMP_3
            FROM V_FMSB_CHG_MAPPED CHG
            WHERE EXISTS (
                SELECT 1 FROM PRECOMPUTED PRE
                WHERE PRE.ARR_RECID = CHG.ID_COMP_1)
            GROUP BY ID_COMP_1
        )
        SELECT
            27 AS BANKNO,
            TO_NUMBER(PRE.ARR_LINKED_APPL_ID) AS ACCTNO,
            'T' AS ACTYPE,
            TRIM(PRE.ACNAME) AS ACNAME,
            PRE.CIFNO AS CIFNO,
            PRE.TYPE AS TYPE,
            PRE.BRN AS BRN,
            CASE
                WHEN PRE.STATUS IN ('CLOSE', 'PENDING.CLOSURE', 'CANCELLED') THEN 2
                ELSE 4
            END AS STATUS,
            TO_NUMBER(PRE.ARR_LINKED_APPL_ID) AS CDNUM,
            ATA.AMOUNT AS ORGBAL,
            0 AS CBAL,
            0 AS HOLD,
            0 AS ACCINT,
            0 AS WDRWH,
            0 AS RNWCTR,
            0 AS PENAMT,
            TO_NUMBER(TO_CHAR(PRE.ISSDT, 'YYYYDDD')) AS ISSDT,
            TO_NUMBER(TO_CHAR(PRE.MATDT, 'YYYYDDD')) AS MATDT,
            SUBSTR( NVL(AIT.PERIODIC_PERIOD, ATA.TERM), 1, LENGTH(NVL(AIT.PERIODIC_PERIOD, ATA.TERM)) - 1) AS CDTERM,
            SUBSTR( NVL(AIT.PERIODIC_PERIOD, ATA.TERM), -1) AS CDTCOD,
            CASE
                WHEN CHG.CHANGE_PERIOD IS NOT NULL OR CHG.CHANGE_DATE IS NOT NULL THEN 'Y'
                ELSE 'N'
            END AS RENEW,
            '' AS DACTN,
            TO_NUMBER(AIT.EFFECTIVE_RATE)/100 AS RATE,
            PRE.CURTYP AS CURTYP,
            SUBSTR(
                PRE.CDMUID,
                INSTR(PRE.CDMUID, '_', 1, 1) + 1,
                INSTR(PRE.CDMUID, '_', 1, 2) - INSTR(PRE.CDMUID, '_', 1, 1) - 1
            ) AS CDMUID,
            TO_NUMBER(TO_CHAR(PRE.RS2DT7, 'YYYYDDD')) AS RS2DT7,
            PRE.WINDOW_ID,
            PRE.COMMIT_TS,
            PRE.REPLICAT_TS,
            PRE.MAPPED_TS,
            'ARR'
            FROM PRECOMPUTED PRE
            LEFT JOIN AIT_AGGREGATED AIT_AGG ON AIT_AGG.ID_COMP_1 = PRE.ARR_RECID
            LEFT JOIN V_FMSB_AIT_CDTNEW AIT ON AIT.ID_COMP_1 = AIT_AGG.ID_COMP_1 AND AIT.ID_COMP_3 = AIT_AGG.MAX_ID_COMP_3
            LEFT JOIN ATA_AGGREGATED ATA_AGG ON ATA_AGG.ID_COMP_1 = PRE.ARR_RECID
            LEFT JOIN V_FMSB_ATA_MAPPED ATA ON ATA.ID_COMP_1 = ATA_AGG.ID_COMP_1 AND ATA.ID_COMP_3 = ATA_AGG.MIN_ID_COMP_3
            LEFT JOIN CHG_AGGREGATED CHG_AGG ON CHG_AGG.ID_COMP_1 = PRE.ARR_RECID
            LEFT JOIN V_FMSB_CHG_MAPPED CHG ON CHG.ID_COMP_1 = CHG_AGG.ID_COMP_1 AND CHG.ID_COMP_3 = CHG_AGG.MAX_ID_COMP_3;

        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN;
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END GEN_FROM_ARR_PROC;

END T24_CDTNEW_ACTIVITY_PKG;
