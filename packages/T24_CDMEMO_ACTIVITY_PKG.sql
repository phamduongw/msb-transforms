CREATE OR REPLACE PACKAGE T24RAWOGG.T24_CDMEMO_ACTIVITY_PKG IS

    FUNCTION CALC_HOLD_VAL_FUNC(
        P_LOCKED_AMOUNT IN VARCHAR2
    ) RETURN NUMBER;

    FUNCTION CALC_CBAL_VAL_FUNC(
        P_CURR_ASSET_TYPE IN VARCHAR2,
        P_OPEN_BALANCE    IN VARCHAR2,
        P_CREDIT_MVMT     IN VARCHAR2,
        P_DEBIT_MVMT      IN VARCHAR2
    ) RETURN NUMBER;

    FUNCTION CALC_ACCINT_VAL_FUNC(
        P_CURR_ASSET_TYPE IN VARCHAR2,
        P_OPEN_BALANCE    IN VARCHAR2,
        P_CREDIT_MVMT     IN VARCHAR2,
        P_DEBIT_MVMT      IN VARCHAR2
    ) RETURN NUMBER;

    PROCEDURE GEN_FROM_ACC_ARR_ECB_PROC;

END T24_CDMEMO_ACTIVITY_PKG;

CREATE OR REPLACE PACKAGE BODY T24RAWOGG.T24_CDMEMO_ACTIVITY_PKG IS
 
---------------------------------------------------------------------------
-- CALC_HOLD_VAL_FUNC
---------------------------------------------------------------------------
    FUNCTION CALC_HOLD_VAL_FUNC(
        P_LOCKED_AMOUNT IN VARCHAR2
    ) RETURN NUMBER IS
        V_HOLD          NUMBER      := 0;
        V_START         PLS_INTEGER := 1;
        V_LEN           PLS_INTEGER := LENGTH(P_LOCKED_AMOUNT);
        V_COLON_IDX     PLS_INTEGER;
        V_HASH_IDX      PLS_INTEGER;
        V_POS           VARCHAR2(6);
        V_LOCKED_AMOUNT NUMBER;
    BEGIN
        IF P_LOCKED_AMOUNT IS NULL THEN
            RETURN V_HOLD;
        END IF;

        WHILE V_START <= V_LEN LOOP
            V_COLON_IDX := INSTR(P_LOCKED_AMOUNT, ':', V_START) + 1;
            V_HASH_IDX := INSTR(P_LOCKED_AMOUNT, '#', V_COLON_IDX);

            IF V_HASH_IDX = 0 THEN
                V_HASH_IDX := V_LEN + 1;
            END IF;

            V_POS := SUBSTR(P_LOCKED_AMOUNT, V_START, V_COLON_IDX - V_START);
            V_LOCKED_AMOUNT := T24_UTILS_PKG.GET_NUM_VAL_BY_POS_FUNC(P_LOCKED_AMOUNT, V_POS);

            IF V_LOCKED_AMOUNT > V_HOLD THEN
                V_HOLD := V_LOCKED_AMOUNT;
            END IF;

            V_START := V_HASH_IDX;
        END LOOP;

        RETURN V_HOLD;
    END CALC_HOLD_VAL_FUNC;

---------------------------------------------------------------------------
-- CALC_CBAL_VAL_FUNC
---------------------------------------------------------------------------
    FUNCTION CALC_CBAL_VAL_FUNC(
        P_CURR_ASSET_TYPE IN VARCHAR2,
        P_OPEN_BALANCE    IN VARCHAR2,
        P_CREDIT_MVMT     IN VARCHAR2,
        P_DEBIT_MVMT      IN VARCHAR2
    ) RETURN NUMBER IS
        V_CBAL            NUMBER := 0;
        V_START           PLS_INTEGER := 1;
        V_LEN             PLS_INTEGER := LENGTH(P_CURR_ASSET_TYPE);
        V_COLON_IDX       PLS_INTEGER;
        V_HASH_IDX        PLS_INTEGER;
        V_M_VAL           VARCHAR2(6);
        V_CURR_ASSET_TYPE VARCHAR2(50);
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

            IF V_CURR_ASSET_TYPE IN ('CURACCOUNT', 'PAYACCOUNT') THEN
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
-- CALC_ACCINT_VAL_FUNC
---------------------------------------------------------------------------
    FUNCTION CALC_ACCINT_VAL_FUNC(
        P_CURR_ASSET_TYPE IN VARCHAR2,
        P_OPEN_BALANCE    IN VARCHAR2,
        P_CREDIT_MVMT     IN VARCHAR2,
        P_DEBIT_MVMT      IN VARCHAR2
    ) RETURN NUMBER IS
        V_ACCINT          NUMBER := 0;
        V_START           PLS_INTEGER := 1;
        V_LEN             PLS_INTEGER := LENGTH(P_CURR_ASSET_TYPE);
        V_COLON_IDX       PLS_INTEGER;
        V_HASH_IDX        PLS_INTEGER;
        V_M_VAL           VARCHAR2(6);
        V_CURR_ASSET_TYPE VARCHAR2(50);
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

            IF V_CURR_ASSET_TYPE = 'ACCDEPOSITINT' THEN
                V_ACCINT := V_ACCINT
                    + T24_UTILS_PKG.GET_NUM_VAL_BY_POS_FUNC(P_OPEN_BALANCE, V_M_VAL)
                    + T24_UTILS_PKG.GET_NUM_VAL_BY_POS_FUNC(P_CREDIT_MVMT, V_M_VAL)
                    + T24_UTILS_PKG.GET_NUM_VAL_BY_POS_FUNC(P_DEBIT_MVMT, V_M_VAL);
            END IF;

            V_START := V_HASH_IDX;
        END LOOP;

        RETURN V_ACCINT;
    END CALC_ACCINT_VAL_FUNC;

