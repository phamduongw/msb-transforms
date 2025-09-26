CREATE OR REPLACE PACKAGE T24_DDMEMO_ACTIVITY_PKG IS

    FUNCTION CALC_HOLD_VAL_FUNC(
        P_FROM_DATE     IN VARCHAR2,
        P_TODAY         IN VARCHAR2,
        P_LOCKED_AMOUNT IN VARCHAR2
    ) RETURN NUMBER;

    FUNCTION CALC_CBAL_VAL_FUNC(
        P_CURR_ASSET_TYPE IN VARCHAR2,
        P_OPEN_BALANCE    IN VARCHAR2,
        P_CREDIT_MVMT     IN VARCHAR2,
        P_DEBIT_MVMT      IN VARCHAR2
    ) RETURN NUMBER;

    FUNCTION CALC_ACCRUE_VAL_FUNC(
        P_CURR_ASSET_TYPE IN VARCHAR2,
        P_OPEN_BALANCE    IN VARCHAR2,
        P_CREDIT_MVMT     IN VARCHAR2,
        P_DEBIT_MVMT      IN VARCHAR2
    ) RETURN NUMBER;

    PROCEDURE GEN_FROM_ACC_PROC;

    PROCEDURE GEN_FROM_ARR_PROC;

    PROCEDURE GEN_FROM_ECB_PROC;

    PROCEDURE GEN_FROM_ADL_PROC;

    PROCEDURE GEN_FROM_LMT_PROC;

END T24_DDMEMO_ACTIVITY_PKG;

CREATE OR REPLACE PACKAGE BODY T24_DDMEMO_ACTIVITY_PKG IS

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
        V_M_VAL         VARCHAR2(6);
        V_FROM_DATE     VARCHAR2(8);
        V_LOCKED_AMOUNT NUMBER;
    BEGIN
        IF P_LOCKED_AMOUNT IS NULL THEN
            RETURN 0;
        END IF;

        V_HOLD := T24_UTILS_PKG.GET_LAST_VAL_FUNC(P_LOCKED_AMOUNT);

        WHILE V_START <= V_LEN LOOP
            V_COLON_IDX := INSTR(P_FROM_DATE, ':', V_START) + 1;
            V_HASH_IDX  := INSTR(P_FROM_DATE, '#', V_COLON_IDX);

            IF V_HASH_IDX = 0 THEN
                V_HASH_IDX := V_LEN + 1;
            END IF;

            V_M_VAL         := SUBSTR(P_FROM_DATE, V_START, V_COLON_IDX - V_START);
            V_FROM_DATE     := SUBSTR(P_FROM_DATE, V_COLON_IDX, V_HASH_IDX - V_COLON_IDX);
            V_LOCKED_AMOUNT := T24_UTILS_PKG.GET_NUM_VAL_BY_POS_FUNC(P_LOCKED_AMOUNT, V_M_VAL);

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
-- CALC_ACCRUE_VAL_FUNC
---------------------------------------------------------------------------
    FUNCTION CALC_ACCRUE_VAL_FUNC(
        P_CURR_ASSET_TYPE IN VARCHAR2,
        P_OPEN_BALANCE    IN VARCHAR2,
        P_CREDIT_MVMT     IN VARCHAR2,
        P_DEBIT_MVMT      IN VARCHAR2
    ) RETURN NUMBER IS
        V_ACCRUE            NUMBER := 0;
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

            IF V_CURR_ASSET_TYPE IN (
                'ACCCRINTEREST', 'ACCODCREDITINT', 'PAYCRINTEREST', 'DUEODCREDITINT'
            ) THEN
                V_ACCRUE := V_ACCRUE
                    + T24_UTILS_PKG.GET_NUM_VAL_BY_POS_FUNC(P_OPEN_BALANCE, V_M_VAL)
                    + T24_UTILS_PKG.GET_NUM_VAL_BY_POS_FUNC(P_CREDIT_MVMT, V_M_VAL)
                    + T24_UTILS_PKG.GET_NUM_VAL_BY_POS_FUNC(P_DEBIT_MVMT, V_M_VAL);
            END IF;

            V_START := V_HASH_IDX;
        END LOOP;

        RETURN ABS(V_ACCRUE);
    END CALC_ACCRUE_VAL_FUNC;

