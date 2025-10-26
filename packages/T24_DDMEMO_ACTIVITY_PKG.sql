CREATE OR REPLACE PACKAGE T24RAWOGG.T24_DDMEMO_ACTIVITY_PKG IS

    FUNCTION CALC_HOLD_VAL_FUNC(
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

    PROCEDURE GEN_FROM_ACC_ECB_ARR_PROC;

    PROCEDURE GEN_FROM_LMT_PROC;

    PROCEDURE GEN_FROM_ADL_PROC;

END T24_DDMEMO_ACTIVITY_PKG;

CREATE OR REPLACE PACKAGE BODY T24RAWOGG.T24_DDMEMO_ACTIVITY_PKG IS

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
-- GEN_FROM_ACC_ECB_ARR_PROC
---------------------------------------------------------------------------
    PROCEDURE GEN_FROM_ACC_ECB_ARR_PROC IS 
        V_JOIN_KEY_LIST  T_JOIN_KEY_ARRAY;
        V_WINDOW_ID_LIST T_WINDOW_ID_ARRAY;
        V_TODAY          VARCHAR2(8);
    BEGIN
        SELECT CDC.JOIN_KEY, CDC.WINDOW_ID
        BULK COLLECT INTO V_JOIN_KEY_LIST, V_WINDOW_ID_LIST
        FROM T24_DDMEMO_ACTIVITY_ACC_ARR_ECB CDC
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
            FROM V_FMSB_ARR_MAPPED ARR
            WHERE ARR.WINDOW_ID = CDC.WINDOW_ID
        );
        -- ) FETCH FIRST 9999 ROWS ONLY;
        
        IF V_JOIN_KEY_LIST.COUNT > 0 THEN
            SELECT /*+ RESULT_CACHE */ TODAY INTO V_TODAY
            FROM F_DAT_MAPPED
            WHERE RECID = 'VN0011000';

            INSERT INTO T24_DDMEMO_ACTIVITY (
                BRANCH, ACCTNO, ACNAME, CIFNO, STATUS, SCCODE,
                DLA7, DLA6, HOLD, CBAL, ACCRUE, ODLIMT, 
                WINDOW_ID, COMMIT_TS, REPLICAT_TS, MAPPED_TS, CALL_CDC
            )
            WITH GROUPED AS (
                SELECT DISTINCT COLUMN_VALUE
                FROM TABLE(V_JOIN_KEY_LIST)
            ),
            PRECOMPUTED AS(
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
                    ARR.ACTIVE_PRODUCT   AS SCCODE,
                    ACC.LOCKED_AMOUNT    AS HOLD,
                    ECB.CURR_ASSET_TYPE  AS CURR_ASSET_TYPE,
                    ECB.OPEN_BALANCE     AS OPEN_BALANCE,
                    ECB.CREDIT_MVMT      AS CREDIT_MVMT,
                    ECB.DEBIT_MVMT       AS DEBIT_MVMT,
                    LMT.INTERNAL_AMOUNT  AS ODLIMT,
                    GREATEST(ARR.WINDOW_ID, ACC.WINDOW_ID, ECB.WINDOW_ID)       AS WINDOW_ID,
                    GREATEST(ARR.COMMIT_TS, ACC.COMMIT_TS, ECB.COMMIT_TS)       AS COMMIT_TS,
                    GREATEST(ARR.REPLICAT_TS, ACC.REPLICAT_TS, ECB.REPLICAT_TS) AS REPLICAT_TS,
                    GREATEST(ARR.MAPPED_TS, ACC.MAPPED_TS, ECB.MAPPED_TS)       AS MAPPED_TS
                FROM GROUPED GRP
                INNER JOIN V_FMSB_ARR_MAPPED ARR ON ARR.LINKED_APPL_ID = GRP.COLUMN_VALUE
                INNER JOIN V_FMSB_ACC_MAPPED ACC ON ACC.RECID          = GRP.COLUMN_VALUE
                INNER JOIN V_FMSB_ECB_MAPPED ECB ON ECB.RECID          = GRP.COLUMN_VALUE
                LEFT JOIN  V_FMSB_ADL_MAPPED ADL ON ADL.RECID          = ARR.RECID
                LEFT JOIN  V_FMSB_LMT_MAPPED LMT ON LMT.RECID          = ACC.LIMIT_KEY
                LEFT JOIN  F_PST_MAPPED      PST ON PST.RECID          = ACC.POSTING_RESTRICT   
                WHERE ARR.PRODUCT_LINE = 'ACCOUNTS' AND ARR.ARR_STATUS <>'UNAUTH'             
            ),
            AGGREGATED AS (
                SELECT 
                    ARRANGEMENT,
                    MAX(EFFECTIVE_DATE) AS MAX_EFF_DAT
                FROM V_FMSB_ARC_DDMEMO ARC 
                WHERE EXISTS (
                    SELECT 1 FROM PRECOMPUTED PRE
                    WHERE PRE.ARR_RECID = ARC.ARRANGEMENT)
                GROUP BY ARRANGEMENT
            )
            SELECT
                PRE.BRANCH,
                TO_NUMBER(PRE.ACCTNO),
                PRE.ACNAME,
                TO_NUMBER(PRE.CIFNO),
                CASE
                    WHEN PRE.ARR_STATUS IN ('CLOSE', 'PENDING.CLOSURE', 'CANCELLED') THEN 2
                    WHEN PRE.RESTRICTION_TYPE = 'DEBIT' THEN 6
                    WHEN PRE.RESTRICTION_TYPE = 'ALL' THEN 7
                    WHEN PRE.DORMANCY_STATUS IS NOT NULL THEN 9
                    WHEN PRE.START_DATE = V_TODAY AND PRE.ARR_STATUS NOT IN ('CLOSE', 'PENDING.CLOSURE') THEN 4
                    WHEN PRE.ARR_STATUS IN ('AUTH', 'RESTORE-AUTH') AND PRE.DORMANCY_STATUS IS NULL THEN 1
                END,
                PRE.SCCODE,
                TO_NUMBER(TO_CHAR(AGG.MAX_EFF_DAT, 'YYYYDDD')), --DLA7
                TO_NUMBER(TO_CHAR(AGG.MAX_EFF_DAT, 'DDMMYY')), --DLA6
                CALC_HOLD_VAL_FUNC(PRE.HOLD),
                CALC_CBAL_VAL_FUNC(PRE.CURR_ASSET_TYPE, PRE.OPEN_BALANCE, PRE.CREDIT_MVMT, PRE.DEBIT_MVMT),
                CALC_ACCRUE_VAL_FUNC(PRE.CURR_ASSET_TYPE, PRE.OPEN_BALANCE, PRE.CREDIT_MVMT, PRE.DEBIT_MVMT),
                TO_NUMBER(NVL(PRE.ODLIMT,0)),
                PRE.WINDOW_ID,
                PRE.COMMIT_TS,
                PRE.REPLICAT_TS,
                PRE.MAPPED_TS,
                'ACC_ECB_ARR'
            FROM PRECOMPUTED PRE
            LEFT JOIN AGGREGATED AGG ON AGG.ARRANGEMENT = PRE.ARR_RECID;

            DELETE FROM T24_DDMEMO_ACTIVITY_ACC_ARR_ECB CDC
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
    END GEN_FROM_ACC_ECB_ARR_PROC;

