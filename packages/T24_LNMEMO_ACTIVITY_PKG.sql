CREATE OR REPLACE PACKAGE T24RAWOGG.T24_LNMEMO_ACTIVITY_PKG IS

    FUNCTION CALC_CBAL_VAL_FUNC(
        P_CURR_ASSET_TYPE IN VARCHAR2,
        P_OPEN_BALANCE    IN VARCHAR2,
        P_CREDIT_MVMT     IN VARCHAR2,
        P_DEBIT_MVMT      IN VARCHAR2
    ) RETURN NUMBER;

    FUNCTION CALC_HOLD_VAL_FUNC(
        P_LOCKED_AMOUNT IN VARCHAR2
    ) RETURN NUMBER;

    FUNCTION CALC_ACCINT_VAL_FUNC(
        P_CURR_ASSET_TYPE IN VARCHAR2,
        P_OPEN_BALANCE    IN VARCHAR2,
        P_CREDIT_MVMT     IN VARCHAR2,
        P_DEBIT_MVMT      IN VARCHAR2
    ) RETURN NUMBER;

    PROCEDURE GEN_FROM_ACC_ARR_ECB_PROC;
    PROCEDURE GEN_FROM_BIL_PROC;
    PROCEDURE GEN_FROM_LMT_PROC;

END T24_LNMEMO_ACTIVITY_PKG;