---------------------------------------------------------------------------
-- CALC_SCCODE_VAL_FUNC
---------------------------------------------------------------------------
    FUNCTION CALC_SCCODE_VAL_FUNC(
        P_PRODUCT_STATUS IN VARCHAR2,
        P_PRODUCT        IN VARCHAR2
    ) RETURN VARCHAR2 IS
        V_SCCODE           VARCHAR2(30);
        V_START            PLS_INTEGER := 1;
        V_LEN              PLS_INTEGER := LENGTH(P_PRODUCT_STATUS);
        V_COLON_IDX        PLS_INTEGER;
        V_HASH_IDX         PLS_INTEGER;
        V_POS              VARCHAR2(6);
        V_PRODUCT_STATUS   VARCHAR2(255);
    BEGIN
        IF P_PRODUCT_STATUS IS NULL THEN
            RETURN 0;
        END IF;

        WHILE V_START <= V_LEN LOOP
            V_COLON_IDX := INSTR(P_PRODUCT_STATUS, ':', V_START) + 1;
            V_HASH_IDX  := INSTR(P_PRODUCT_STATUS, '#', V_COLON_IDX);

            IF V_HASH_IDX = 0 THEN
                V_HASH_IDX := V_LEN + 1;
            END IF;

            V_POS            := SUBSTR(P_PRODUCT_STATUS, V_START, V_COLON_IDX - V_START);
            V_PRODUCT_STATUS := SUBSTR(P_PRODUCT_STATUS, V_COLON_IDX, V_HASH_IDX - V_COLON_IDX);

            IF V_PRODUCT_STATUS = 'CURRENT'
             THEN
                V_SCCODE :=  T24_UTILS_PKG.GET_STR_VAL_BY_POS_FUNC(P_PRODUCT, V_POS);
            END IF;

            V_START := V_HASH_IDX;
        END LOOP;

        RETURN V_SCCODE;
    END CALC_TYPE_VAL_FUNC;

---------------------------------------------------------------------------
-- GEN_FROM_ACC_PROC
---------------------------------------------------------------------------
    PROCEDURE GEN_FROM_ACC_PROC IS
        V_WINDOW_ID_LIST T_WINDOW_ID_ARRAY;
        V_TODAY          VARCHAR2(8);
    BEGIN
        SELECT CDC.WINDOW_ID
        BULK COLLECT INTO V_WINDOW_ID_LIST
        FROM T24_DDMEMO_ACTIVITY_ACC CDC
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

            INSERT INTO T24_DDMEMO_ACTIVITY (
                BRANCH, ACCTNO, ACNAME, CIFNO, STATUS, SCCODE,
                DLA7, DLA6, HOLD, CBAL, ACCRUE, ODLIMT,
                WINDOW_ID, COMMIT_TS, REPLICAT_TS, MAPPED_TS, CALL_CDC
            )
            WITH PRECOMPUTED AS(
                SELECT /*+ MATERIALIZE */
                    ACC.CO_CODE          AS BRANCH,
                    ACC.RECID            AS ACCTNO,
                    ARR.RECID            AS ARR_RECID,
                    ACC.ACNAME           AS ACNAME,
                    ACC.CUSTOMER         AS CIFNO,
                    ARR.ARR_STATUS       AS ARR_STATUS,
                    PST.RESTRICTION_TYPE AS RESTRICTION_TYPE,
                    ADL.DORMANCY_STATUS  AS DORMANCY_STATUS,
                    ARR.START_DATE       AS START_DATE,
                    ARR.PRODUCT          AS PRODUCT,
                    ARR.PRODUCT_STATUS   AS PRODUCT_STATUS,
                    ACC.LOCKED_AMOUNT    AS LOCKED_AMOUNT,
                    ACC.FROM_DATE        AS FROM_DATE,
                    ECB.CURR_ASSET_TYPE  AS CURR_ASSET_TYPE,
                    ECB.OPEN_BALANCE     AS OPEN_BALANCE,
                    ECB.CREDIT_MVMT      AS CREDIT_MVMT,
                    ECB.DEBIT_MVMT       AS DEBIT_MVMT,
                    LMT.INTERNAL_AMOUNT  AS INTERNAL_AMOUNT,
                    ACC.WINDOW_ID        AS WINDOW_ID,
                    ACC.COMMIT_TS        AS COMMIT_TS,
                    ACC.REPLICAT_TS      AS REPLICAT_TS,
                    ACC.MAPPED_TS        AS MAPPED_TS
                FROM TABLE(V_WINDOW_ID_LIST) V
                JOIN V_FMSB_ACC_MAPPED ACC ON ACC.WINDOW_ID = V.COLUMN_VALUE
                JOIN V_FMSB_ARR_DD ARR ON ARR.LINKED_APPL_ID = ACC.RECID
                JOIN V_FMSB_ECB_MAPPED ECB ON ECB.RECID = ACC.RECID
                JOIN V_FMSB_ADL_MAPPED ADL ON ADL.RECID = ARR.RECID
                JOIN V_FMSB_LMT_MAPPED LMT ON LMT.RECID = ACC.LIMIT_KEY
                LEFT JOIN V_F_PST_MAPPED PST ON PST.RECID = ACC.POSTING_RESTRICT                
            ),
            AGGREGATED AS (
                SELECT 
                    ARRANGEMENT,
                    MAX(EFFECTIVE_RATE) AS MAX_EFF_DAT
                FROM V_FMSB_ARC_DDMEMO ARC
                WHERE EXISTS (
                    SELECT 1 FROM PRECOMPUTED PRE
                    WHERE PRE.ARR_RECID = ARC.ARRANGEMENT)
                GROUP BY ARRANGEMENT
            )
            SELECT
                PRE.BRANCH,
                TO_NUMBER(PRE.ACCTNO),
                TRIM(PRE.ACNAME),
                TO_NUMBER(PRE.CUSTOMER),
                CASE
                    WHEN PRE.ARR_STATUS IN ('CLOSE', 'PENDING.CLOSURE', 'CANCELLED') THEN 2
                    WHEN PRE.RESTRICTION_TYPE = 'DEBIT' THEN 6
                    WHEN PRE.RESTRICTION_TYPE = 'ALL' THEN 7
                    WHEN PRE.DORMANCY_STATUS IS NOT NULL THEN 9
                    WHEN PRE.START_DATE = TO_DATE(V_TODAY,'YYYYMMDD') AND ARR.ARR_STATUS NOT IN ('CLOSE', 'PENDING.CLOSURE') THEN 4
                    WHEN PRE.ARR_STATUS IN ('AUTH', 'RESTORE-AUTH') AND ADL.DORMANCY_STATUS IS NULL THEN 1
                END,
                CALC_SCCODE_VAL_FUNC(PRE.PRODUCT_STATUS, PRE.PRODUCT),
                TO_NUMBER(TO_CHAR(AGG.MAX_EFF_DAT, 'YYYYDDD'))
                TO_NUMBER(TO_CHAR(AGG.MAX_EFF_DAT, 'DDMMYY')),
                CALC_HOLD_VAL_FUNC(PRE.FROM_DATE, V_TODAY, PRE.LOCKED_AMOUNT),
                CALC_CBAL_VAL_FUNC(PRE.CURR_ASSET_TYPE, PRE.OPEN_BALANCE, PRE.CREDIT_MVMT, PRE.DEBIT_MVMT),
                CALC_ACCRUE_VAL_FUNC(PRE.CURR_ASSET_TYPE, PRE.OPEN_BALANCE, PRE.CREDIT_MVMT, PRE.DEBIT_MVMT),
                TO_NUMBER(PRE.INTERNAL_AMOUNT),
                PRE.WINDOW_ID,
                PRE.COMMIT_TS,
                PRE.REPLICAT_TS,
                PRE.MAPPED_TS,
                'ACC'
            FROM PRECOMPUTED PRE
            LEFT JOIN AGGREGATED AGG ON AGG.ARRANGEMENT = PRE.ARR_RECID

            DELETE FROM T24_DDMEMO_ACTIVITY_ACC
            WHERE WINDOW_ID MEMBER OF V_WINDOW_ID_LIST;
        END IF;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END GEN_FROM_ACC_PROC;

