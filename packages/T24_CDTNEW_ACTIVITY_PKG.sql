CREATE OR REPLACE PACKAGE T24RAWOGG.T24_CDTNEW_ACTIVITY_PKG IS
    
    PROCEDURE GEN_FROM_ACC_PROC;

    PROCEDURE GEN_FROM_ARR_AIT_ATA_CHG_PROC;

END T24_CDTNEW_ACTIVITY_PKG;

CREATE OR REPLACE PACKAGE BODY T24RAWOGG.T24_CDTNEW_ACTIVITY_PKG IS

---------------------------------------------------------------------------
-- GEN_FROM_ACC_PROC
---------------------------------------------------------------------------
    PROCEDURE GEN_FROM_ACC_PROC IS
        V_WINDOW_ID_LIST T_WINDOW_ID_ARRAY;
        V_TODAY          VARCHAR2(8); 
    BEGIN
        SELECT CDC.WINDOW_ID
        BULK COLLECT INTO V_WINDOW_ID_LIST 
        FROM T24_CDTNEW_ACTIVITY_ACC CDC
        WHERE EXISTS (
            SELECT 1
            FROM V_FMSB_ACC_MAPPED ACC
            WHERE CDC.WINDOW_ID = ACC.WINDOW_ID
        );
        -- ) FETCH FIRST 5000 ROWS ONLY;

        IF V_WINDOW_ID_LIST.COUNT > 0 THEN
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
                    ACC.OPEN_ACTUAL_BAL AS CBAL,
                    ACC.OPENING_DATE    AS ISSDT, 
                    ADL.MATURITY_DATE   AS MATDT,
                    ARR.CURRENCY        AS CURTYP,
                    ACC.INPUTTER        AS CDMUID,
                    ADL.RENEWAL_DATE    AS RS2DT7,
                    ACC.WINDOW_ID       AS WINDOW_ID,
                    ACC.COMMIT_TS       AS COMMIT_TS,
                    ACC.REPLICAT_TS     AS REPLICAT_TS,
                    ACC.MAPPED_TS       AS MAPPED_TS
                FROM TABLE(V_WINDOW_ID_LIST) V
                INNER JOIN V_FMSB_ACC_MAPPED ACC ON ACC.WINDOW_ID = V.COLUMN_VALUE
                INNER JOIN V_FMSB_ARR_CD ARR ON ARR.LINKED_APPL_ID = ACC.RECID
                LEFT JOIN V_FMSB_ADL_MAPPED ADL ON ADL.RECID = ARR.RECID
                WHERE ARR.START_DATE >= TO_DATE(V_TODAY,'YYYYMMDD')
            ), 
            AIT_MAX AS (
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
            AIT_AGGREGATED AS(
                SELECT
                    AIT.ID_COMP_1, 
                    AIT.EFFECTIVE_RATE,
                    AIT.PERIODIC_PERIOD
                FROM V_FMSB_AIT_CDTNEW AIT
                JOIN AIT_MAX M ON AIT.ID_COMP_1 = M.ID_COMP_1 AND AIT.ID_COMP_3 = M.MAX_ID_COMP_3
            ),
            ATA_MIN AS (
                SELECT 
                    ATA.ID_COMP_1,
                    MIN(ATA.ID_COMP_3) AS MIN_ID_COMP_3
                FROM V_FMSB_ATA_MAPPED ATA
                WHERE EXISTS (
                    SELECT 1
                    FROM PRECOMPUTED PRE
                    WHERE PRE.ARR_RECID = ATA.ID_COMP_1
                )
                GROUP BY ATA.ID_COMP_1
            ),
            ATA_AGGREGATED AS(
                SELECT 
                	ATA.ID_COMP_1,
                    ATA.AMOUNT,
                    ATA.TERM
                FROM V_FMSB_ATA_MAPPED ATA
                JOIN ATA_MIN M ON ATA.ID_COMP_1 = M.ID_COMP_1 AND ATA.ID_COMP_3 = M.MIN_ID_COMP_3
            ), 
            CHG_MAX AS (
                SELECT 
                    ID_COMP_1, 
                    MAX(ID_COMP_3) AS MAX_ID_COMP_3
                FROM V_FMSB_CHG_MAPPED CHG
                WHERE EXISTS (
                    SELECT 1 FROM PRECOMPUTED PRE
                    WHERE PRE.ARR_RECID = CHG.ID_COMP_1)
                GROUP BY ID_COMP_1                
            ),
            CHG_AGGREGATED AS(
                SELECT 
                	CHG.ID_COMP_1,
                    CHG.CHANGE_PERIOD,
                    CHG.CHANGE_DATE
                FROM V_FMSB_CHG_MAPPED CHG
                JOIN CHG_MAX M ON CHG.ID_COMP_1 = M.ID_COMP_1 AND CHG.ID_COMP_3 = M.MAX_ID_COMP_3
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
                TO_NUMBER(NVL(PRE.CBAL,0)) AS CBAL,
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
            LEFT JOIN AIT_AGGREGATED AIT ON AIT.ID_COMP_1 = PRE.ARR_RECID
            LEFT JOIN ATA_AGGREGATED ATA ON ATA.ID_COMP_1 = PRE.ARR_RECID
            LEFT JOIN CHG_AGGREGATED CHG ON CHG.ID_COMP_1 = PRE.ARR_RECID;

            DELETE FROM T24_CDTNEW_ACTIVITY_ACC CDC
            WHERE EXISTS (
                SELECT 1
                FROM TABLE(V_WINDOW_ID_LIST) TMP
                WHERE TMP.COLUMN_VALUE = CDC.WINDOW_ID
            );

            COMMIT;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END GEN_FROM_ACC_PROC;

---------------------------------------------------------------------------
-- GEN_FROM_ARR_AIT_ATA_CHG_PROC
---------------------------------------------------------------------------
    PROCEDURE GEN_FROM_ARR_AIT_ATA_CHG_PROC IS
        V_JOIN_KEY_LIST  T_JOIN_KEY_ARRAY;
        V_WINDOW_ID_LIST T_WINDOW_ID_ARRAY;
        V_TODAY          VARCHAR2(8);
    BEGIN
        SELECT CDC.JOIN_KEY, CDC.WINDOW_ID
        BULK COLLECT INTO V_JOIN_KEY_LIST, V_WINDOW_ID_LIST
        FROM T24_CDTNEW_ACTIVITY_ARR_AIT_ATA_CHG CDC
        WHERE EXISTS (
            SELECT 1
            FROM V_FMSB_ARR_CD ARR
            WHERE ARR.WINDOW_ID = CDC.WINDOW_ID
        )
        OR EXISTS (
            SELECT 1
            FROM V_FMSB_AIT_CDTNEW AIT
            WHERE AIT.WINDOW_ID = CDC.WINDOW_ID
        )
        OR EXISTS (
            SELECT 1
            FROM V_FMSB_ATA_MAPPED ATA
            WHERE ATA.WINDOW_ID = CDC.WINDOW_ID
        )
        OR EXISTS (
            SELECT 1
            FROM V_FMSB_CHG_MAPPED CHG
            WHERE CHG.WINDOW_ID = CDC.WINDOW_ID
        );
        -- ) FETCH FIRST 9999 ROWS ONLY;

        IF V_JOIN_KEY_LIST.COUNT > 0 THEN
            SELECT /*+ RESULT_CACHE */ TODAY INTO V_TODAY
            FROM F_DAT_MAPPED
            WHERE RECID = 'VN0011000';

            INSERT INTO T24_CDTNEW_ACTIVITY (
                BANKNO, ACCTNO, ACTYPE, ACNAME, CIFNO, TYPE, BRN, STATUS,
                CDNUM, ORGBAL, CBAL, HOLD, ACCINT, WDRWH, RNWCTR, PENAMT,
                ISSDT, MATDT, CDTERM, CDTCOD, RENEW, DACTN, RATE, CURTYP, CDMUID, RS2DT7,
                WINDOW_ID, COMMIT_TS, REPLICAT_TS, MAPPED_TS, CALL_CDC
            )
            WITH GROUPED AS (
                SELECT DISTINCT COLUMN_VALUE
                FROM TABLE(V_JOIN_KEY_LIST)
            ),
            PRECOMPUTED AS (
                SELECT /*+ MATERIALIZE */
                    ARR.LINKED_APPL_ID  AS ARR_LINKED_APPL_ID,
                    ARR.RECID           AS ARR_RECID,
                    ACC.ACNAME          AS ACNAME,
                    ACC.CUSTOMER        AS CIFNO,
                    ARR.ACTIVE_PRODUCT  AS TYPE,
                    ACC.CO_CODE         AS BRN,
                    ARR.ARR_STATUS      AS ARR_STATUS,
                    ACC.OPEN_ACTUAL_BAL AS CBAL,
                    ARR.START_DATE      AS START_DATE,
                    ACC.OPENING_DATE 	AS ISSDT,
                    ADL.MATURITY_DATE   AS MATDT,
                    ARR.CURRENCY        AS CURTYP,
                    ACC.INPUTTER        AS CDMUID,
                    ADL.RENEWAL_DATE    AS RS2DT7,
                    ARR.WINDOW_ID       AS WINDOW_ID,
                    ARR.COMMIT_TS       AS COMMIT_TS,
                    ARR.REPLICAT_TS     AS REPLICAT_TS,
                    ARR.MAPPED_TS       AS MAPPED_TS
                FROM GROUPED GRP
                INNER JOIN  V_FMSB_ARR_CD ARR     ON ARR.RECID = GRP.COLUMN_VALUE
                INNER JOIN  V_FMSB_ACC_MAPPED ACC ON ACC.RECID = ARR.LINKED_APPL_ID
                LEFT JOIN   V_FMSB_ADL_MAPPED ADL ON ADL.RECID = ARR.RECID
            ), 
            ARC_AGGREGATED AS(
                SELECT 
                    ARRANGEMENT
                FROM V_FMSB_ARC_CDTNEW ARC
                WHERE EXISTS (
                    SELECT 1 FROM PRECOMPUTED PRE
                    WHERE PRE.ARR_RECID = ARC.ARRANGEMENT
                    AND PRE.START_DATE < TO_DATE(V_TODAY,'YYYYMMDD'))
                AND ARC.TRADE_DATE < TO_DATE(V_TODAY,'YYYYMMDD') 
                AND TRUNC(TO_DATE(ARC.DATE_TIME, 'RRMMDDHH24MI')) = TO_DATE(V_TODAY,'YYYYMMDD')
            ),
            AIT_MAX AS (
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
            AIT_AGGREGATED AS(
                SELECT 
                    AIT.ID_COMP_1,
                    AIT.EFFECTIVE_RATE,
                    AIT.PERIODIC_PERIOD,
                    AIT.WINDOW_ID,
                    AIT.COMMIT_TS,
                    AIT.REPLICAT_TS,
                    AIT.MAPPED_TS
                FROM V_FMSB_AIT_CDTNEW AIT
                JOIN AIT_MAX M ON AIT.ID_COMP_1 = M.ID_COMP_1 AND AIT.ID_COMP_3 = M.MAX_ID_COMP_3
            ),
            ATA_MIN AS (
                SELECT 
                    ATA.ID_COMP_1,
                    MIN(ATA.ID_COMP_3) AS MIN_ID_COMP_3
                FROM V_FMSB_ATA_MAPPED ATA
                WHERE EXISTS (
                    SELECT 1
                    FROM PRECOMPUTED PRE
                    WHERE PRE.ARR_RECID = ATA.ID_COMP_1
                )
                GROUP BY ATA.ID_COMP_1
            ),
            ATA_AGGREGATED AS(
                SELECT 
                    ATA.ID_COMP_1,
                    ATA.AMOUNT,
                    ATA.TERM,
                    ATA.WINDOW_ID,
                    ATA.COMMIT_TS,
                    ATA.REPLICAT_TS,
                    ATA.MAPPED_TS
                FROM V_FMSB_ATA_MAPPED ATA
                JOIN ATA_MIN M ON ATA.ID_COMP_1 = M.ID_COMP_1 AND ATA.ID_COMP_3 = M.MIN_ID_COMP_3
            ),
            CHG_MAX AS (
                SELECT 
                    ID_COMP_1, 
                    MAX(ID_COMP_3) AS MAX_ID_COMP_3
                FROM V_FMSB_CHG_MAPPED CHG
                WHERE EXISTS (
                    SELECT 1 FROM PRECOMPUTED PRE
                    WHERE PRE.ARR_RECID = CHG.ID_COMP_1)
                GROUP BY ID_COMP_1                
            ),
            CHG_AGGREGATED AS(
                SELECT 
                    CHG.ID_COMP_1,
                    CHG.CHANGE_PERIOD,
                    CHG.CHANGE_DATE,
                    CHG.WINDOW_ID,
                    CHG.COMMIT_TS,
                    CHG.REPLICAT_TS,
                    CHG.MAPPED_TS
                FROM V_FMSB_CHG_MAPPED CHG
                JOIN CHG_MAX M ON CHG.ID_COMP_1 = M.ID_COMP_1 AND CHG.ID_COMP_3 = M.MAX_ID_COMP_3
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
                    WHEN PRE.ARR_STATUS IN ('CLOSE', 'PENDING.CLOSURE', 'CANCELLED') THEN 2
                    ELSE 4
                END AS STATUS,
                TO_NUMBER(PRE.ARR_LINKED_APPL_ID) AS CDNUM,
                ATA.AMOUNT AS ORGBAL,
                TO_NUMBER(NVL(PRE.CBAL,0)) AS CBAL,
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
                GREATEST(PRE.WINDOW_ID, AIT.WINDOW_ID, ATA.WINDOW_ID, CHG.WINDOW_ID)         AS WINDOW_ID,
                GREATEST(PRE.COMMIT_TS, AIT.COMMIT_TS, ATA.COMMIT_TS, CHG.COMMIT_TS)         AS COMMIT_TS,
                GREATEST(PRE.REPLICAT_TS, AIT.REPLICAT_TS, ATA.REPLICAT_TS, CHG.REPLICAT_TS) AS REPLICAT_TS,
                GREATEST(PRE.MAPPED_TS, AIT.MAPPED_TS, ATA.MAPPED_TS, CHG.MAPPED_TS)         AS MAPPED_TS,
                'ARR_AIT_ATA_CHG'
            FROM PRECOMPUTED PRE
            INNER JOIN AIT_AGGREGATED AIT ON AIT.ID_COMP_1 = PRE.ARR_RECID
            INNER JOIN ATA_AGGREGATED ATA ON ATA.ID_COMP_1 = PRE.ARR_RECID
            INNER JOIN CHG_AGGREGATED CHG ON CHG.ID_COMP_1 = PRE.ARR_RECID
            LEFT JOIN ARC_AGGREGATED ARC ON ARC.ARRANGEMENT = PRE.ARR_RECID
            WHERE (PRE.START_DATE >= TO_DATE(V_TODAY,'YYYYMMDD'))
                OR (PRE.ARR_STATUS = 'AUTH' AND PRE.START_DATE < TO_DATE(V_TODAY,'YYYYMMDD'))
                OR (ARC.ARRANGEMENT IS NOT NULL);

            DELETE FROM T24_CDTNEW_ACTIVITY_ARR_AIT_ATA_CHG CDC
            WHERE EXISTS (
                SELECT 1
                FROM TABLE(V_WINDOW_ID_LIST) TMP
                WHERE TMP.COLUMN_VALUE = CDC.WINDOW_ID
            );

            COMMIT;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END GEN_FROM_ARR_AIT_ATA_CHG_PROC;

END T24_CDTNEW_ACTIVITY_PKG;