---------------------------------------------------------------------------
-- GEN_FROM_LMT_PROC
---------------------------------------------------------------------------
    PROCEDURE GEN_FROM_LMT_PROC IS
        V_WINDOW_ID_LIST T_WINDOW_ID_ARRAY;
        V_TODAY VARCHAR2(8);
    BEGIN
        SELECT CDC.WINDOW_ID
        BULK COLLECT INTO V_WINDOW_ID_LIST
        FROM T24_DDMEMO_ACTIVITY_LMT CDC
        WHERE EXISTS (
            SELECT 1
            FROM V_FMSB_LMT_MAPPED LMT
            WHERE LMT.WINDOW_ID = CDC.WINDOW_ID
        );
        -- ) FETCH FIRST 9999 ROWS ONLY;

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
                    ARR.ACTIVE_PRODUCT   AS SCCODE,
                    ACC.LOCKED_AMOUNT    AS HOLD,
                    ECB.CURR_ASSET_TYPE  AS CURR_ASSET_TYPE,
                    ECB.OPEN_BALANCE     AS OPEN_BALANCE,
                    ECB.CREDIT_MVMT      AS CREDIT_MVMT,
                    ECB.DEBIT_MVMT       AS DEBIT_MVMT,
                    LMT.INTERNAL_AMOUNT  AS ODLIMT,
                    LMT.WINDOW_ID        AS WINDOW_ID,
                    LMT.COMMIT_TS        AS COMMIT_TS,
                    LMT.REPLICAT_TS      AS REPLICAT_TS,
                    LMT.MAPPED_TS        AS MAPPED_TS
                FROM TABLE(V_WINDOW_ID_LIST) TMP
                INNER JOIN V_FMSB_LMT_MAPPED LMT ON LMT.WINDOW_ID      = TMP.COLUMN_VALUE
                INNER JOIN V_FMSB_ACC_MAPPED ACC ON ACC.LIMIT_KEY      = LMT.RECID
                INNER JOIN V_FMSB_ARR_MAPPED ARR ON ARR.LINKED_APPL_ID = ACC.RECID
                INNER JOIN V_FMSB_ECB_MAPPED ECB ON ECB.RECID          = ACC.RECID
                LEFT JOIN  V_FMSB_ADL_MAPPED ADL ON ADL.RECID          = ARR.RECID
                LEFT JOIN  F_PST_MAPPED      PST ON PST.RECID          = ACC.POSTING_RESTRICT   
                WHERE ARR.PRODUCT_LINE = 'ACCOUNTS' AND ARR.ARR_STATUS <>'UNAUTH'             
            ),
            AGGREGATED AS (
                SELECT 
                    ARRANGEMENT,
                    MAX(EFFECTIVE_DATE) AS MAX_EFF_DAT
                FROM V_FMSB_ARC_DDMEMO ARC
                WHERE EXISTS (
                    SELECT 1 FROM PRECOMPUTED PRE
                    WHERE PRE.ARR_RECID = ARC.ARRANGEMENT)
                GROUP BY ARRANGEMENT
            )   
            SELECT
                PRE.BRANCH,
                TO_NUMBER(PRE.ACCTNO),
                PRE.ACNAME,
                TO_NUMBER(PRE.CIFNO),
                CASE
                    WHEN PRE.ARR_STATUS IN ('CLOSE', 'PENDING.CLOSURE', 'CANCELLED') THEN 2
                    WHEN PRE.RESTRICTION_TYPE = 'DEBIT' THEN 6
                    WHEN PRE.RESTRICTION_TYPE = 'ALL' THEN 7
                    WHEN PRE.DORMANCY_STATUS IS NOT NULL THEN 9
                    WHEN PRE.START_DATE = V_TODAY AND PRE.ARR_STATUS NOT IN ('CLOSE', 'PENDING.CLOSURE') THEN 4
                    WHEN PRE.ARR_STATUS IN ('AUTH', 'RESTORE-AUTH') AND PRE.DORMANCY_STATUS IS NULL THEN 1
                END,
                PRE.SCCODE,
                TO_NUMBER(TO_CHAR(AGG.MAX_EFF_DAT, 'YYYYDDD')), --DLA7
                TO_NUMBER(TO_CHAR(AGG.MAX_EFF_DAT, 'DDMMYY')), --DLA6
                CALC_HOLD_VAL_FUNC(PRE.HOLD) AS HOLD,
                CALC_CBAL_VAL_FUNC(PRE.CURR_ASSET_TYPE, PRE.OPEN_BALANCE, PRE.CREDIT_MVMT, PRE.DEBIT_MVMT),
                CALC_ACCRUE_VAL_FUNC(PRE.CURR_ASSET_TYPE, PRE.OPEN_BALANCE, PRE.CREDIT_MVMT, PRE.DEBIT_MVMT),
                TO_NUMBER(NVL(PRE.ODLIMT,0)),
                PRE.WINDOW_ID,
                PRE.COMMIT_TS,
                PRE.REPLICAT_TS,
                PRE.MAPPED_TS,
                'LMT'
            FROM PRECOMPUTED PRE
            LEFT JOIN AGGREGATED AGG ON AGG.ARRANGEMENT = PRE.ARR_RECID;

            DELETE FROM T24_DDMEMO_ACTIVITY_LMT CDC
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
 