---------------------------------------------------------------------------
-- GEN_FROM_ECB_PROC
---------------------------------------------------------------------------
    PROCEDURE GEN_FROM_ECB_PROC IS
        V_WINDOW_ID_LIST T_WINDOW_ID_ARRAY;
        V_TODAY          VARCHAR2(8);
    BEGIN
        SELECT CDC.WINDOW_ID
        BULK COLLECT INTO V_WINDOW_ID_LIST
        FROM T24_DDMEMO_ACTIVITY_ECB CDC
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

            INSERT INTO T24_DDMEMO_ACTIVITY (
                BRANCH, ACCTNO, ACNAME, CIFNO, STATUS, SCCODE,
                DLA7, DLA6, HOLD, CBAL, ACCRUE, ODLIMT,
                WINDOW_ID, COMMIT_TS, REPLICAT_TS, MAPPED_TS, CALL_CDC
            )
            WITH PRECOMPUTED AS(
                SELECT /*+ MATERIALIZE */
                    ACC.CO_CODE          AS BRANCH,
                    ECB.RECID            AS ACCTNO,
                    ARR.RECID            AS ARR_RECID,
                    ACC.ACNAME           AS ACNAME,
                    ACC.CUSTOMER         AS CIFNO,
                    ARR.ARR_STATUS       AS ARR_STATUS,
                    PST.RESTRICTION_TYPE AS RESTRICTION_TYPE,
                    ADL.DORMANCY_STATUS  AS DORMANCY_STATUS,
                    ARR.START_DATE       AS START_DATE,
                    ARR.PRODUCT          AS PRODUCT,
                    ARR.PRODUCT_STATUS   AS PRODUCT_STATUS,
                    ACC.LOCKED_AMOUNT    AS LOCKED_AMOUNT,
                    ACC.FROM_DATE        AS FROM_DATE,
                    ECB.CURR_ASSET_TYPE  AS CURR_ASSET_TYPE,
                    ECB.OPEN_BALANCE     AS OPEN_BALANCE,
                    ECB.CREDIT_MVMT      AS CREDIT_MVMT,
                    ECB.DEBIT_MVMT       AS DEBIT_MVMT,
                    LMT.INTERNAL_AMOUNT  AS INTERNAL_AMOUNT,
                    ECB.WINDOW_ID        AS WINDOW_ID,
                    ECB.COMMIT_TS        AS COMMIT_TS,
                    ECB.REPLICAT_TS      AS REPLICAT_TS,
                    ECB.MAPPED_TS        AS MAPPED_TS
                FROM TABLE(V_WINDOW_ID_LIST) V
                JOIN V_FMSB_ECB_MAPPED ECB ON ECB.WINDOW_ID = V.COLUMN_VALUE
                JOIN V_FMSB_ACC_MAPPED ACC ON ACC.RECID = ECB.RECID
                JOIN V_FMSB_ARR_DD ARR ON ARR.LINKED_APPL_ID = ECB.RECID
                JOIN V_FMSB_ADL_MAPPED ADL ON ADL.RECID = ARR.RECID
                JOIN V_FMSB_LMT_MAPPED LMT ON LMT.RECID = ACC.LIMIT_KEY
                LEFT JOIN V_F_PST_MAPPED PST ON PST.RECID = ACC.POSTING_RESTRICT               
            ),
            AGGREGATED AS (
                SELECT 
                    ARRANGEMENT,
                    MAX(EFFECTIVE_RATE) AS MAX_EFF_DAT
                FROM V_FMSB_ARC_DDMEMO ARC
                WHERE EXISTS (
                    SELECT 1 FROM PRECOMPUTED PRE
                    WHERE PRE.ARR_RECID = ARC.ARRANGEMENT)
                GROUP BY ARRANGEMENT
            )
            SELECT
                PRE.BRANCH,
                TO_NUMBER(PRE.ACCTNO),
                TRIM(PRE.ACNAME),
                TO_NUMBER(PRE.CUSTOMER),
                CASE
                    WHEN PRE.ARR_STATUS IN ('CLOSE', 'PENDING.CLOSURE', 'CANCELLED') THEN 2
                    WHEN PRE.RESTRICTION_TYPE = 'DEBIT' THEN 6
                    WHEN PRE.RESTRICTION_TYPE = 'ALL' THEN 7
                    WHEN PRE.DORMANCY_STATUS IS NOT NULL THEN 9
                    WHEN PRE.START_DATE = TO_DATE(V_TODAY,'YYYYMMDD') AND ARR.ARR_STATUS NOT IN ('CLOSE', 'PENDING.CLOSURE') THEN 4
                    WHEN PRE.ARR_STATUS IN ('AUTH', 'RESTORE-AUTH') AND ADL.DORMANCY_STATUS IS NULL THEN 1
                END,
                CALC_SCCODE_VAL_FUNC(PRE.PRODUCT_STATUS, PRE.PRODUCT),
                TO_NUMBER(TO_CHAR(AGG.MAX_EFF_DAT, 'YYYYDDD'))
                TO_NUMBER(TO_CHAR(AGG.MAX_EFF_DAT, 'DDMMYY')),
                CALC_HOLD_VAL_FUNC(PRE.FROM_DATE, V_TODAY, PRE.LOCKED_AMOUNT),
                CALC_CBAL_VAL_FUNC(PRE.CURR_ASSET_TYPE, PRE.OPEN_BALANCE, PRE.CREDIT_MVMT, PRE.DEBIT_MVMT),
                CALC_ACCRUE_VAL_FUNC(PRE.CURR_ASSET_TYPE, PRE.OPEN_BALANCE, PRE.CREDIT_MVMT, PRE.DEBIT_MVMT),
                TO_NUMBER(PRE.INTERNAL_AMOUNT),
                PRE.WINDOW_ID,
                PRE.COMMIT_TS,
                PRE.REPLICAT_TS,
                PRE.MAPPED_TS,
                'ECB'
            FROM PRECOMPUTED PRE
            LEFT JOIN AGGREGATED AGG ON AGG.ARRANGEMENT = PRE.ARR_RECID

            DELETE FROM T24_DDMEMO_ACTIVITY_ECB
            WHERE WINDOW_ID MEMBER OF V_WINDOW_ID_LIST;
        END IF;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END GEN_FROM_ECB_PROC;

