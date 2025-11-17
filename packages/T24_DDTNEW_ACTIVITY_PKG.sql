CREATE OR REPLACE PACKAGE T24RAWOGG.T24_DDTNEW_ACTIVITY_PKG IS

    PROCEDURE GEN_FROM_ACC_PROC;

    PROCEDURE GEN_FROM_ARR_PROC;

END T24_DDTNEW_ACTIVITY_PKG;

CREATE OR REPLACE PACKAGE BODY T24RAWOGG.T24_DDTNEW_ACTIVITY_PKG IS

---------------------------------------------------------------------------
-- GEN_FROM_ACC_PROC
---------------------------------------------------------------------------
    PROCEDURE GEN_FROM_ACC_PROC IS
        V_WINDOW_ID_LIST T_WINDOW_ID_ARRAY;
        V_TODAY          VARCHAR2(8);
    BEGIN
        SELECT CDC.WINDOW_ID
        BULK COLLECT INTO V_WINDOW_ID_LIST
        FROM T24_DDTNEW_ACTIVITY_ACC CDC
        WHERE EXISTS (
            SELECT 1
            FROM V_FMSB_ACC_MAPPED ACC
            WHERE CDC.WINDOW_ID = ACC.WINDOW_ID
        );
        -- ) FETCH FIRST 5000 ROWS ONLY;

        IF V_WINDOW_ID_LIST.COUNT > 0 THEN

            DELETE FROM T24_DDTNEW_ACTIVITY_ACC CDC
            WHERE EXISTS (
                SELECT 1
                FROM TABLE(V_WINDOW_ID_LIST) V
                WHERE V.COLUMN_VALUE = CDC.WINDOW_ID
            );

            SELECT /*+ RESULT_CACHE */ TODAY INTO V_TODAY
            FROM F_DAT_MAPPED
            WHERE RECID = 'VN0011000';

            INSERT INTO T24_DDTNEW_ACTIVITY (
                BRANCH, ACNAME, ACCTNO, ACTYPE, DDCTYP, SCCODE, CIFNO, STATUS,
                DATOP7, DLA7, DLA6, HOLD, CBAL, ACCRUE, RATE, ODLIMT,
                WINDOW_ID, COMMIT_TS, REPLICAT_TS, MAPPED_TS, CALL_CDC
            )
            SELECT
                ACC.CO_CODE AS BRANCH,
                ACC.ACNAME AS ACNAME,
                TO_NUMBER(ACC.RECID) AS ACCTNO,
                CASE 
                    WHEN TO_NUMBER(ACC.CATEGORY) BETWEEN 6000 AND 6100 THEN 'S' 
                    ELSE 'D'
                END AS ACTYPE,
                ACC.CURRENCY AS DDCTYP,
                ARR.ACTIVE_PRODUCT AS SCCODE,
                TO_NUMBER(ACC.CUSTOMER) AS CIFNO,
                CASE
                    WHEN ARR.ARR_STATUS IN ('CLOSE','PENDING.CLOSURE','CANCELLED') THEN 2
                    ELSE 4
                END AS STATUS,
                TO_NUMBER(TO_CHAR(NVL(TO_DATE(ARR.ORIG_CONTRACT_DATE, 'YYYYMMDD'), ACC.OPENING_DATE), 'YYYYDDD')) AS DATOP7,
                TO_NUMBER(TO_CHAR(TO_DATE(ARR.START_DATE, 'YYYYMMDD'), 'YYYYDDD')) AS DLA7,
                TO_NUMBER(TO_CHAR(TO_DATE(ARR.START_DATE, 'YYYYMMDD'), 'DDMMYY')) AS DLA6,
                0 AS HOLD,
                TO_NUMBER(NVL(ACC.ONLINE_ACTUAL_BAL,0)) AS CBAL,
                0 AS ACCRUE,
                0 AS RATE,
                0 AS ODLIMT,
                ACC.WINDOW_ID,
                ACC.COMMIT_TS,
                ACC.REPLICAT_TS,
                ACC.MAPPED_TS,
                'ACC'
                FROM TABLE(V_WINDOW_ID_LIST) V
                INNER JOIN V_FMSB_ACC_MAPPED ACC ON ACC.WINDOW_ID = V.COLUMN_VALUE
                INNER JOIN V_FMSB_ARR_MAPPED ARR ON ARR.LINKED_APPL_ID = ACC.RECID
                WHERE ARR.PRODUCT_LINE = 'ACCOUNTS' AND ARR.ARR_STATUS <> 'UNAUTH'
                AND ARR.START_DATE >= V_TODAY;

            COMMIT;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END GEN_FROM_ACC_PROC;

