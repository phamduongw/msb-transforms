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

    PROCEDURE GEN_FROM_ACC_ECB_ARR_PROC;

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
-- GEN_FROM_ACC_ECB_ARR_PROC
---------------------------------------------------------------------------
    PROCEDURE GEN_FROM_ACC_ECB_ARR_PROC IS
        V_TODAY          VARCHAR2(8);
        V_DUMMY          NUMBER;
        V_MAPPED_TS      TIMESTAMP;

    BEGIN
        SELECT 1 INTO V_DUMMY
        FROM T24_CDMEMO_ACTIVITY_ACC_ECB_ARR
        WHERE ROWNUM = 1;

        INSERT INTO TMP_INFLIGHT_RECORD (JOIN_KEY, WINDOW_ID)
        SELECT JOIN_KEY, WINDOW_ID
        FROM 
        (
            SELECT ACC.RECID AS JOIN_KEY, ACC.WINDOW_ID
            FROM T24_CDMEMO_ACTIVITY_ACC_ECB_ARR CDC
            JOIN FMSB_ACC_MAPPED ACC ON ACC.WINDOW_ID = CDC.WINDOW_ID

            UNION ALL

            SELECT ECB.RECID AS JOIN_KEY, ECB.WINDOW_ID
            FROM T24_CDMEMO_ACTIVITY_ACC_ECB_ARR CDC
            JOIN FMSB_ECB_MAPPED ECB ON ECB.WINDOW_ID = CDC.WINDOW_ID

            UNION ALL

            SELECT ARR.LINKED_APPL_ID AS JOIN_KEY, ARR.WINDOW_ID
            FROM T24_CDMEMO_ACTIVITY_ACC_ECB_ARR CDC
            JOIN FMSB_ARR_CD ARR ON ARR.WINDOW_ID = CDC.WINDOW_ID
        );

        SELECT /*+ RESULT_CACHE */ TODAY INTO V_TODAY
        FROM F_DAT_MAPPED
        WHERE RECID = 'VN0011000';

        V_MAPPED_TS := SYSTIMESTAMP;

        INSERT INTO T24_CDMEMO_ACTIVITY (
            ACCTNO, CURTYP, CDNUM, CBAL, HOLD, 
            STATUS, ACCINT, WDRWH, PENAMT, 
            WINDOW_ID, COMMIT_TS, REPLICAT_TS, MAPPED_TS, CALL_CDC
        )
        WITH GROUPED AS (
            SELECT JOIN_KEY
            FROM TMP_INFLIGHT_RECORD
            GROUP BY JOIN_KEY
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
            ACC.WINDOW_ID,
            ACC.COMMIT_TS,
            ACC.REPLICAT_TS,
            V_MAPPED_TS,
            'ACC_ECB_ARR'
        FROM TABLE GROUPED GRP
        JOIN V_FMSB_ACC_MAPPED ACC ON ACC.RECID = GRP.JOIN_KEY
        JOIN V_FMSB_ECB_MAPPED ECB ON ECB.RECID = ACC.RECID
        JOIN V_FMSB_ARR_CD ARR ON ARR.LINKED_APPL_ID = ACC.RECID
        LEFT JOIN F_PST_MAPPED PST ON PST.RECID = ACC.POSTING_RESTRICT;

        DELETE FROM T24_CDMEMO_ACTIVITY_ACC_ECB_ARR CDC
        WHERE EXISTS (
            SELECT 1
            FROM TMP_INFLIGHT_RECORD TMP
            WHERE TMP.WINDOW_ID = CDC.WINDOW_ID
        );

        COMMIT;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN;
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END GEN_FROM_ACC_ECB_ARR_PROC;

END T24_CDMEMO_ACTIVITY_PKG;