---------------------------------------------------------------------------
-- GEN_FROM_ARR_PROC
---------------------------------------------------------------------------
    PROCEDURE GEN_FROM_ARR_PROC IS
        V_WINDOW_ID_LIST T_WINDOW_ID_ARRAY;
        V_TODAY          VARCHAR2(8);
    BEGIN
        SELECT CDC.WINDOW_ID
        BULK COLLECT INTO V_WINDOW_ID_LIST
        FROM T24_DDMEMO_ACTIVITY_ARR CDC
        WHERE EXISTS (
            SELECT 1
            FROM V_FMSB_ARR_DD ARR
            WHERE ARR.RECID = CDC.RECID
            AND CDC.WINDOW_ID <= ARR.WINDOW_ID
        );
        -- ) FETCH FIRST 5000 ROWS ONLY;

        IF V_WINDOW_ID_LIST.COUNT > 0 THEN
            SELECT /*+ RESULT_CACHE */ TODAY INTO V_TODAY
            FROM F_DAT_MAPPED
            WHERE RECID = 'VN0011000';

            INSERT INTO T24_DDMEMO_ACTIVITY (
                BRANCH, ACCTNO, ACNAME, CIFNO, STATUS, SCCODE,
                DLA7, DLA6, HOLD, CBAL, ACCRUE, ODLIMT,
                WINDOW_ID, COMMIT_TS, REPLICAT_TS, MAPPED_TS, CALL_CDC
            )
            WITH PRECOMPUTED AS(
                SELECT /*+ MATERIALIZE */
                    ACC.CO_CODE          AS BRANCH,
                    ARR.LINKED_APPL_ID   AS ACCTNO,
                    ARR.RECID            AS ARR_RECID,
                    ACC.ACNAME           AS ACNAME,
                    ACC.CUSTOMER         AS CIFNO,
                    ARR.ARR_STATUS       AS ARR_STATUS,
                    PST.RESTRICTION_TYPE AS RESTRICTION_TYPE,
                    ADL.DORMANCY_STATUS  AS DORMANCY_STATUS,
                    ARR.START_DATE       AS START_DATE,
                    ARR.PRODUCT          AS PRODUCT,
                    ARR.PRODUCT_STATUS   AS PRODUCT_STATUS,
                    ACC.LOCKED_AMOUNT    AS LOCKED_AMOUNT,
                    ACC.FROM_DATE        AS FROM_DATE,
                    ECB.CURR_ASSET_TYPE  AS CURR_ASSET_TYPE,
                    ECB.OPEN_BALANCE     AS OPEN_BALANCE,
                    ECB.CREDIT_MVMT      AS CREDIT_MVMT,
                    ECB.DEBIT_MVMT       AS DEBIT_MVMT,
                    LMT.INTERNAL_AMOUNT  AS INTERNAL_AMOUNT,
                    ARR.WINDOW_ID        AS WINDOW_ID,
                    ARR.COMMIT_TS        AS COMMIT_TS,
                    ARR.REPLICAT_TS      AS REPLICAT_TS,
                    ARR.MAPPED_TS        AS MAPPED_TS
                FROM TABLE(V_WINDOW_ID_LIST) V
                JOIN V_FMSB_ARR_DD ARR ON ARR.WINDOW_ID = V.COLUMN_VALUE
                JOIN V_FMSB_ACC_MAPPED ACC ON ACC.RECID = ARR.LINKED_APPL_ID
                JOIN V_FMSB_ECB_MAPPED ECB ON ECB.RECID = ARR.LINKED_APPL_ID
                JOIN V_FMSB_ADL_MAPPED ADL ON ADL.RECID = ARR.RECID
                JOIN V_FMSB_LMT_MAPPED LMT ON LMT.RECID = ACC.LIMIT_KEY
                LEFT JOIN V_F_PST_MAPPED PST ON PST.RECID = ACC.POSTING_RESTRICT               
            ),
            AGGREGATED AS (
                SELECT 
                    ARRANGEMENT,
                    MAX(EFFECTIVE_RATE) AS MAX_EFF_DAT
                FROM V_FMSB_ARC_DDMEMO ARC
                WHERE EXISTS (
                    SELECT 1 FROM PRECOMPUTED PRE
                    WHERE PRE.ARR_RECID = ARC.ARRANGEMENT)
                GROUP BY ARRANGEMENT
            )
            SELECT
                PRE.BRANCH,
                TO_NUMBER(PRE.ACCTNO),
                TRIM(PRE.ACNAME),
                TO_NUMBER(PRE.CUSTOMER),
                CASE
                    WHEN PRE.ARR_STATUS IN ('CLOSE', 'PENDING.CLOSURE', 'CANCELLED') THEN 2
                    WHEN PRE.RESTRICTION_TYPE = 'DEBIT' THEN 6
                    WHEN PRE.RESTRICTION_TYPE = 'ALL' THEN 7
                    WHEN PRE.DORMANCY_STATUS IS NOT NULL THEN 9
                    WHEN PRE.START_DATE = TO_DATE(V_TODAY,'YYYYMMDD') AND ARR.ARR_STATUS NOT IN ('CLOSE', 'PENDING.CLOSURE') THEN 4
                    WHEN PRE.ARR_STATUS IN ('AUTH', 'RESTORE-AUTH') AND ADL.DORMANCY_STATUS IS NULL THEN 1
                END,
                CALC_SCCODE_VAL_FUNC(PRE.PRODUCT_STATUS, PRE.PRODUCT),
                TO_NUMBER(TO_CHAR(AGG.MAX_EFF_DAT, 'YYYYDDD'))
                TO_NUMBER(TO_CHAR(AGG.MAX_EFF_DAT, 'DDMMYY')),
                CALC_HOLD_VAL_FUNC(PRE.FROM_DATE, V_TODAY, PRE.LOCKED_AMOUNT),
                CALC_CBAL_VAL_FUNC(PRE.CURR_ASSET_TYPE, PRE.OPEN_BALANCE, PRE.CREDIT_MVMT, PRE.DEBIT_MVMT),
                CALC_ACCRUE_VAL_FUNC(PRE.CURR_ASSET_TYPE, PRE.OPEN_BALANCE, PRE.CREDIT_MVMT, PRE.DEBIT_MVMT),
                TO_NUMBER(PRE.INTERNAL_AMOUNT),
                PRE.WINDOW_ID,
                PRE.COMMIT_TS,
                PRE.REPLICAT_TS,
                PRE.MAPPED_TS,
                'ARR'
            FROM PRECOMPUTED PRE
            LEFT JOIN AGGREGATED AGG ON AGG.ARRANGEMENT = PRE.ARR_RECID

            DELETE FROM T24_DDMEMO_ACTIVITY_ARR
            WHERE WINDOW_ID MEMBER OF V_WINDOW_ID_LIST;
        END IF;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END GEN_FROM_ARR_PROC;