---------------------------------------------------------------------------
-- GEN_FROM_ARR_PROC
---------------------------------------------------------------------------
    PROCEDURE GEN_FROM_ARR_PROC IS
        V_WINDOW_ID_LIST T_WINDOW_ID_ARRAY;
        V_TODAY          VARCHAR2(8);
    BEGIN
        SELECT CDC.WINDOW_ID
        BULK COLLECT INTO V_WINDOW_ID_LIST
        FROM T24_DDTNEW_ACTIVITY_ARR CDC
        WHERE EXISTS (
            SELECT 1
            FROM V_FMSB_ARR_MAPPED ARR
            WHERE CDC.WINDOW_ID = ARR.WINDOW_ID
        );
        -- ) FETCH FIRST 5000 ROWS ONLY;

        IF V_WINDOW_ID_LIST.COUNT > 0 THEN

            DELETE FROM T24_DDTNEW_ACTIVITY_ARR CDC
            WHERE EXISTS (
                SELECT 1
                FROM TABLE(V_WINDOW_ID_LIST) V
                WHERE V.COLUMN_VALUE = CDC.WINDOW_ID
            );

            SELECT /*+ RESULT_CACHE */ TODAY INTO V_TODAY
            FROM F_DAT_MAPPED
            WHERE RECID = 'VN0011000';

            INSERT INTO T24_DDTNEW_ACTIVITY (
                BRANCH, ACNAME, ACCTNO, ACTYPE, DDCTYP, SCCODE, CIFNO, STATUS,
                DATOP7, DLA7, DLA6, HOLD, CBAL, ACCRUE, RATE, ODLIMT,
                WINDOW_ID, COMMIT_TS, REPLICAT_TS, MAPPED_TS, CALL_CDC
            )
            WITH PRECOMPUTED AS (
                SELECT /*+ MATERIALIZE */
                    ARR.RECID               AS ARR_RECID,
                    ACC.CO_CODE             AS BRANCH,
                    ACC.ACNAME              AS ACNAME,
                    ARR.LINKED_APPL_ID      AS ACCTNO,
                    ACC.CATEGORY            AS ACTYPE,
                    ACC.CURRENCY            AS DDCTYP,
                    ARR.ACTIVE_PRODUCT      AS SCCODE,
                    ACC.CUSTOMER            AS CIFNO,
                    ARR.ARR_STATUS          AS ARR_STATUS,
                    ARR.ORIG_CONTRACT_DATE  AS ORIG_CONTRACT_DATE,
                    ACC.OPENING_DATE        AS OPENING_DATE,
                    ARR.START_DATE          AS START_DATE,
                    ACC.ONLINE_ACTUAL_BAL   AS CBAL,
                    ARR.WINDOW_ID           AS WINDOW_ID,
                    ARR.COMMIT_TS           AS COMMIT_TS,
                    ARR.REPLICAT_TS         AS REPLICAT_TS,
                    ARR.MAPPED_TS           AS MAPPED_TS
                FROM TABLE(V_WINDOW_ID_LIST) V
                INNER JOIN V_FMSB_ARR_MAPPED ARR ON ARR.WINDOW_ID = V.COLUMN_VALUE
                INNER JOIN V_FMSB_ACC_MAPPED ACC ON ACC.RECID = ARR.LINKED_APPL_ID
                WHERE ARR.PRODUCT_LINE = 'ACCOUNTS' AND ARR.ARR_STATUS <> 'UNAUTH'
            ),
            ARC_AGGREGATED AS(
                SELECT 
                    ARRANGEMENT
                FROM V_FMSB_ARC_DDTNEW ARC
                WHERE EXISTS (
                    SELECT 1 FROM PRECOMPUTED PRE
                    WHERE PRE.ARR_RECID = ARC.ARRANGEMENT
                    AND PRE.START_DATE < V_TODAY)
                AND ARC.TRADE_DATE < TO_DATE(V_TODAY,'YYYYMMDD') 
                AND TRUNC(TO_DATE(ARC.DATE_TIME, 'RRMMDDHH24MI')) = TO_DATE(V_TODAY,'YYYYMMDD')
            )
            SELECT
                PRE.BRANCH AS BRANCH,
                PRE.ACNAME AS ACNAME,
                TO_NUMBER(PRE.ACCTNO) AS ACCTNO,
                CASE 
                    WHEN TO_NUMBER(PRE.ACTYPE) BETWEEN 6000 AND 6100 THEN 'S' 
                    ELSE 'D'
                END AS ACTYPE,
                PRE.DDCTYP AS DDCTYP,
                PRE.SCCODE AS SCCODE,
                TO_NUMBER(PRE.CIFNO) AS CIFNO,
                CASE
                    WHEN PRE.ARR_STATUS IN ('CLOSE','PENDING.CLOSURE','CANCELLED') THEN 2
                    ELSE 4
                END AS STATUS,
                TO_NUMBER(TO_CHAR(NVL(TO_DATE(PRE.ORIG_CONTRACT_DATE, 'YYYYMMDD'), PRE.OPENING_DATE), 'YYYYDDD')) AS DATOP7,
                TO_NUMBER(TO_CHAR(TO_DATE(PRE.START_DATE, 'YYYYMMDD'), 'YYYYDDD')) AS DLA7,
                TO_NUMBER(TO_CHAR(TO_DATE(PRE.START_DATE, 'YYYYMMDD'), 'DDMMYY')) AS DLA6,
                0 AS HOLD,
                TO_NUMBER(NVL(PRE.CBAL,0)) AS CBAL,
                0 AS ACCRUE,
                0 AS RATE,
                0 AS ODLIMT,
                PRE.WINDOW_ID,
                PRE.COMMIT_TS,
                PRE.REPLICAT_TS,
                PRE.MAPPED_TS,
                'ARR'
                FROM PRECOMPUTED PRE
                LEFT JOIN ARC_AGGREGATED ARC ON ARC.ARRANGEMENT = PRE.ARR_RECID
                WHERE PRE.START_DATE >= V_TODAY OR ARC.ARRANGEMENT IS NOT NULL;

            COMMIT;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END GEN_FROM_ARR_PROC;

END T24_DDTNEW_ACTIVITY_PKG;