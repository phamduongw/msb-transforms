CREATE OR REPLACE PACKAGE T24RAWOGG.T24_DDTNEW_ACTIVITY_PKG IS

    PROCEDURE GEN_FROM_ACC_ARR;

END T24_DDTNEW_ACTIVITY_PKG;

CREATE OR REPLACE PACKAGE BODY T24RAWOGG.T24_DDTNEW_ACTIVITY_PKG IS

---------------------------------------------------------------------------
-- GEN_FROM_ACC_ARR
---------------------------------------------------------------------------
    PROCEDURE GEN_FROM_ACC_ARR IS
        V_JOIN_KEY_LIST  T_JOIN_KEY_ARRAY;
        V_WINDOW_ID_LIST T_WINDOW_ID_ARRAY;
        V_CAPTURED_TIME  TIMESTAMP := SYSTIMESTAMP;
        V_TODAY          VARCHAR2(8);
    BEGIN
        SELECT CDC.JOIN_KEY, CDC.WINDOW_ID
        BULK COLLECT INTO V_JOIN_KEY_LIST, V_WINDOW_ID_LIST
        FROM T24_DDTNEW_ACTIVITY_ACC_ARR CDC
        WHERE EXISTS (
            SELECT 1
            FROM V_FMSB_ACC_MAPPED ACC
            WHERE ACC.RECID = CDC.JOIN_KEY
            AND ACC.WINDOW_ID >= CDC.WINDOW_ID
        )
        OR EXISTS (
            SELECT 1
            FROM V_FMSB_ARR_MAPPED ARR
            WHERE ARR.LINKED_APPL_ID = CDC.JOIN_KEY
            AND ARR.WINDOW_ID >= CDC.WINDOW_ID
        );
        -- ) FETCH FIRST 9999 ROWS ONLY;
        
        IF V_JOIN_KEY_LIST.COUNT > 0 THEN
            SELECT /*+ RESULT_CACHE */ TODAY INTO V_TODAY
            FROM F_DAT_MAPPED
            WHERE RECID = 'VN0011000';

            INSERT INTO T24_DDTNEW_ACTIVITY (
                BRANCH, ACNAME, ACCTNO, ACTYPE, DDCTYP, SCCODE, CIFNO, STATUS,
                DATOP7, DLA7, DLA6, HOLD, CBAL, ACCRUE, RATE, ODLIMT, CAPTURED_TIME, CALL_CDC
            )
            WITH GROUPED AS (
                SELECT DISTINCT COLUMN_VALUE
                FROM TABLE(V_JOIN_KEY_LIST)
            ),
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
                0 AS CBAL,
                0 AS ACCRUE,
                0 AS RATE,
                0 AS ODLIMT,
                V_CAPTURED_TIME,
                '1'
            FROM GROUPED GRP
            INNER JOIN V_FMSB_ARR_MAPPED ARR ON ARR.LINKED_APPL_ID = GRP.COLUMN_VALUE
            INNER JOIN V_FMSB_ACC_MAPPED ACC ON ACC.RECID          = GRP.COLUMN_VALUE
            WHERE ARR.PRODUCT_LINE = 'ACCOUNTS' AND ARR.ARR_STATUS <> 'UNAUTH'
            AND ARR.START_DATE >= V_TODAY;

            DELETE FROM T24_DDTNEW_ACTIVITY_ACC_ARR CDC
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
    END GEN_FROM_ACC_ARR;

END T24_DDTNEW_ACTIVITY_PKG;