---------------------------------------------------------------------------
-- GEN_FROM_LMT_PROC
---------------------------------------------------------------------------
    PROCEDURE GEN_FROM_LMT_PROC IS
        V_WINDOW_ID_LIST T_WINDOW_ID_ARRAY;
        V_TODAY          VARCHAR2(8);
    BEGIN
        SELECT CDC.WINDOW_ID
        BULK COLLECT INTO V_WINDOW_ID_LIST
        FROM T24_DDMEMO_ACTIVITY_LMT CDC
        WHERE EXISTS (
            SELECT 1
            FROM V_FMSB_LMT_MAPPED LMT
            WHERE LME.RECID = CDC.RECID
            AND CDC.WINDOW_ID <= LMT.WINDOW_ID
        );
        -- ) FETCH FIRST 5000 ROWS ONLY;

        IF V_WINDOW_ID_LIST.COUNT > 0 THEN
            SELECT /*+ RESULT_CACHE */ TODAY INTO V_TODAY
            FROM F_DAT_MAPPED
            WHERE RECID = 'VN0011000';

            INSERT INTO T24_DDMEMO_ACTIVITY (
                BRANCH, ACCTNO, ACNAME, CIFNO, STATUS, SCCODE,
                DLA7, DLA6, HOLD, CBAL, ACCRUE, ODLIMT,
                WINDOW_ID, COMMIT_TS, REPLICAT_TS, MAPPED_TS, CALL_CDC
            )
            WITH PRECOMPUTED AS(
                SELECT /*+ MATERIALIZE */
                    ACC.CO_CODE          AS BRANCH,
                    ACC.RECID            AS ACCTNO,
                    ARR.RECID            AS ARR_RECID,
                    ACC.ACNAME           AS ACNAME,
                    ACC.CUSTOMER         AS CIFNO,
                    ARR.ARR_STATUS       AS ARR_STATUS,
                    PST.RESTRICTION_TYPE AS RESTRICTION_TYPE,
                    ADL.DORMANCY_STATUS  AS DORMANCY_STATUS,
                    ARR.START_DATE       AS START_DATE,
                    ARR.PRODUCT          AS PRODUCT,
                    ARR.PRODUCT_STATUS   AS PRODUCT_STATUS,
                    ACC.LOCKED_AMOUNT    AS LOCKED_AMOUNT,
                    ACC.FROM_DATE        AS FROM_DATE,
                    ECB.CURR_ASSET_TYPE  AS CURR_ASSET_TYPE,
                    ECB.OPEN_BALANCE     AS OPEN_BALANCE,
                    ECB.CREDIT_MVMT      AS CREDIT_MVMT,
                    ECB.DEBIT_MVMT       AS DEBIT_MVMT,
                    LMT.INTERNAL_AMOUNT  AS INTERNAL_AMOUNT,
                    LMT.WINDOW_ID        AS WINDOW_ID,
                    LMT.COMMIT_TS        AS COMMIT_TS,
                    LMT.REPLICAT_TS      AS REPLICAT_TS,
                    LMT.MAPPED_TS        AS MAPPED_TS
                FROM TABLE(V_WINDOW_ID_LIST) V
                JOIN V_FMSB_LMT_MAPPED LMT ON LMT.WINDOW_ID = V.COLUMN_VALUE
                JOIN V_FMSB_ACC_MAPPED ACC ON ACC.LIMIT_KEY = LMT.RECID
                JOIN V_FMSB_ARR_DD ARR ON ARR.LINKED_APPL_ID = ACC.RECID
                JOIN V_FMSB_ECB_MAPPED ECB ON ECB.RECID = ACC.RECID
                JOIN V_FMSB_ADL_MAPPED ADL ON ADL.RECID = ARR.RECID
                LEFT JOIN V_F_PST_MAPPED PST ON PST.RECID = ACC.POSTING_RESTRICT               
            ),
            AGGREGATED AS (
                SELECT 
                    ARRANGEMENT,
                    MAX(EFFECTIVE_RATE) AS MAX_EFF_DAT
                FROM V_FMSB_ARC_DDMEMO ARC
                WHERE EXISTS (
                    SELECT 1 FROM PRECOMPUTED PRE
                    WHERE PRE.ARR_RECID = ARC.ARRANGEMENT)
                GROUP BY ARRANGEMENT
            )
            SELECT
                PRE.BRANCH,
                TO_NUMBER(PRE.ACCTNO),
                TRIM(PRE.ACNAME),
                TO_NUMBER(PRE.CUSTOMER),
                CASE
                    WHEN PRE.ARR_STATUS IN ('CLOSE', 'PENDING.CLOSURE', 'CANCELLED') THEN 2
                    WHEN PRE.RESTRICTION_TYPE = 'DEBIT' THEN 6
                    WHEN PRE.RESTRICTION_TYPE = 'ALL' THEN 7
                    WHEN PRE.DORMANCY_STATUS IS NOT NULL THEN 9
                    WHEN PRE.START_DATE = TO_DATE(V_TODAY,'YYYYMMDD') AND ARR.ARR_STATUS NOT IN ('CLOSE', 'PENDING.CLOSURE') THEN 4
                    WHEN PRE.ARR_STATUS IN ('AUTH', 'RESTORE-AUTH') AND ADL.DORMANCY_STATUS IS NULL THEN 1
                END,
                CALC_SCCODE_VAL_FUNC(PRE.PRODUCT_STATUS, PRE.PRODUCT),
                TO_NUMBER(TO_CHAR(AGG.MAX_EFF_DAT, 'YYYYDDD'))
                TO_NUMBER(TO_CHAR(AGG.MAX_EFF_DAT, 'DDMMYY')),
                CALC_HOLD_VAL_FUNC(PRE.FROM_DATE, V_TODAY, PRE.LOCKED_AMOUNT),
                CALC_CBAL_VAL_FUNC(PRE.CURR_ASSET_TYPE, PRE.OPEN_BALANCE, PRE.CREDIT_MVMT, PRE.DEBIT_MVMT),
                CALC_ACCRUE_VAL_FUNC(PRE.CURR_ASSET_TYPE, PRE.OPEN_BALANCE, PRE.CREDIT_MVMT, PRE.DEBIT_MVMT),
                TO_NUMBER(PRE.INTERNAL_AMOUNT),
                PRE.WINDOW_ID,
                PRE.COMMIT_TS,
                PRE.REPLICAT_TS,
                PRE.MAPPED_TS,
                'LMT'
            FROM PRECOMPUTED PRE
            LEFT JOIN AGGREGATED AGG ON AGG.ARRANGEMENT = PRE.ARR_RECID

            DELETE FROM T24_DDMEMO_ACTIVITY_LMT
            WHERE WINDOW_ID MEMBER OF V_WINDOW_ID_LIST;
        END IF;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END GEN_FROM_LMT_PROC

