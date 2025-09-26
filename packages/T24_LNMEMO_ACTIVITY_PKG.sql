CREATE OR REPLACE PACKAGE T24RAWOGG.T24_LNMEMO_ACTIVITY_PKG IS

    FUNCTION CALC_CBAL_VAL_FUNC(
        P_CURR_ASSET_TYPE IN VARCHAR2,
        P_OPEN_BALANCE    IN VARCHAR2,
        P_CREDIT_MVMT     IN VARCHAR2,
        P_DEBIT_MVMT      IN VARCHAR2
    ) RETURN NUMBER;

    FUNCTION CALC_HOLD_VAL_FUNC(
        P_FROM_DATE     IN VARCHAR2,
        P_TODAY         IN VARCHAR2,
        P_LOCKED_AMOUNT IN VARCHAR2
    ) RETURN NUMBER;

    FUNCTION CALC_ACCINT_VAL_FUNC(
        P_CURR_ASSET_TYPE IN VARCHAR2,
        P_OPEN_BALANCE    IN VARCHAR2,
        P_CREDIT_MVMT     IN VARCHAR2,
        P_DEBIT_MVMT      IN VARCHAR2
    ) RETURN NUMBER;

    PROCEDURE GEN_FROM_ACC_PROC;
    PROCEDURE GEN_FROM_ARR_PROC;
    PROCEDURE GEN_FROM_BIL_PROC;
    PROCEDURE GEN_FROM_ECB_PROC;

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
        V_START           PLS_INTEGER := 1;
        V_LEN             PLS_INTEGER := LENGTH(P_CURR_ASSET_TYPE);
        V_COLON_IDX       PLS_INTEGER;
        V_HASH_IDX        PLS_INTEGER;
        V_POS             VARCHAR2(6);
        V_CURR_ASSET_TYPE VARCHAR2(255);
        V_CBAL            NUMBER := 0;
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
        P_FROM_DATE     IN VARCHAR2,
        P_TODAY         IN VARCHAR2,
        P_LOCKED_AMOUNT IN VARCHAR2
    ) RETURN NUMBER IS
        V_HOLD          NUMBER;
        V_PAST          NUMBER;
        V_START         PLS_INTEGER := 1;
        V_LEN           PLS_INTEGER := LENGTH(P_FROM_DATE);
        V_COLON_IDX     PLS_INTEGER;
        V_HASH_IDX      PLS_INTEGER;
        V_POS           VARCHAR2(6);
        V_FROM_DATE     VARCHAR2(8);
        V_LOCKED_AMOUNT NUMBER;
    BEGIN
        IF P_LOCKED_AMOUNT IS NULL THEN
            RETURN 0;
        END IF;

        V_HOLD := TO_NUMBER(T24_UTILS_PKG.GET_LAST_VAL_FUNC(P_LOCKED_AMOUNT));

        WHILE V_START <= V_LEN LOOP
            V_COLON_IDX := INSTR(P_FROM_DATE, ':', V_START) + 1;
            V_HASH_IDX  := INSTR(P_FROM_DATE, '#', V_COLON_IDX);
            IF V_HASH_IDX = 0 THEN
                V_HASH_IDX := V_LEN + 1;
            END IF;

            V_POS           := SUBSTR(P_FROM_DATE, V_START, V_COLON_IDX - V_START);
            V_FROM_DATE     := SUBSTR(P_FROM_DATE, V_COLON_IDX, V_HASH_IDX - V_COLON_IDX);
            V_LOCKED_AMOUNT := T24_UTILS_PKG.GET_NUM_VAL_BY_POS_FUNC(P_LOCKED_AMOUNT, V_POS);

            IF V_FROM_DATE > P_TODAY THEN
                V_HOLD := GREATEST(V_HOLD, V_LOCKED_AMOUNT);
            ELSE
                V_PAST := V_LOCKED_AMOUNT;
            END IF;

            V_START := V_HASH_IDX;
        END LOOP;

        RETURN GREATEST(V_HOLD, NVL(V_PAST, V_HOLD));
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
        V_START           PLS_INTEGER := 1;
        V_LEN             PLS_INTEGER := LENGTH(P_CURR_ASSET_TYPE);
        V_COLON_IDX       PLS_INTEGER;
        V_HASH_IDX        PLS_INTEGER;
        V_POS             VARCHAR2(6);
        V_CURR_ASSET_TYPE VARCHAR2(255);
        V_ACCINT          NUMBER := 0;
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
    -- GEN_FROM_ACC_PROC
    ---------------------------------------------------------------------------
    PROCEDURE GEN_FROM_ACC_PROC IS
        V_WINDOW_ID_LIST T_WINDOW_ID_ARRAY;
        V_TODAY          VARCHAR2(8);
    BEGIN
        SELECT CDC.WINDOW_ID
        BULK COLLECT INTO V_WINDOW_ID_LIST
        FROM T24_LNMEMO_ACTIVITY_ACC CDC
        WHERE EXISTS (
            SELECT 1
            FROM V_FMSB_ACC_MAPPED ACC
            WHERE ACC.RECID = CDC.RECID
            AND CDC.WINDOW_ID <= ACC.WINDOW_ID
        );
        -- ) FETCH FIRST 5000 ROWS ONLY;

        IF V_WINDOW_ID_LIST.COUNT > 0 THEN
            SELECT /*+ RESULT_CACHE */ TODAY INTO V_TODAY
            FROM F_DAT_MAPPED
            WHERE RECID = 'VN0011000';

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
                    ACC.RECID            AS ACCTNO,
                    ARR.RECID            AS ARR_RECID,
                    ACC.CURRENCY         AS CURTYP,
                    ECB.CURR_ASSET_TYPE  AS CURR_ASSET_TYPE,
                    ECB.OPEN_BALANCE     AS OPEN_BALANCE,
                    ECB.CREDIT_MVMT      AS CREDIT_MVMT,
                    ECB.DEBIT_MVMT       AS DEBIT_MVMT,
                    ACC.FROM_DATE        AS FROM_DATE,
                    ACC.LOCKED_AMOUNT    AS LOCKED_AMOUNT,
                    LMT.INTERNAL_AMOUNT  AS DRLIMT,
                    ACC.WINDOW_ID        AS WINDOW_ID,
                    ACC.COMMIT_TS        AS COMMIT_TS,
                    ACC.REPLICAT_TS      AS REPLICAT_TS,
                    ACC.MAPPED_TS        AS MAPPED_TS
                FROM TABLE(V_WINDOW_ID_LIST) V
                INNER JOIN V_FMSB_ACC_MAPPED ACC ON ACC.WINDOW_ID      = V.COLUMN_VALUE
                INNER JOIN V_FMSB_ECB_MAPPED ECB ON ECB.RECID          = ACC.RECID
                INNER JOIN V_FMSB_ARR_LNMEMO ARR ON ARR.LINKED_APPL_ID = ACC.RECID
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
                CALC_HOLD_VAL_FUNC(PRE.FROM_DATE, V_TODAY, PRE.LOCKED_AMOUNT), -- HOLD
                NVL(TO_NUMBER(PRE.DRLIMT), 0), -- DRLIMT
                CALC_ACCINT_VAL_FUNC(PRE.CURR_ASSET_TYPE, PRE.OPEN_BALANCE, PRE.CREDIT_MVMT, PRE.DEBIT_MVMT), -- ACCINT
                0, -- COMACC
                0, -- OTHCHG
                AGG.BILPRN, -- BILPRN
                AGG.BILINT, -- BILINT
                0, -- BILESC
                AGG.BILLC, -- BILLC
                0, -- BILOC
                0, -- BILMC
                PRE.WINDOW_ID, -- WINDOW_ID
                PRE.COMMIT_TS, -- COMMIT_TS
                PRE.REPLICAT_TS, -- REPLICAT_TS
                PRE.MAPPED_TS, -- MAPPED_TS
                'ACC' -- CALL_CDC
            FROM PRECOMPUTED PRE
            LEFT JOIN AGGREGATED AGG ON AGG.ARRANGEMENT_ID = PRE.ARR_RECID;

            DELETE FROM T24_LNMEMO_ACTIVITY_ACC
            WHERE WINDOW_ID MEMBER OF V_WINDOW_ID_LIST;
        END IF;

        COMMIT;
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
        FROM T24_LNMEMO_ACTIVITY_ARR CDC
        WHERE EXISTS (
            SELECT 1
            FROM V_FMSB_ARR_LNMEMO ARR
            WHERE ARR.RECID = CDC.RECID
            AND CDC.WINDOW_ID <= ARR.WINDOW_ID
        );
        -- ) FETCH FIRST 5000 ROWS ONLY;

        IF V_WINDOW_ID_LIST.COUNT > 0 THEN
            SELECT /*+ RESULT_CACHE */ TODAY INTO V_TODAY
            FROM F_DAT_MAPPED
            WHERE RECID = 'VN0011000';

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
                    ARR.LINKED_APPL_ID  AS ACCTNO,
                    ARR.RECID           AS ARR_RECID,
                    ACC.CURRENCY        AS CURTYP,
                    ECB.CURR_ASSET_TYPE AS CURR_ASSET_TYPE,
                    ECB.OPEN_BALANCE    AS OPEN_BALANCE,
                    ECB.CREDIT_MVMT     AS CREDIT_MVMT,
                    ECB.DEBIT_MVMT      AS DEBIT_MVMT,
                    ACC.FROM_DATE       AS FROM_DATE,
                    ACC.LOCKED_AMOUNT   AS LOCKED_AMOUNT,
                    LMT.INTERNAL_AMOUNT AS DRLIMT,
                    ARR.WINDOW_ID       AS WINDOW_ID,
                    ARR.COMMIT_TS       AS COMMIT_TS,
                    ARR.REPLICAT_TS     AS REPLICAT_TS,
                    ARR.MAPPED_TS       AS MAPPED_TS
                FROM TABLE(V_WINDOW_ID_LIST) V
                INNER JOIN V_FMSB_ARR_LNMEMO ARR ON ARR.WINDOW_ID = V.COLUMN_VALUE
                INNER JOIN V_FMSB_ACC_MAPPED ACC ON ACC.RECID     = ARR.LINKED_APPL_ID
                INNER JOIN V_FMSB_ECB_MAPPED ECB ON ECB.RECID     = ARR.LINKED_APPL_ID
                LEFT  JOIN V_FMSB_LMT_MAPPED LMT ON LMT.RECID     = ACC.LIMIT_KEY
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
                CALC_HOLD_VAL_FUNC(PRE.FROM_DATE, V_TODAY, PRE.LOCKED_AMOUNT), -- HOLD
                NVL(TO_NUMBER(PRE.DRLIMT), 0), -- DRLIMT
                CALC_ACCINT_VAL_FUNC(PRE.CURR_ASSET_TYPE, PRE.OPEN_BALANCE, PRE.CREDIT_MVMT, PRE.DEBIT_MVMT), -- ACCINT
                0, -- COMACC
                0, -- OTHCHG
                AGG.BILPRN, -- BILPRN
                AGG.BILINT, -- BILINT
                0, -- BILESC
                AGG.BILLC, -- BILLC
                0, -- BILOC
                0, -- BILMC
                PRE.WINDOW_ID, -- WINDOW_ID
                PRE.COMMIT_TS, -- COMMIT_TS
                PRE.REPLICAT_TS, -- REPLICAT_TS
                PRE.MAPPED_TS, -- MAPPED_TS
                'ARR' -- CALL_CDC
            FROM PRECOMPUTED PRE
            LEFT JOIN AGGREGATED AGG ON AGG.ARRANGEMENT_ID = PRE.ARR_RECID;

            DELETE FROM T24_LNMEMO_ACTIVITY_ARR
            WHERE WINDOW_ID MEMBER OF V_WINDOW_ID_LIST;
        END IF;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END GEN_FROM_ARR_PROC;

    ---------------------------------------------------------------------------
    -- GEN_FROM_BIL_PROC
    ---------------------------------------------------------------------------
    PROCEDURE GEN_FROM_BIL_PROC IS
        V_WINDOW_ID_LIST T_WINDOW_ID_ARRAY;
        V_TODAY          VARCHAR2(8);
    BEGIN
        SELECT CDC.WINDOW_ID
        BULK COLLECT INTO V_WINDOW_ID_LIST
        FROM T24_LNMEMO_ACTIVITY_BIL CDC
        WHERE EXISTS (
            SELECT 1
            FROM V_FMSB_BIL_LNMEMO BIL
            WHERE BIL.RECID = CDC.RECID
            AND CDC.WINDOW_ID <= BIL.WINDOW_ID
        );
        -- ) FETCH FIRST 5000 ROWS ONLY;

        IF V_WINDOW_ID_LIST.COUNT > 0 THEN
            SELECT /*+ RESULT_CACHE */ TODAY INTO V_TODAY
            FROM F_DAT_MAPPED
            WHERE RECID = 'VN0011000';

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
                    ARR.LINKED_APPL_ID  AS ACCTNO,
                    ARR.RECID           AS ARR_RECID,
                    ACC.CURRENCY        AS CURTYP,
                    ECB.CURR_ASSET_TYPE AS CURR_ASSET_TYPE,
                    ECB.OPEN_BALANCE    AS OPEN_BALANCE,
                    ECB.CREDIT_MVMT     AS CREDIT_MVMT,
                    ECB.DEBIT_MVMT      AS DEBIT_MVMT,
                    ACC.FROM_DATE       AS FROM_DATE,
                    ACC.LOCKED_AMOUNT   AS LOCKED_AMOUNT,
                    LMT.INTERNAL_AMOUNT AS DRLIMT,
                    BIL.WINDOW_ID       AS WINDOW_ID,
                    BIL.COMMIT_TS       AS COMMIT_TS,
                    BIL.REPLICAT_TS     AS REPLICAT_TS,
                    BIL.MAPPED_TS       AS MAPPED_TS
                FROM TABLE(V_WINDOW_ID_LIST) V
                INNER JOIN V_FMSB_BIL_LNMEMO BIL ON BIL.WINDOW_ID = V.COLUMN_VALUE
                INNER JOIN V_FMSB_ARR_LNMEMO ARR ON ARR.RECID     = BIL.ARRANGEMENT_ID
                INNER JOIN V_FMSB_ACC_MAPPED ACC ON ACC.RECID     = ARR.LINKED_APPL_ID
                INNER JOIN V_FMSB_ECB_MAPPED ECB ON ECB.RECID     = ACC.RECID
                LEFT  JOIN V_FMSB_LMT_MAPPED LMT ON LMT.RECID     = ACC.LIMIT_KEY
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
                CALC_HOLD_VAL_FUNC(PRE.FROM_DATE, V_TODAY, PRE.LOCKED_AMOUNT), -- HOLD
                NVL(TO_NUMBER(PRE.DRLIMT), 0), -- DRLIMT
                CALC_ACCINT_VAL_FUNC(PRE.CURR_ASSET_TYPE, PRE.OPEN_BALANCE, PRE.CREDIT_MVMT, PRE.DEBIT_MVMT), -- ACCINT
                0, -- COMACC
                0, -- OTHCHG
                AGG.BILPRN, -- BILPRN
                AGG.BILINT, -- BILINT
                0, -- BILESC
                AGG.BILLC, -- BILLC
                0, -- BILOC
                0, -- BILMC
                PRE.WINDOW_ID, -- WINDOW_ID
                PRE.COMMIT_TS, -- COMMIT_TS
                PRE.REPLICAT_TS, -- REPLICAT_TS
                PRE.MAPPED_TS, -- MAPPED_TS
                'BIL' -- CALL_CDC
            FROM PRECOMPUTED PRE
            LEFT JOIN AGGREGATED AGG ON AGG.ARRANGEMENT_ID = PRE.ARR_RECID;

            DELETE FROM T24_LNMEMO_ACTIVITY_BIL
            WHERE WINDOW_ID MEMBER OF V_WINDOW_ID_LIST;
        END IF;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END GEN_FROM_BIL_PROC;

    ---------------------------------------------------------------------------
    -- GEN_FROM_ECB_PROC
    ---------------------------------------------------------------------------
    PROCEDURE GEN_FROM_ECB_PROC IS
        V_WINDOW_ID_LIST T_WINDOW_ID_ARRAY;
        V_TODAY          VARCHAR2(8);
    BEGIN
        SELECT CDC.WINDOW_ID
        BULK COLLECT INTO V_WINDOW_ID_LIST
        FROM T24_LNMEMO_ACTIVITY_ECB CDC
        WHERE EXISTS (
            SELECT 1
            FROM V_FMSB_ECB_MAPPED ECB
            WHERE ECB.RECID = CDC.RECID
            AND CDC.WINDOW_ID <= ECB.WINDOW_ID
        );
        -- ) FETCH FIRST 5000 ROWS ONLY;

        IF V_WINDOW_ID_LIST.COUNT > 0 THEN
            SELECT /*+ RESULT_CACHE */ TODAY INTO V_TODAY
            FROM F_DAT_MAPPED
            WHERE RECID = 'VN0011000';

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
                    ECB.RECID            AS ACCTNO,
                    ARR.RECID            AS ARR_RECID,
                    ACC.CURRENCY         AS CURTYP,
                    ECB.CURR_ASSET_TYPE  AS CURR_ASSET_TYPE,
                    ECB.OPEN_BALANCE     AS OPEN_BALANCE,
                    ECB.CREDIT_MVMT      AS CREDIT_MVMT,
                    ECB.DEBIT_MVMT       AS DEBIT_MVMT,
                    ACC.FROM_DATE        AS FROM_DATE,
                    ACC.LOCKED_AMOUNT    AS LOCKED_AMOUNT,
                    LMT.INTERNAL_AMOUNT  AS DRLIMT,
                    ECB.WINDOW_ID        AS WINDOW_ID,
                    ECB.COMMIT_TS        AS COMMIT_TS,
                    ECB.REPLICAT_TS      AS REPLICAT_TS,
                    ECB.MAPPED_TS        AS MAPPED_TS
                FROM TABLE(V_WINDOW_ID_LIST) V
                INNER JOIN V_FMSB_ECB_MAPPED ECB ON ECB.WINDOW_ID      = V.COLUMN_VALUE
                INNER JOIN V_FMSB_ACC_MAPPED ACC ON ACC.RECID          = ECB.RECID
                INNER JOIN V_FMSB_ARR_LNMEMO ARR ON ARR.LINKED_APPL_ID = ECB.RECID
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
                CALC_HOLD_VAL_FUNC(PRE.FROM_DATE, V_TODAY, PRE.LOCKED_AMOUNT), -- HOLD
                NVL(TO_NUMBER(PRE.DRLIMT), 0), -- DRLIMT
                CALC_ACCINT_VAL_FUNC(PRE.CURR_ASSET_TYPE, PRE.OPEN_BALANCE, PRE.CREDIT_MVMT, PRE.DEBIT_MVMT), -- ACCINT
                0, -- COMACC
                0, -- OTHCHG
                AGG.BILPRN, -- BILPRN
                AGG.BILINT, -- BILINT
                0, -- BILESC
                AGG.BILLC, -- BILLC
                0, -- BILOC
                0, -- BILMC
                PRE.WINDOW_ID, -- WINDOW_ID
                PRE.COMMIT_TS, -- COMMIT_TS
                PRE.REPLICAT_TS, -- REPLICAT_TS
                PRE.MAPPED_TS, -- MAPPED_TS
                'ECB' -- CALL_CDC
            FROM PRECOMPUTED PRE
            LEFT JOIN AGGREGATED AGG ON AGG.ARRANGEMENT_ID = PRE.ARR_RECID;

            DELETE FROM T24_LNMEMO_ACTIVITY_ECB
            WHERE WINDOW_ID MEMBER OF V_WINDOW_ID_LIST;
        END IF;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END GEN_FROM_ECB_PROC;

END T24_LNMEMO_ACTIVITY_PKG;