---------------------------------------------------------------------------
-- GEN_FROM_ADL_PROC
---------------------------------------------------------------------------
    PROCEDURE GEN_FROM_ADL_PROC IS
        V_WINDOW_ID_LIST T_WINDOW_ID_ARRAY;
        V_TODAY VARCHAR2(8);
    BEGIN
        SELECT CDC.WINDOW_ID
        BULK COLLECT INTO V_WINDOW_ID_LIST
        FROM T24_DDMEMO_ACTIVITY_ADL CDC
        WHERE EXISTS (
            SELECT 1
            FROM V_FMSB_ADL_MAPPED ADL
            WHERE ADL.WINDOW_ID = CDC.WINDOW_ID
        );
        -- ) FETCH FIRST 9999 ROWS ONLY;

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
                    ARR.ACTIVE_PRODUCT   AS SCCODE,
                    ACC.LOCKED_AMOUNT    AS HOLD,
                    ECB.CURR_ASSET_TYPE  AS CURR_ASSET_TYPE,
                    ECB.OPEN_BALANCE     AS OPEN_BALANCE,
                    ECB.CREDIT_MVMT      AS CREDIT_MVMT,
                    ECB.DEBIT_MVMT       AS DEBIT_MVMT,
                    LMT.INTERNAL_AMOUNT  AS ODLIMT,
                    ADL.WINDOW_ID        AS WINDOW_ID,
                    ADL.COMMIT_TS        AS COMMIT_TS,
                    ADL.REPLICAT_TS      AS REPLICAT_TS,
                    ADL.MAPPED_TS        AS MAPPED_TS
                FROM TABLE(V_WINDOW_ID_LIST) TMP
                INNER JOIN V_FMSB_ADL_MAPPED ADL ON ADL.WINDOW_ID      = TMP.COLUMN_VALUE
                INNER JOIN V_FMSB_ARR_MAPPED ARR ON ARR.RECID          = ADL.RECID
                INNER JOIN V_FMSB_ACC_MAPPED ACC ON ACC.RECID          = ARR.LINKED_APPL_ID
                INNER JOIN V_FMSB_ECB_MAPPED ECB ON ECB.RECID          = ARR.LINKED_APPL_ID
                LEFT JOIN  V_FMSB_LMT_MAPPED LMT ON LMT.RECID          = ACC.LIMIT_KEY
                LEFT JOIN  F_PST_MAPPED    PST ON PST.RECID          = ACC.POSTING_RESTRICT   
                WHERE ARR.PRODUCT_LINE = 'ACCOUNTS' AND ARR.ARR_STATUS <>'UNAUTH'             
            ),
            AGGREGATED AS (
                SELECT 
                    ARRANGEMENT,
                    MAX(EFFECTIVE_DATE) AS MAX_EFF_DAT
                FROM V_FMSB_ARC_DDMEMO ARC
                WHERE EXISTS (
                    SELECT 1 FROM PRECOMPUTED PRE
                    WHERE PRE.ARR_RECID = ARC.ARRANGEMENT)
                GROUP BY ARRANGEMENT
            )  
            SELECT
                PRE.BRANCH,
                TO_NUMBER(PRE.ACCTNO),
                PRE.ACNAME,
                TO_NUMBER(PRE.CIFNO),
                CASE
                    WHEN PRE.ARR_STATUS IN ('CLOSE', 'PENDING.CLOSURE', 'CANCELLED') THEN 2
                    WHEN PRE.RESTRICTION_TYPE = 'DEBIT' THEN 6
                    WHEN PRE.RESTRICTION_TYPE = 'ALL' THEN 7
                    WHEN PRE.DORMANCY_STATUS IS NOT NULL THEN 9
                    WHEN PRE.START_DATE = V_TODAY AND PRE.ARR_STATUS NOT IN ('CLOSE', 'PENDING.CLOSURE') THEN 4
                    WHEN PRE.ARR_STATUS IN ('AUTH', 'RESTORE-AUTH') AND PRE.DORMANCY_STATUS IS NULL THEN 1
                END,
                PRE.SCCODE,
                TO_NUMBER(TO_CHAR(AGG.MAX_EFF_DAT, 'YYYYDDD')), --DLA7
                TO_NUMBER(TO_CHAR(AGG.MAX_EFF_DAT, 'DDMMYY')), --DLA6
                CALC_HOLD_VAL_FUNC(PRE.HOLD) AS HOLD,
                CALC_CBAL_VAL_FUNC(PRE.CURR_ASSET_TYPE, PRE.OPEN_BALANCE, PRE.CREDIT_MVMT, PRE.DEBIT_MVMT),
                CALC_ACCRUE_VAL_FUNC(PRE.CURR_ASSET_TYPE, PRE.OPEN_BALANCE, PRE.CREDIT_MVMT, PRE.DEBIT_MVMT),
                TO_NUMBER(NVL(PRE.ODLIMT,0)),
                PRE.WINDOW_ID,
                PRE.COMMIT_TS,
                PRE.REPLICAT_TS,      
                PRE.MAPPED_TS,
                'ADL'
            FROM PRECOMPUTED PRE
            LEFT JOIN AGGREGATED AGG ON AGG.ARRANGEMENT = PRE.ARR_RECID;

            DELETE FROM T24_DDMEMO_ACTIVITY_ADL CDC
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
    END GEN_FROM_ADL_PROC;
    
END T24_DDMEMO_ACTIVITY_PKG;
