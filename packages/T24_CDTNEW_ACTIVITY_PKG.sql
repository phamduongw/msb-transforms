CREATE OR REPLACE PACKAGE T24RAWOGG.T24_CDTNEW_ACTIVITY_PKG IS
    
    FUNCTION CALC_CBAL_VAL_FUNC(
        P_CURR_ASSET_TYPE IN VARCHAR2,
        P_OPEN_BALANCE    IN VARCHAR2,
        P_CREDIT_MVMT     IN VARCHAR2,
        P_DEBIT_MVMT      IN VARCHAR2
    ) RETURN NUMBER;

    PROCEDURE GEN_FROM_ACC_ARR_ECB_PROC;

END T24_CDTNEW_ACTIVITY_PKG;

CREATE OR REPLACE PACKAGE BODY T24RAWOGG.T24_CDTNEW_ACTIVITY_PKG IS

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
        FROM T24_CDTNEW_ACTIVITY_ACC_ARR_ECB CDC
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

            INSERT INTO T24_CDTNEW_ACTIVITY (
                BANKNO, ACCTNO, ACTYPE, ACNAME, CIFNO, TYPE, BRN, STATUS,
                CDNUM, ORGBAL, CBAL, HOLD, ACCINT, WDRWH, RNWCTR, PENAMT,
                ISSDT, MATDT, CDTERM, CDTCOD, RENEW, DACTN, RATE, CURTYP, CDMUID, RS2DT7, CAPTURED_TIME, CALL_CDC
            )
            WITH GROUPED AS (
                SELECT DISTINCT COLUMN_VALUE
                FROM TABLE(V_JOIN_KEY_LIST)
            ),
            PRECOMPUTED AS (
                SELECT /*+ MATERIALIZE */
                    ACC.RECID           AS ACC_RECID,
                    ARR.RECID           AS ARR_RECID,
                    ACC.ACNAME          AS ACNAME,
                    ACC.CUSTOMER        AS CIFNO,
                    ARR.ACTIVE_PRODUCT  AS TYPE,
                    ACC.CO_CODE         AS BRN,
                    ARR.ARR_STATUS      AS STATUS,
                    ECB.CURR_ASSET_TYPE AS CURR_ASSET_TYPE,
                    ECB.OPEN_BALANCE    AS OPEN_BALANCE,
                    ECB.CREDIT_MVMT     AS CREDIT_MVMT,
                    ECB.DEBIT_MVMT      AS DEBIT_MVMT,
                    ARR.START_DATE      AS ISSDT, 
                    ADL.MATURITY_DATE   AS MATDT,
                    ARR.CURRENCY        AS CURTYP,
                    ACC.INPUTTER        AS CDMUID,
                    ADL.RENEWAL_DATE    AS RS2DT7
                FROM GROUPED GRP
                INNER JOIN V_FMSB_ARR_CD     ARR ON ARR.LINKED_APPL_ID = GRP.COLUMN_VALUE
                INNER JOIN V_FMSB_ACC_MAPPED ACC ON ACC.RECID          = GRP.COLUMN_VALUE
                INNER JOIN V_FMSB_ECB_MAPPED ECB ON ECB.RECID          = GRP.COLUMN_VALUE
                LEFT JOIN  V_FMSB_ADL_MAPPED ADL ON ADL.RECID          = ARR.RECID
                WHERE ARR.START_DATE >= TO_DATE(V_TODAY,'YYYYMMDD')
            ),
            AIT_PRECOMPUTED AS(
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
                WHERE EXISTS (
                    SELECT 1 FROM AIT_PRECOMPUTED PRE
                    WHERE PRE.ID_COMP_1 = AIT.ID_COMP_1
                    AND PRE.MAX_ID_COMP_3 = AIT.ID_COMP_3
                )
            ),
            ATA_PRECOMPUTED AS(
                SELECT 
                    ID_COMP_1, 
                    MIN(ID_COMP_3) AS MIN_ID_COMP_3
                FROM V_FMSB_ATA_MAPPED ATA
                WHERE EXISTS (
                    SELECT 1 FROM PRECOMPUTED PRE
                    WHERE PRE.ARR_RECID = ATA.ID_COMP_1)
                GROUP BY ID_COMP_1
            ),
            ATA_AGGREGATED AS(
                SELECT
                    ATA.ID_COMP_1,
                    ATA.AMOUNT,
                    ATA.TERM
                FROM V_FMSB_ATA_MAPPED ATA
                WHERE EXISTS (
                    SELECT 1 FROM ATA_PRECOMPUTED PRE
                    WHERE PRE.ID_COMP_1 = ATA.ID_COMP_1
                    AND PRE.MIN_ID_COMP_3 = ATA.ID_COMP_3
                )
            ),
            CHG_PRECOMPUTED AS(
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
                    CHG.CHANGE_DATE,
                    CHG.CHANGE_PERIOD
                FROM V_FMSB_CHG_MAPPED CHG
                WHERE EXISTS (
                    SELECT 1 FROM CHG_PRECOMPUTED PRE
                    WHERE PRE.ID_COMP_1 = CHG.ID_COMP_1
                    AND PRE.MAX_ID_COMP_3 = CHG.ID_COMP_3
                )
            ),
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
                CALC_CBAL_VAL_FUNC(PRE.CURR_ASSET_TYPE, PRE.OPEN_BALANCE, PRE.CREDIT_MVMT, PRE.DEBIT_MVMT) AS CBAL,
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
                V_CAPTURED_TIME,
                '1'
            FROM PRECOMPUTED PRE
            LEFT JOIN AIT_AGGREGATED AIT ON AIT.ID_COMP_1 = PRE.ARR_RECID
            LEFT JOIN ATA_AGGREGATED ATA ON ATA.ID_COMP_1 = PRE.ARR_RECID
            LEFT JOIN CHG_AGGREGATED CHG ON CHG.ID_COMP_1 = PRE.ARR_RECID

            DELETE FROM T24_CDTNEW_ACTIVITY_ACC_ARR_ECB CDC
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

END T24_CDTNEW_ACTIVITY_PKG;