---------------------------------------------------------------------------
-- GEN_FROM_ADL_PROC
---------------------------------------------------------------------------
    PROCEDURE GEN_FROM_ADL_PROC IS
        V_WINDOW_ID_LIST T_WINDOW_ID_ARRAY;
        V_TODAY          VARCHAR2(8);
    BEGIN
        SELECT CDC.WINDOW_ID
        BULK COLLECT INTO V_WINDOW_ID_LIST
        FROM T24_DDMEMO_ACTIVITY_ADL CDC
        WHERE EXISTS (
            SELECT 1
            FROM V_FMSB_ADL_MAPPED ADL
            WHERE ADL.RECID = CDC.RECID
            AND CDC.WINDOW_ID <= ADL.WINDOW_ID
        );
        -- ) FETCH FIRST 5000 ROWS ONLY;

        IF V_WINDOW_ID_LIST.COUNT > 0 THEN
            SELECT /*+ RESULT_CACHE */ TODAY INTO V_TODAY
            FROM F_DAT_MAPPED
            WHERE RECID = 'VN0011000';

            INSERT INTO T24_DDMEMO_ACTIVITY (
                BRANCH, ACCTNO, ACNAME, CIFNO, STATUS, SCCODE,
                DLA7, DLA6, HOLD, CBAL, ACCRUE, ODLIMT,
                WINDOW_ID, COMMIT_TS, REPLICAT_TS, MAPPED_TS, CALL_CDC
            )
            WITH PRECOMPUTED AS(
                SELECT /*+ MATERIALIZE */
                    ACC.CO_CODE          AS BRANCH,
                    ARR.LINKED_APPL_ID   AS ACCTNO,
                    ARR.RECID            AS ARR_RECID,
                    ACC.ACNAME           AS ACNAME,
                    ACC.CUSTOMER         AS CIFNO,
                    ARR.ARR_STATUS       AS ARR_STATUS,
                    PST.RESTRICTION_TYPE AS RESTRICTION_TYPE,
                    ADL.DORMANCY_STATUS  AS DORMANCY_STATUS,
                    ARR.START_DATE       AS START_DATE,
                    ARR.PRODUCT          AS PRODUCT,
                    ARR.PRODUCT_STATUS   AS PRODUCT_STATUS,
                    ACC.LOCKED_AMOUNT    AS LOCKED_AMOUNT,
                    ACC.FROM_DATE        AS FROM_DATE,
                    ECB.CURR_ASSET_TYPE  AS CURR_ASSET_TYPE,
                    ECB.OPEN_BALANCE     AS OPEN_BALANCE,
                    ECB.CREDIT_MVMT      AS CREDIT_MVMT,
                    ECB.DEBIT_MVMT       AS DEBIT_MVMT,
                    ADL.INTERNAL_AMOUNT  AS INTERNAL_AMOUNT,
                    ADL.WINDOW_ID        AS WINDOW_ID,
                    ADL.COMMIT_TS        AS COMMIT_TS,
                    ADL.REPLICAT_TS      AS REPLICAT_TS,
                    ADL.MAPPED_TS        AS MAPPED_TS
                FROM TABLE(V_WINDOW_ID_LIST) V
                JOIN V_FMSB_ADL_MAPPED ADL ON ADL.WINDOW_ID = V.COLUMN_VALUE
                JOIN V_FMSB_ARR_DD ARR ON ARR.RECID = ADL.RECID
                JOIN V_FMSB_ACC_MAPPED ACC ON ACC.RECID = ARR.LINKED_APPL_ID
                JOIN V_FMSB_ECB_MAPPED ECB ON ECB.RECID = ARR.LINKED_APPL_ID
                JOIN V_FMSB_LMT_MAPPED LMT ON LMT.RECID = ACC.LIMIT_KEY
                LEFT JOIN V_F_PST_MAPPED PST ON PST.RECID = ACC.POSTING_RESTRICT               
            ),
            AGGREGATED AS (
                SELECT 
                    ARRANGEMENT,
                    MAX(EFFECTIVE_RATE) AS MAX_EFF_DAT
                FROM V_FMSB_ARC_DDMEMO ARC
                WHERE EXISTS (
                    SELECT 1 FROM PRECOMPUTED PRE
                    WHERE PRE.ARR_RECID = ARC.ARRANGEMENT)
                GROUP BY ARRANGEMENT
            )
            SELECT
                PRE.BRANCH,
                TO_NUMBER(PRE.ACCTNO),
                TRIM(PRE.ACNAME),
                TO_NUMBER(PRE.CUSTOMER),
                CASE
                    WHEN PRE.ARR_STATUS IN ('CLOSE', 'PENDING.CLOSURE', 'CANCELLED') THEN 2
                    WHEN PRE.RESTRICTION_TYPE = 'DEBIT' THEN 6
                    WHEN PRE.RESTRICTION_TYPE = 'ALL' THEN 7
                    WHEN PRE.DORMANCY_STATUS IS NOT NULL THEN 9
                    WHEN PRE.START_DATE = TO_DATE(V_TODAY,'YYYYMMDD') AND ARR.ARR_STATUS NOT IN ('CLOSE', 'PENDING.CLOSURE') THEN 4
                    WHEN PRE.ARR_STATUS IN ('AUTH', 'RESTORE-AUTH') AND ADL.DORMANCY_STATUS IS NULL THEN 1
                END,
                CALC_SCCODE_VAL_FUNC(PRE.PRODUCT_STATUS, PRE.PRODUCT),
                TO_NUMBER(TO_CHAR(AGG.MAX_EFF_DAT, 'YYYYDDD'))
                TO_NUMBER(TO_CHAR(AGG.MAX_EFF_DAT, 'DDMMYY')),
                CALC_HOLD_VAL_FUNC(PRE.FROM_DATE, V_TODAY, PRE.LOCKED_AMOUNT),
                CALC_CBAL_VAL_FUNC(PRE.CURR_ASSET_TYPE, PRE.OPEN_BALANCE, PRE.CREDIT_MVMT, PRE.DEBIT_MVMT),
                CALC_ACCRUE_VAL_FUNC(PRE.CURR_ASSET_TYPE, PRE.OPEN_BALANCE, PRE.CREDIT_MVMT, PRE.DEBIT_MVMT),
                TO_NUMBER(PRE.INTERNAL_AMOUNT),
                PRE.WINDOW_ID,
                PRE.COMMIT_TS,
                PRE.REPLICAT_TS,
                PRE.MAPPED_TS,
                'ADL'
            FROM PRECOMPUTED PRE
            LEFT JOIN AGGREGATED AGG ON AGG.ARRANGEMENT = PRE.ARR_RECID

            DELETE FROM T24_DDMEMO_ACTIVITY_ADL
            WHERE WINDOW_ID MEMBER OF V_WINDOW_ID_LIST;
        END IF;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END GEN_FROM_ADL_PROC;
    
END T24_DDMEMO_ACTIVITY_PKG;