---------------------------------------------------------------------------
-- GEN_FROM_ACC_ARR_ECB_PROC
---------------------------------------------------------------------------
    PROCEDURE GEN_FROM_ACC_ARR_ECB_PROC IS
        V_JOIN_KEY_LIST  T_JOIN_KEY_ARRAY;
        V_WINDOW_ID_LIST T_WINDOW_ID_ARRAY;
        V_CAPTURED_TIME  TIMESTAMP := SYSTIMESTAMP;
        V_TODAY          VARCHAR2(8);
    BEGIN
        SELECT CDC.JOIN_KEY, CDC.WINDOW_ID
        BULK COLLECT INTO V_JOIN_KEY_LIST, V_WINDOW_ID_LIST
        FROM T24_CDMEMO_ACTIVITY_ACC_ARR_ECB CDC
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
            FROM V_FMSB_ARR_CD ARR
            WHERE ARR.LINKED_APPL_ID = CDC.JOIN_KEY
            AND ARR.WINDOW_ID >= CDC.WINDOW_ID
        );
        -- ) FETCH FIRST 9999 ROWS ONLY;
        
        IF V_JOIN_KEY_LIST.COUNT > 0 THEN
            SELECT /*+ RESULT_CACHE */ TODAY INTO V_TODAY
            FROM F_DAT_MAPPED
            WHERE RECID = 'VN0011000';

            INSERT INTO T24_CDMEMO_ACTIVITY (
                ACCTNO, CURTYP, CDNUM, CBAL, HOLD, 
                STATUS, ACCINT, WDRWH, PENAMT, CAPTURED_TIME, CALL_CDC
            )
            WITH GROUPED AS (
                SELECT DISTINCT COLUMN_VALUE
                FROM TABLE(V_JOIN_KEY_LIST)
            ),
            SELECT
                TO_NUMBER(ACC.RECID) AS ACCTNO,
                ACC.CURRENCY AS CURTYP,
                TO_NUMBER(ACC.RECID) AS CDNUM,
                CALC_CBAL_VAL_FUNC(ECB.CURR_ASSET_TYPE, ECB.OPEN_BALANCE, ECB.CREDIT_MVMT, ECB.DEBIT_MVMT) AS CBAL, 
                CALC_HOLD_VAL_FUNC(PRE.LOCKED_AMOUNT), -- HOLD
                CASE
                    WHEN ARR.ARR_STATUS IN ('CLOSE', 'PENDING.CLOSURE', 'CANCELLED') THEN 2
                    WHEN PST.RESTRICTION_TYPE IN ('ALL', 'DEBIT') THEN 6
                    WHEN ARR.ARR_STATUS IN ('MATURED', 'EXPIRED') THEN 3
                    WHEN ARR.ARR_STATUS IN ('AUTH', 'AUTH-FWD') OR ARR.START_DATE = TO_DATE(V_TODAY,'YYYYMMDD') THEN 4
                    ELSE 1
                END AS STATUS,
                CALC_ACCINT_VAL_FUNC(ECB.CURR_ASSET_TYPE, ECB.OPEN_BALANCE, ECB.CREDIT_MVMT, ECB.DEBIT_MVMT) AS ACCINT,
                0 AS WDRWH,
                0 AS PENAMT,
                V_CAPTURED_TIME,
                '1'
            FROM GROUPED GRP
            INNER JOIN V_FMSB_ARR_CD     ARR ON ARR.LINKED_APPL_ID = GRP.COLUMN_VALUE
            INNER JOIN V_FMSB_ACC_MAPPED ACC ON ACC.RECID          = GRP.COLUMN_VALUE
            INNER JOIN V_FMSB_ECB_MAPPED ECB ON ECB.RECID          = GRP.COLUMN_VALUE
            LEFT JOIN  F_PST_MAPPED      PST ON PST.RECID          = ACC.POSTING_RESTRICT;

            DELETE FROM T24_CDMEMO_ACTIVITY_ACC_ARR_ECB CDC
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
    END GEN_FROM_ACC_ARR_ECB_PROC;

END T24_CDMEMO_ACTIVITY_PKG;