CREATE OR REPLACE PACKAGE BODY T24RAWOGG.T24_LNMEMO_ACTIVITY_PKG IS

    ---------------------------------------------------------------------------
    -- CALC_CBAL_VAL_FUNC
    ---------------------------------------------------------------------------
    FUNCTION CALC_CBAL_VAL_FUNC(
        P_CURR_ASSET_TYPE IN VARCHAR2,
        P_OPEN_BALANCE    IN VARCHAR2,
        P_CREDIT_MVMT     IN VARCHAR2,
        P_DEBIT_MVMT      IN VARCHAR2
    ) RETURN NUMBER IS
        V_CBAL            NUMBER      := 0;
        V_START           PLS_INTEGER := 1;
        V_LEN             PLS_INTEGER := LENGTH(P_CURR_ASSET_TYPE);
        V_COLON_IDX       PLS_INTEGER;
        V_HASH_IDX        PLS_INTEGER;
        V_POS             VARCHAR2(6);
        V_CURR_ASSET_TYPE VARCHAR2(255);
    BEGIN
        WHILE V_START <= V_LEN LOOP
            V_COLON_IDX := INSTR(P_CURR_ASSET_TYPE, ':', V_START) + 1;
            V_HASH_IDX  := INSTR(P_CURR_ASSET_TYPE, '#', V_COLON_IDX);
            IF V_HASH_IDX = 0 THEN
                V_HASH_IDX := V_LEN + 1;
            END IF;

            V_POS             := SUBSTR(P_CURR_ASSET_TYPE, V_START, V_COLON_IDX - V_START);
            V_CURR_ASSET_TYPE := SUBSTR(P_CURR_ASSET_TYPE, V_COLON_IDX, V_HASH_IDX - V_COLON_IDX);

            IF V_CURR_ASSET_TYPE IN (
                'CURACCOUNT', 'DUEACCOUNT', 'DELACCOUNT',
                'CURACCOUNTINF', 'DUEACCOUNTINF', 'DELACCOUNTINF'
            ) THEN
                V_CBAL := V_CBAL
                       + T24_UTILS_PKG.GET_NUM_VAL_BY_POS_FUNC(P_OPEN_BALANCE, V_POS)
                       + T24_UTILS_PKG.GET_NUM_VAL_BY_POS_FUNC(P_CREDIT_MVMT, V_POS)
                       + T24_UTILS_PKG.GET_NUM_VAL_BY_POS_FUNC(P_DEBIT_MVMT, V_POS);
            END IF;

            V_START := V_HASH_IDX;
        END LOOP;

        RETURN ABS(V_CBAL);
    END CALC_CBAL_VAL_FUNC;

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
    -- CALC_ACCINT_VAL_FUNC
    ---------------------------------------------------------------------------
    FUNCTION CALC_ACCINT_VAL_FUNC(
        P_CURR_ASSET_TYPE IN VARCHAR2,
        P_OPEN_BALANCE    IN VARCHAR2,
        P_CREDIT_MVMT     IN VARCHAR2,
        P_DEBIT_MVMT      IN VARCHAR2
    ) RETURN NUMBER IS
        V_ACCINT          NUMBER      := 0;
        V_START           PLS_INTEGER := 1;
        V_LEN             PLS_INTEGER := LENGTH(P_CURR_ASSET_TYPE);
        V_COLON_IDX       PLS_INTEGER;
        V_HASH_IDX        PLS_INTEGER;
        V_POS             VARCHAR2(6);
        V_CURR_ASSET_TYPE VARCHAR2(255);
    BEGIN
        WHILE V_START <= V_LEN LOOP
            V_COLON_IDX := INSTR(P_CURR_ASSET_TYPE, ':', V_START) + 1;
            V_HASH_IDX  := INSTR(P_CURR_ASSET_TYPE, '#', V_COLON_IDX);
            IF V_HASH_IDX = 0 THEN
                V_HASH_IDX := V_LEN + 1;
            END IF;

            V_POS             := SUBSTR(P_CURR_ASSET_TYPE, V_START, V_COLON_IDX - V_START);
            V_CURR_ASSET_TYPE := SUBSTR(P_CURR_ASSET_TYPE, V_COLON_IDX, V_HASH_IDX - V_COLON_IDX);

            IF V_CURR_ASSET_TYPE IN (
                'ACCLOANINTEREST', 'ACCLNINTPREBUY', 'ACCINVESTORINT', 'ACCRISKINTEREST', 'ACCLOANINTERESTINF',
                'DUELOANINTEREST', 'DUELNINTPREBUY', 'DUEINVESTORINT', 'DUERISKINTEREST', 'DUELOANINTERESTINF',
                'DELLOANINTEREST', 'DELLNINTPREBUY', 'DELINVESTORINT', 'DELRISKINTEREST', 'DELLOANINTERESTINF'
            ) THEN
                V_ACCINT := V_ACCINT
                         + T24_UTILS_PKG.GET_NUM_VAL_BY_POS_FUNC(P_OPEN_BALANCE, V_POS)
                         + T24_UTILS_PKG.GET_NUM_VAL_BY_POS_FUNC(P_CREDIT_MVMT, V_POS)
                         + T24_UTILS_PKG.GET_NUM_VAL_BY_POS_FUNC(P_DEBIT_MVMT, V_POS);
            END IF;

            V_START := V_HASH_IDX;
        END LOOP;

        RETURN ABS(V_ACCINT);
    END CALC_ACCINT_VAL_FUNC;

    ---------------------------------------------------------------------------
    -- GEN_FROM_ACC_ARR_ECB_PROC
    ---------------------------------------------------------------------------
    PROCEDURE GEN_FROM_ACC_ARR_ECB_PROC IS
        V_JOIN_KEY_LIST  T_JOIN_KEY_ARRAY;
        V_WINDOW_ID_LIST T_WINDOW_ID_ARRAY;
    BEGIN
        SELECT CDC.JOIN_KEY, CDC.WINDOW_ID
        BULK COLLECT INTO V_JOIN_KEY_LIST, V_WINDOW_ID_LIST
        FROM T24_LNMEMO_ACTIVITY_ACC_ARR_ECB CDC
        WHERE EXISTS (
            SELECT 1
            FROM V_FMSB_ECB_MAPPED ECB
            WHERE ECB.WINDOW_ID = CDC.WINDOW_ID
        )
        OR EXISTS (
            SELECT 1
            FROM V_FMSB_ACC_MAPPED ACC
            WHERE ACC.WINDOW_ID = CDC.WINDOW_ID
        )
        OR EXISTS (
            SELECT 1
            FROM V_FMSB_ARR_LNMEMO ARR
            WHERE ARR.WINDOW_ID = CDC.WINDOW_ID
        );
        -- ) FETCH FIRST 9999 ROWS ONLY;

        IF V_JOIN_KEY_LIST.COUNT > 0 THEN
            INSERT INTO T24_LNMEMO_ACTIVITY (
                ACCTNO,
                CURTYP,
                CBAL,
                HOLD,
                DRLIMT,
                ACCINT,
                COMACC,
                OTHCHG,
                BILPRN,
                BILINT,
                BILESC,
                BILLC,
                BILOC,
                BILMC,
                WINDOW_ID,
                COMMIT_TS,
                REPLICAT_TS,
                MAPPED_TS,
                CALL_CDC
            )
            WITH GROUPED AS (
                SELECT DISTINCT COLUMN_VALUE
                FROM TABLE(V_JOIN_KEY_LIST)
            ),
            PRECOMPUTED AS (
                SELECT /*+ MATERIALIZE */
                    ARR.RECID           AS ARR_RECID,
                    ACC.RECID           AS ACCTNO,
                    ACC.CURRENCY        AS CURTYP,
                    ECB.CURR_ASSET_TYPE AS CURR_ASSET_TYPE,
                    ECB.OPEN_BALANCE    AS OPEN_BALANCE,
                    ECB.CREDIT_MVMT     AS CREDIT_MVMT,
                    ECB.DEBIT_MVMT      AS DEBIT_MVMT,
                    ACC.LOCKED_AMOUNT   AS LOCKED_AMOUNT,
                    LMT.INTERNAL_AMOUNT AS DRLIMT,
                    GREATEST(ARR.WINDOW_ID, ACC.WINDOW_ID, ECB.WINDOW_ID)       AS WINDOW_ID,
                    GREATEST(ARR.COMMIT_TS, ACC.COMMIT_TS, ECB.COMMIT_TS)       AS COMMIT_TS,
                    GREATEST(ARR.REPLICAT_TS, ACC.REPLICAT_TS, ECB.REPLICAT_TS) AS REPLICAT_TS,
                    GREATEST(ARR.MAPPED_TS, ACC.MAPPED_TS, ECB.MAPPED_TS)       AS MAPPED_TS
                FROM GROUPED GRP
                INNER JOIN V_FMSB_ARR_LNMEMO ARR ON ARR.LINKED_APPL_ID = GRP.COLUMN_VALUE
                INNER JOIN V_FMSB_ACC_MAPPED ACC ON ACC.RECID          = GRP.COLUMN_VALUE
                INNER JOIN V_FMSB_ECB_MAPPED ECB ON ECB.RECID          = GRP.COLUMN_VALUE
                LEFT  JOIN V_FMSB_LMT_MAPPED LMT ON LMT.RECID          = ACC.LIMIT_KEY
            ),
            AGGREGATED AS (
                SELECT
                    BIL.ARRANGEMENT_ID,
                    SUM(BILPRN_AMT) AS BILPRN,
                    SUM(BILINT_AMT) AS BILINT,
                    SUM(BILLC_AMT)  AS BILLC
                FROM V_FMSB_BIL_LNMEMO BIL
                WHERE EXISTS (
                    SELECT 1
                    FROM PRECOMPUTED PRE
                    WHERE PRE.ARR_RECID = BIL.ARRANGEMENT_ID
                )
                GROUP BY BIL.ARRANGEMENT_ID
            )
            SELECT 
                TO_NUMBER(PRE.ACCTNO), -- ACCTNO
                PRE.CURTYP, -- CURTYP
                CALC_CBAL_VAL_FUNC(PRE.CURR_ASSET_TYPE, PRE.OPEN_BALANCE, PRE.CREDIT_MVMT, PRE.DEBIT_MVMT), -- CBAL
                CALC_HOLD_VAL_FUNC(PRE.LOCKED_AMOUNT), -- HOLD
                NVL(TO_NUMBER(PRE.DRLIMT), 0), -- DRLIMT
                CALC_ACCINT_VAL_FUNC(PRE.CURR_ASSET_TYPE, PRE.OPEN_BALANCE, PRE.CREDIT_MVMT, PRE.DEBIT_MVMT), -- ACCINT
                0, -- COMACC
                0, -- OTHCHG
                NVL(AGG.BILPRN, 0), -- BILPRN
                NVL(AGG.BILINT, 0), -- BILINT
                0, -- BILESC
                NVL(AGG.BILLC, 0), -- BILLC
                0, -- BILOC
                0, -- BILMC
                PRE.WINDOW_ID, -- WINDOW_ID
                PRE.COMMIT_TS, -- COMMIT_TS
                PRE.REPLICAT_TS, -- REPLICAT_TS
                PRE.MAPPED_TS, -- MAPPED_TS
                'ACC_ARR_ECB' -- CALL_CDC
            FROM PRECOMPUTED PRE
            LEFT JOIN AGGREGATED AGG ON AGG.ARRANGEMENT_ID = PRE.ARR_RECID;

            DELETE FROM T24_LNMEMO_ACTIVITY_ACC_ARR_ECB CDC
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

    ---------------------------------------------------------------------------
    -- GEN_FROM_BIL_PROC
    ---------------------------------------------------------------------------
    PROCEDURE GEN_FROM_BIL_PROC IS
        V_JOIN_KEY_LIST  T_JOIN_KEY_ARRAY;
        V_WINDOW_ID_LIST T_WINDOW_ID_ARRAY;
    BEGIN
        SELECT CDC.ARRANGEMENT_ID, CDC.WINDOW_ID
        BULK COLLECT INTO V_JOIN_KEY_LIST, V_WINDOW_ID_LIST
        FROM T24_LNMEMO_ACTIVITY_BIL CDC
        WHERE EXISTS (
            SELECT 1
            FROM V_FMSB_BIL_LNMEMO BIL
            WHERE BIL.WINDOW_ID = CDC.WINDOW_ID 
        );
        -- ) FETCH FIRST 9999 ROWS ONLY;

        IF V_JOIN_KEY_LIST.COUNT > 0 THEN
            INSERT INTO T24_LNMEMO_ACTIVITY (
                ACCTNO,
                CURTYP,
                CBAL,
                HOLD,
                DRLIMT,
                ACCINT,
                COMACC,
                OTHCHG,
                BILPRN,
                BILINT,
                BILESC,
                BILLC,
                BILOC,
                BILMC,
                WINDOW_ID,
                COMMIT_TS,
                REPLICAT_TS,
                MAPPED_TS,
                CALL_CDC
            )
            WITH AGGREGATED AS (
                SELECT
                    BIL.ARRANGEMENT_ID,
                    SUM(BILPRN_AMT)  AS BILPRN,
                    SUM(BILINT_AMT)  AS BILINT,
                    SUM(BILLC_AMT)   AS BILLC,
                    MAX(WINDOW_ID)   AS WINDOW_ID,
                    MAX(COMMIT_TS)   AS COMMIT_TS,
                    MAX(REPLICAT_TS) AS REPLICAT_TS,
                    MAX(MAPPED_TS)   AS MAPPED_TS
                FROM V_FMSB_BIL_LNMEMO BIL
                WHERE EXISTS (
                    SELECT 1
                    FROM TABLE(V_JOIN_KEY_LIST) TMP
                    WHERE TMP.COLUMN_VALUE = BIL.ARRANGEMENT_ID
                )
                GROUP BY BIL.ARRANGEMENT_ID
            )
            SELECT
                TO_NUMBER(ARR.LINKED_APPL_ID), -- ACCTNO
                ACC.CURRENCY, -- CURTYP
                CALC_CBAL_VAL_FUNC(ECB.CURR_ASSET_TYPE, ECB.OPEN_BALANCE, ECB.CREDIT_MVMT, ECB.DEBIT_MVMT), -- CBAL
                CALC_HOLD_VAL_FUNC(ACC.LOCKED_AMOUNT), -- HOLD
                NVL(TO_NUMBER(LMT.INTERNAL_AMOUNT), 0), -- DRLIMT
                CALC_ACCINT_VAL_FUNC(ECB.CURR_ASSET_TYPE, ECB.OPEN_BALANCE, ECB.CREDIT_MVMT, ECB.DEBIT_MVMT), -- ACCINT
                0, -- COMACC
                0, -- OTHCHG
                NVL(AGG.BILPRN, 0), -- BILPRN
                NVL(AGG.BILINT, 0), -- BILINT
                0, -- BILESC
                NVL(AGG.BILLC, 0), -- BILLC
                0, -- BILOC
                0, -- BILMC
                AGG.WINDOW_ID, -- WINDOW_ID
                AGG.COMMIT_TS, -- COMMIT_TS
                AGG.REPLICAT_TS, -- REPLICAT_TS
                AGG.MAPPED_TS, -- MAPPED_TS
                'BIL' -- CALL_CDC
            FROM AGGREGATED AGG
            INNER JOIN V_FMSB_ARR_LNMEMO ARR ON ARR.RECID = AGG.ARRANGEMENT_ID
            INNER JOIN V_FMSB_ACC_MAPPED ACC ON ACC.RECID = ARR.LINKED_APPL_ID
            INNER JOIN V_FMSB_ECB_MAPPED ECB ON ECB.RECID = ACC.RECID
            LEFT  JOIN V_FMSB_LMT_MAPPED LMT ON LMT.RECID = ACC.LIMIT_KEY;

            DELETE FROM T24_LNMEMO_ACTIVITY_BIL CDC
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
    END GEN_FROM_BIL_PROC;

    ---------------------------------------------------------------------------
    -- GEN_FROM_LMT_PROC
    ---------------------------------------------------------------------------
    PROCEDURE GEN_FROM_LMT_PROC IS
        V_WINDOW_ID_LIST T_WINDOW_ID_ARRAY;
    BEGIN
        SELECT CDC.WINDOW_ID
        BULK COLLECT INTO V_WINDOW_ID_LIST
        FROM T24_LNMEMO_ACTIVITY_LMT CDC
        WHERE EXISTS (
            SELECT 1
            FROM V_FMSB_LMT_MAPPED LMT
            WHERE LMT.WINDOW_ID = CDC.WINDOW_ID
        );
        -- ) FETCH FIRST 9999 ROWS ONLY;

        IF V_WINDOW_ID_LIST.COUNT > 0 THEN
            INSERT INTO T24_LNMEMO_ACTIVITY (
                ACCTNO,
                CURTYP,
                CBAL,
                HOLD,
                DRLIMT,
                ACCINT,
                COMACC,
                OTHCHG,
                BILPRN,
                BILINT,
                BILESC,
                BILLC,
                BILOC,
                BILMC,
                WINDOW_ID,
                COMMIT_TS,
                REPLICAT_TS,
                MAPPED_TS,
                CALL_CDC
            )
            WITH PRECOMPUTED AS (
                SELECT /*+ MATERIALIZE */
                    ARR.RECID           AS ARR_RECID,
                    ARR.LINKED_APPL_ID  AS ACCTNO,
                    ACC.CURRENCY        AS CURTYP,
                    ECB.CURR_ASSET_TYPE AS CURR_ASSET_TYPE,
                    ECB.OPEN_BALANCE    AS OPEN_BALANCE,
                    ECB.CREDIT_MVMT     AS CREDIT_MVMT,
                    ECB.DEBIT_MVMT      AS DEBIT_MVMT,
                    ACC.LOCKED_AMOUNT   AS LOCKED_AMOUNT,
                    LMT.INTERNAL_AMOUNT AS DRLIMT,
                    LMT.WINDOW_ID       AS WINDOW_ID,
                    LMT.COMMIT_TS       AS COMMIT_TS,
                    LMT.REPLICAT_TS     AS REPLICAT_TS,
                    LMT.MAPPED_TS       AS MAPPED_TS
                FROM TABLE(V_WINDOW_ID_LIST) TMP
                INNER JOIN V_FMSB_LMT_MAPPED LMT ON LMT.WINDOW_ID      = TMP.COLUMN_VALUE
                INNER JOIN V_FMSB_ACC_MAPPED ACC ON ACC.LIMIT_KEY      = LMT.RECID
                INNER JOIN V_FMSB_ARR_LNMEMO ARR ON ARR.LINKED_APPL_ID = ACC.RECID
                INNER JOIN V_FMSB_ECB_MAPPED ECB ON ECB.RECID          = ACC.RECID
            ),
            AGGREGATED AS (
                SELECT
                    BIL.ARRANGEMENT_ID,
                    SUM(BILPRN_AMT) AS BILPRN,
                    SUM(BILINT_AMT) AS BILINT,
                    SUM(BILLC_AMT)  AS BILLC
                FROM V_FMSB_BIL_LNMEMO BIL
                WHERE EXISTS (
                    SELECT 1
                    FROM PRECOMPUTED PRE
                    WHERE PRE.ARR_RECID = BIL.ARRANGEMENT_ID
                )
                GROUP BY BIL.ARRANGEMENT_ID
            )
            SELECT 
                TO_NUMBER(PRE.ACCTNO), -- ACCTNO
                PRE.CURTYP, -- CURTYP
                CALC_CBAL_VAL_FUNC(PRE.CURR_ASSET_TYPE, PRE.OPEN_BALANCE, PRE.CREDIT_MVMT, PRE.DEBIT_MVMT), -- CBAL
                CALC_HOLD_VAL_FUNC(PRE.LOCKED_AMOUNT), -- HOLD
                NVL(TO_NUMBER(PRE.DRLIMT), 0), -- DRLIMT
                CALC_ACCINT_VAL_FUNC(PRE.CURR_ASSET_TYPE, PRE.OPEN_BALANCE, PRE.CREDIT_MVMT, PRE.DEBIT_MVMT), -- ACCINT
                0, -- COMACC
                0, -- OTHCHG
                NVL(AGG.BILPRN, 0), -- BILPRN
                NVL(AGG.BILINT, 0), -- BILINT
                0, -- BILESC
                NVL(AGG.BILLC, 0), -- BILLC
                0, -- BILOC
                0, -- BILMC
                PRE.WINDOW_ID, -- WINDOW_ID
                PRE.COMMIT_TS, -- COMMIT_TS
                PRE.REPLICAT_TS, -- REPLICAT_TS
                PRE.MAPPED_TS, -- MAPPED_TS
                'LMT' -- CALL_CDC
            FROM PRECOMPUTED PRE
            LEFT JOIN AGGREGATED AGG ON AGG.ARRANGEMENT_ID = PRE.ARR_RECID;

            DELETE FROM T24_LNMEMO_ACTIVITY_LMT CDC
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
    END GEN_FROM_LMT_PROC;

END T24_LNMEMO_ACTIVITY_PKG;
