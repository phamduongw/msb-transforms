CREATE OR REPLACE PACKAGE T24_DDTNEW_ACTIVITY_PKG IS

    PROCEDURE GEN_FROM_ACC_PROC;

    PROCEDURE GEN_FROM_ARR_PROC;

END T24_DDTNEW_ACTIVITY_PKG;


CREATE OR REPLACE PACKAGE BODY T24_DDTNEW_ACTIVITY_PKG IS     

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
        FROM T24_DDTNEW_ACTIVITY_ACC CDC
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

            INSERT INTO T24_DDTNEW_ACTIVITY (
                BRANCH, ACNAME, ACCTNO, ACTYPE, DDCTYP, SCCODE, CIFNO, STATUS,
                DATOP7, DLA7, DLA6, HOLD, CBAL, ACCRUE, RATE, ODLIMT,
                WINDOW_ID, COMMIT_TS, REPLICAT_TS, MAPPED_TS, CALL_CDC
            )
            SELECT
                ACC.CO_CODE AS BRANCH,
                TRIM(ACC.ACNAME) AS ACNAME,
                TO_NUMBER(ACC.RECID) AS ACCTNO,
                CASE WHEN TO_NUMBER(ACC.CATEGORY) BETWEEN 6000 AND 6100 THEN 'S' ELSE 'D' AS ACTYPE,
                ACC.CURRENCY AS DDCTYP,
                CALC_SCCODE_VAL_FUNC(ARR.PRODUCT_STATUS, ARR.PRODUCT) AS SCCODE,
                TO_NUMBER(ACC.CUSTOMER) AS CIFNO,
                CASE
                    WHEN ARR.ARR_STATUS IN ('CLOSE','PENDING.CLOSURE','CANCELLED') THEN 2
                    ELSE 4
                END AS STATUS,
                TO_NUMBER(TO_CHAR(NVL(ARR.ORIG_CONTRACT_DATE, ACC.OPENING_DATE), 'YYYYDDD')) AS DATOP7,
                TO_NUMBER(TO_CHAR(ARR.START_DATE), 'YYYYDDD') AS DLA7,
                TO_NUMBER(TO_CHAR(ARR.START_DATE), 'DDMMYY') AS DLA6,
                0 AS HOLD,
                0 AS CBAL,
                0 AS ACCRUE,
                0 AS RATE,
                0 AS ODLIMT,
                ACC.WINDOW_ID,
                ACC.COMMIT_TS,
                ACC.REPLICAT_TS,
                ACC.MAPPED_TS,
                'ACC'
                FROM TABLE(V_WINDOW_ID_LIST) V
                JOIN FMSB_ACC_MAPPED ACC ON ACC.WINDOW_ID = V.COLUMN_VALUE
                JOIN FMSB_ARR_DD ARR ON ARR.LINKED_APPL_ID = ACC.RECID
                WHERE ARR.START_DATE >= TO_DATE(V_TODAY,'YYYYMMDD');

                DELETE FROM T24_DDTNEW_ACTIVITY_ACC
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
        FROM T24_DDTNEW_ACTIVITY_ARR CDC
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

            INSERT INTO T24_DDTNEW_ACTIVITY (
                BRANCH, ACNAME, ACCTNO, ACTYPE, DDCTYP, SCCODE, CIFNO, STATUS,
                DATOP7, DLA7, DLA6, HOLD, CBAL, ACCRUE, RATE, ODLIMT,
                WINDOW_ID, COMMIT_TS, REPLICAT_TS, MAPPED_TS, CALL_CDC
            )
            SELECT
                ACC.CO_CODE AS BRANCH,
                TRIM(ACC.ACNAME) AS ACNAME,
                TO_NUMBER(ARR.LINKED_APPL_ID) AS ACCTNO,
                CASE WHEN TO_NUMBER(ACC.CATEGORY) BETWEEN 6000 AND 6100 THEN 'S' ELSE 'D' AS ACTYPE,
                ACC.CURRENCY AS DDCTYP,
                CALC_SCCODE_VAL_FUNC(ARR.PRODUCT_STATUS, ARR.PRODUCT) AS SCCODE,
                TO_NUMBER(ACC.CUSTOMER) AS CIFNO,
                CASE
                    WHEN ARR.ARR_STATUS IN ('CLOSE','PENDING.CLOSURE','CANCELLED') THEN 2
                    ELSE 4
                END AS STATUS,
                TO_NUMBER(TO_CHAR(NVL(ARR.ORIG_CONTRACT_DATE, ACC.OPENING_DATE), 'YYYYDDD')) AS DATOP7,
                TO_NUMBER(TO_CHAR(ARR.START_DATE), 'YYYYDDD') AS DLA7,
                TO_NUMBER(TO_CHAR(ARR.START_DATE), 'DDMMYY') AS DLA6,
                0 AS HOLD,
                0 AS CBAL,
                0 AS ACCRUE,
                0 AS RATE,
                0 AS ODLIMT,
                ARR.WINDOW_ID,
                ARR.COMMIT_TS,
                ARR.REPLICAT_TS,
                ARR.MAPPED_TS,
                'ARR'
                FROM TABLE(V_WINDOW_ID_LIST) V
                JOIN FMSB_ARR_DD ARR ON ARR.WINDOW_ID = V.COLUMN_VALUE
                JOIN FMSB_ACC_MAPPED ACC ON ACC.WINDOW_ID = ARR.LINKED_APPL_ID
                WHERE ARR.START_DATE >= TO_DATE(V_TODAY,'YYYYMMDD');

                DELETE FROM T24_DDTNEW_ACTIVITY_ARR
                WHERE WINDOW_ID MEMBER OF V_WINDOW_ID_LIST;
        END IF;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END GEN_FROM_ARR_PROC;

END T24_DDTNEW_ACTIVITY_PKG;