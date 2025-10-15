CREATE OR REPLACE PACKAGE T24RAWOGG.T24_DDTNEW_ACTIVITY_PKG IS

    FUNCTION CALC_CBAL_VAL_FUNC(
        P_CURR_ASSET_TYPE  IN VARCHAR2,
        P_OPEN_BALANCE     IN VARCHAR2,
        P_CREDIT_MVMT      IN VARCHAR2,
        P_DEBIT_MVMT       IN VARCHAR2
    ) RETURN NUMBER;

    PROCEDURE GEN_FROM_ACC_ARR_ECB;

END T24_DDTNEW_ACTIVITY_PKG;

CREATE OR REPLACE PACKAGE BODY T24RAWOGG.T24_DDTNEW_ACTIVITY_PKG IS

---------------------------------------------------------------------------
-- CALC_CBAL_VAL_FUNC
---------------------------------------------------------------------------
    FUNCTION CALC_CBAL_VAL_FUNC(
        P_CURR_ASSET_TYPE IN VARCHAR2,
        P_OPEN_BALANCE    IN VARCHAR2,
        P_CREDIT_MVMT     IN VARCHAR2,
        P_DEBIT_MVMT      IN VARCHAR2
    ) RETURN NUMBER IS
        V_CBAL              NUMBER := 0;
        V_START             PLS_INTEGER := 1;
        V_LEN               PLS_INTEGER := LENGTH(P_CURR_ASSET_TYPE);
        V_COLON_IDX         PLS_INTEGER;
        V_HASH_IDX          PLS_INTEGER;
        V_M_VAL             VARCHAR2(6);
        V_CURR_ASSET_TYPE   VARCHAR2(50);
    BEGIN
        IF P_CURR_ASSET_TYPE IS NULL THEN
            RETURN 0;
        END IF;

        WHILE V_START <= V_LEN LOOP
            V_COLON_IDX := INSTR(P_CURR_ASSET_TYPE, ':', V_START) + 1;
            V_HASH_IDX  := INSTR(P_CURR_ASSET_TYPE, '#', V_COLON_IDX);

            IF V_HASH_IDX = 0 THEN
                V_HASH_IDX := V_LEN + 1;
            END IF;

            V_M_VAL            := SUBSTR(P_CURR_ASSET_TYPE, V_START, V_COLON_IDX - V_START);
            V_CURR_ASSET_TYPE  := SUBSTR(P_CURR_ASSET_TYPE, V_COLON_IDX, V_HASH_IDX - V_COLON_IDX);

            IF V_CURR_ASSET_TYPE IN ('CREDIT', 'DEBIT') THEN
                V_CBAL := V_CBAL
                    + T24_UTILS_PKG.GET_NUM_VAL_BY_POS_FUNC(P_OPEN_BALANCE, V_M_VAL)
                    + T24_UTILS_PKG.GET_NUM_VAL_BY_POS_FUNC(P_CREDIT_MVMT, V_M_VAL)
                    + T24_UTILS_PKG.GET_NUM_VAL_BY_POS_FUNC(P_DEBIT_MVMT, V_M_VAL);
            END IF;

            V_START := V_HASH_IDX;
        END LOOP;

        RETURN V_CBAL;
    END CALC_CBAL_VAL_FUNC;

---------------------------------------------------------------------------
-- GEN_FROM_ACC_ARR_ECB
---------------------------------------------------------------------------
    PROCEDURE GEN_FROM_ACC_ARR_ECB IS
        V_JOIN_KEY_LIST  T_JOIN_KEY_ARRAY;
        V_WINDOW_ID_LIST T_WINDOW_ID_ARRAY;
        V_CAPTURED_TIME  TIMESTAMP := SYSTIMESTAMP;
    BEGIN
        SELECT CDC.JOIN_KEY, CDC.WINDOW_ID
        BULK COLLECT INTO V_JOIN_KEY_LIST, V_WINDOW_ID_LIST
        FROM T24_DDTNEW_ACTIVITY_ACC_ARR_ECB CDC
        WHERE EXISTS (
            SELECT 1
            FROM V_FMSB_ECB_MAPPED ECB
            WHERE ECB.RECID = CDC.JOIN_KEY
            AND ECB.WINDOW_ID >= CDC.WINDOW_ID
        )
        OR EXISTS (
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
                CALC_CBAL_VAL_FUNC(ECB.CURR_ASSET_TYPE, ECB.OPEN_BALANCE, ECB.CREDIT_MVMT, ECB.DEBIT_MVMT) AS CBAL,
                0 AS ACCRUE,
                0 AS RATE,
                0 AS ODLIMT,
                V_CAPTURED_TIME,
                '1'
            FROM GROUPED GRP
            INNER JOIN V_FMSB_ARR_MAPPED ARR ON ARR.LINKED_APPL_ID = GRP.COLUMN_VALUE
            INNER JOIN V_FMSB_ACC_MAPPED ACC ON ACC.RECID          = GRP.COLUMN_VALUE
            INNER JOIN V_FMSB_ECB_MAPPED ECB ON ECB.RECID          = GRP.COLUMN_VALUE
            WHERE ARR.PRODUCT_LINE = 'ACCOUNTS' AND ARR.ARR_STATUS <> 'UNAUTH'
            AND ARR.START_DATE >= V_TODAY;

            DELETE FROM T24_DDTNEW_ACTIVITY_ACC_ARR_ECB CDC
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
    END GEN_FROM_ACC_ARR_ECB;

END T24_DDTNEW_ACTIVITY_PKG;
