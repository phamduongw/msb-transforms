CREATE OR REPLACE PACKAGE T24RAWOGG.T24_LNTNEW_ACTIVITY_PKG IS

    FUNCTION CALC_PMTAMT_VAL_FUNC(
        P_CALC_AMOUNT   IN VARCHAR2
    ) RETURN NUMBER;

    FUNCTION CALC_TYPE_VAL_FUNC(
        P_PRODUCT_STATUS IN VARCHAR2,
        P_PRODUCT        IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION CALC_FREQ_VAL_FUNC(
        P_BILL_TYPE    IN VARCHAR2,
        P_PROPERTY     IN VARCHAR2,
        P_PAYMENT_FREQ IN VARCHAR2
    ) RETURN NUMBER;
   
   	FUNCTION CALC_IPFREQ_VAL_FUNC(
        P_BILL_TYPE    IN VARCHAR2,
        P_PROPERTY     IN VARCHAR2,
        P_PAYMENT_FREQ IN VARCHAR2
    ) RETURN NUMBER;

    PROCEDURE GEN_FROM_ACC_PROC;

    PROCEDURE GEN_FROM_ARR_PROC;

    PROCEDURE GEN_FROM_AIT_PROC;

    PROCEDURE GEN_FROM_ASC_PROC;

END T24_LNTNEW_ACTIVITY_PKG;

CREATE OR REPLACE PACKAGE BODY T24RAWOGG.T24_LNTNEW_ACTIVITY_PKG IS 

---------------------------------------------------------------------------
-- CALC_PMTAMT_VAL_FUNC
---------------------------------------------------------------------------
    FUNCTION CALC_PMTAMT_VAL_FUNC(
        P_CALC_AMOUNT   IN VARCHAR2
    ) RETURN NUMBER IS
        V_PMTAMT        NUMBER := 0;
        V_START         PLS_INTEGER := 1;
        V_LEN           PLS_INTEGER := LENGTH(P_CALC_AMOUNT); 
        V_COLON_IDX     PLS_INTEGER;
        V_HASH_IDX      PLS_INTEGER;
        V_POS           VARCHAR2(6);
        V_CALC_AMOUNT   NUMBER;
    BEGIN
        IF P_CALC_AMOUNT IS NULL THEN
            RETURN 0;
        END IF;

        V_COLON_IDX := INSTR(P_CALC_AMOUNT, ':', V_START) + 1;
        V_HASH_IDX  := INSTR(P_CALC_AMOUNT, '#', V_COLON_IDX);

        IF V_HASH_IDX = 0 THEN
            V_HASH_IDX := V_LEN + 1;
        END IF;

        V_POS    := SUBSTR(P_CALC_AMOUNT, V_START, V_COLON_IDX - V_START);
        V_PMTAMT := T24_UTILS_PKG.GET_NUM_VAL_BY_POS_FUNC(P_CALC_AMOUNT, V_POS);

        RETURN V_PMTAMT;
    END CALC_PMTAMT_VAL_FUNC;

    FUNCTION CALC_TYPE_VAL_FUNC(
        P_PRODUCT_STATUS IN VARCHAR2,
        P_PRODUCT        IN VARCHAR2
    ) RETURN VARCHAR2 IS
        V_TYPE             VARCHAR2(30);
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

            IF V_PRODUCT_STATUS IN ('CURRENT')
             THEN
                V_TYPE :=  T24_UTILS_PKG.GET_STR_VAL_BY_POS_FUNC(P_PRODUCT, V_POS);
            END IF;

            V_START := V_HASH_IDX;
        END LOOP;

        RETURN V_TYPE;
    END CALC_TYPE_VAL_FUNC;

---------------------------------------------------------------------------
-- CALC_FREQ_VAL_FUNC
---------------------------------------------------------------------------
    FUNCTION CALC_FREQ_VAL_FUNC(
        P_BILL_TYPE    IN VARCHAR2,
        P_PROPERTY     IN VARCHAR2,
        P_PAYMENT_FREQ IN VARCHAR2
    ) RETURN NUMBER IS
        V_PAYMENT_FREQ VARCHAR2(255);
        V_START        PLS_INTEGER := 1;
        V_LEN          PLS_INTEGER := LENGTH(P_BILL_TYPE);
        V_COLON_IDX    PLS_INTEGER;
        V_HASH_IDX     PLS_INTEGER;
        V_POS          VARCHAR2(4);
        V_BILL_TYPE    VARCHAR2(20);
        V_PROPERTY     VARCHAR2(20);
        V_SPACE_1      NUMBER;
        V_SPACE_2      NUMBER;
        V_SPACE_3      NUMBER;
        V_SPACE_4      NUMBER;
        V_GROUP_1      VARCHAR2(20);
        V_GROUP_2      VARCHAR2(20);
        V_GROUP_3      VARCHAR2(20);
        V_GROUP_4      VARCHAR2(20);
        V_GROUP_5      VARCHAR2(20);
        D_GROUP_1      NUMBER;
        D_GROUP_2      NUMBER;
        D_GROUP_3      NUMBER;
        D_GROUP_4      NUMBER;
        D_GROUP_5      NUMBER;
        V_FREQ_RESULT  NUMBER;
       	V_FREQ_CURRENT NUMBER;
    BEGIN
        IF P_BILL_TYPE IS NULL THEN
            RETURN 0;
        END IF;

        WHILE V_START <= V_LEN LOOP
            V_COLON_IDX := INSTR(P_BILL_TYPE, ':', V_START) + 1;
            V_HASH_IDX := INSTR(P_BILL_TYPE, '#', V_COLON_IDX);

            IF V_HASH_IDX = 0 THEN
                V_HASH_IDX := V_LEN + 1;
            END IF;

            V_POS          := SUBSTR(P_BILL_TYPE, V_START, V_COLON_IDX - V_START);
            V_BILL_TYPE    := SUBSTR(P_BILL_TYPE, V_COLON_IDX, V_HASH_IDX - V_COLON_IDX);
            V_PROPERTY     := T24_UTILS_PKG.GET_STR_VAL_BY_POS_FUNC(P_PROPERTY, V_POS);

            IF V_BILL_TYPE IN ('INSTALLMENT','INVESTORBILL','PAYMENT')
            AND V_PROPERTY = 'ACCOUNT'
            THEN
                V_PAYMENT_FREQ := T24_UTILS_PKG.GET_STR_VAL_BY_POS_FUNC(P_PAYMENT_FREQ, V_POS);
               
               	IF V_PAYMENT_FREQ IS NOT NULL THEN
                    V_SPACE_1 := INSTR(V_PAYMENT_FREQ,' ',1,1);
                    V_SPACE_2 := INSTR(V_PAYMENT_FREQ,' ',1,2);
                    V_SPACE_3 := INSTR(V_PAYMENT_FREQ,' ',1,3);
                    V_SPACE_4 := INSTR(V_PAYMENT_FREQ,' ',1,4);

                    V_GROUP_1 := SUBSTR(V_PAYMENT_FREQ, 1, V_SPACE_1 -1);
                    V_GROUP_2 := SUBSTR(V_PAYMENT_FREQ, V_SPACE_1 +1, V_SPACE_2- V_SPACE_1 -1);
                    V_GROUP_3 := SUBSTR(V_PAYMENT_FREQ, V_SPACE_2 +1, V_SPACE_3- V_SPACE_2 -1);
                    V_GROUP_4 := SUBSTR(V_PAYMENT_FREQ, V_SPACE_3 +1, V_SPACE_4- V_SPACE_3 -1);
                    V_GROUP_5 := SUBSTR(V_PAYMENT_FREQ, V_SPACE_4 +1);

                    D_GROUP_1 := TO_NUMBER(SUBSTR(V_GROUP_1, 2, LENGTH(V_GROUP_1) -2));
                    D_GROUP_2 := TO_NUMBER(SUBSTR(V_GROUP_2, 2, LENGTH(V_GROUP_2) -2));
                    D_GROUP_3 := TO_NUMBER(SUBSTR(V_GROUP_3, 2, LENGTH(V_GROUP_3) -2));
                    D_GROUP_4 := TO_NUMBER(SUBSTR(V_GROUP_4, 2, LENGTH(V_GROUP_4) -2));

	                 V_FREQ_CURRENT:=
	                    CASE
	                        WHEN V_GROUP_5 = 'eLHFYRF' THEN 6
	                        WHEN V_GROUP_5 = 'eLMNTHF' THEN 1
	                        WHEN V_GROUP_5 = 'eLQUATF' THEN 3
	                        WHEN V_GROUP_5 = 'eLWEEKF' THEN 1
	                        WHEN V_GROUP_5 = 'eLYEARF' THEN 1
	                        WHEN SUBSTR(V_GROUP_4,1,1) = 'o' AND NVL(D_GROUP_2,0) <> 0 THEN D_GROUP_2
	                        WHEN SUBSTR(V_GROUP_4,1,1) = 'o' AND NVL(D_GROUP_3,0) <> 0 THEN D_GROUP_3
	                        WHEN NVL(D_GROUP_1,0) <> 0 THEN D_GROUP_1
	                        WHEN NVL(D_GROUP_2,0) <> 0 THEN D_GROUP_2
	                        WHEN NVL(D_GROUP_3,0) <> 0 THEN D_GROUP_3
	                        WHEN SUBSTR(V_GROUP_4,2,1) = 'B' THEN 1
	                        WHEN NVL(D_GROUP_4,0) <> 0 THEN D_GROUP_4
	                    END;
	               	V_FREQ_RESULT := GREATEST(NVL(V_FREQ_RESULT,0), V_FREQ_CURRENT);
	            END IF;
	        END IF;
			
            V_START := V_HASH_IDX;
        END LOOP;

        RETURN V_FREQ_RESULT;
    END CALC_FREQ_VAL_FUNC;

---------------------------------------------------------------------------
-- CALC_IPFREQ_VAL_FUNC
---------------------------------------------------------------------------   
    FUNCTION CALC_IPFREQ_VAL_FUNC(
        P_BILL_TYPE    IN VARCHAR2,
        P_PROPERTY     IN VARCHAR2,
        P_PAYMENT_FREQ IN VARCHAR2
    ) RETURN NUMBER IS
        V_PAYMENT_FREQ   VARCHAR2(255);
        V_START          PLS_INTEGER := 1;
        V_LEN            PLS_INTEGER := LENGTH(P_BILL_TYPE);
        V_COLON_IDX      PLS_INTEGER;
        V_HASH_IDX       PLS_INTEGER;
        V_POS            VARCHAR2(4);
        V_BILL_TYPE      VARCHAR2(255);
        V_PROPERTY       VARCHAR2(50);
        V_SPACE_1      NUMBER;
        V_SPACE_2      NUMBER;
        V_SPACE_3      NUMBER;
        V_SPACE_4      NUMBER;
        V_GROUP_1      VARCHAR2(20);
        V_GROUP_2      VARCHAR2(20);
        V_GROUP_3      VARCHAR2(20);
        V_GROUP_4      VARCHAR2(20);
        V_GROUP_5      VARCHAR2(20);
        D_GROUP_1      NUMBER;
        D_GROUP_2      NUMBER;
        D_GROUP_3      NUMBER;
        D_GROUP_4      NUMBER;
        V_IPFREQ_RESULT  NUMBER;
        V_IPFREQ_CURRENT NUMBER;
    BEGIN
        IF P_BILL_TYPE IS NULL THEN
            RETURN 0;
        END IF;

        WHILE V_START <= V_LEN LOOP
            V_COLON_IDX := INSTR(P_BILL_TYPE, ':', V_START) + 1;
            V_HASH_IDX := INSTR(P_BILL_TYPE, '#', V_COLON_IDX);

            IF V_HASH_IDX = 0 THEN
                V_HASH_IDX := V_LEN + 1;
            END IF;

            V_POS       := SUBSTR(P_BILL_TYPE, V_START, V_COLON_IDX - V_START);
            V_BILL_TYPE := SUBSTR(P_BILL_TYPE, V_COLON_IDX, V_HASH_IDX - V_COLON_IDX);
            V_PROPERTY  := T24_UTILS_PKG.GET_STR_VAL_BY_POS_FUNC(P_PROPERTY, V_POS);

            IF V_BILL_TYPE IN ('INSTALLMENT','INVESTORBILL','PAYMENT')
            AND V_PROPERTY IN ('LOANINTEREST','LNINTPREBUY','INVESTORINT','RISKINTEREST')
            THEN
                V_PAYMENT_FREQ := T24_UTILS_PKG.GET_STR_VAL_BY_POS_FUNC(P_PAYMENT_FREQ, V_POS);
               		
               	IF V_PAYMENT_FREQ IS NOT NULL THEN
                    V_SPACE_1 := INSTR(V_PAYMENT_FREQ,' ',1,1);
                    V_SPACE_2 := INSTR(V_PAYMENT_FREQ,' ',1,2);
                    V_SPACE_3 := INSTR(V_PAYMENT_FREQ,' ',1,3);
                    V_SPACE_4 := INSTR(V_PAYMENT_FREQ,' ',1,4);

                    V_GROUP_1 := SUBSTR(V_PAYMENT_FREQ, 1, V_SPACE_1-1);
                    V_GROUP_2 := SUBSTR(V_PAYMENT_FREQ, V_SPACE_1+1, V_SPACE_2-V_SPACE_1-1);
                    V_GROUP_3 := SUBSTR(V_PAYMENT_FREQ, V_SPACE_2+1, V_SPACE_3-V_SPACE_2-1);
                    V_GROUP_4 := SUBSTR(V_PAYMENT_FREQ, V_SPACE_3+1, V_SPACE_4-V_SPACE_3-1);
                    V_GROUP_5 := SUBSTR(V_PAYMENT_FREQ, V_SPACE_4+1);

                    D_GROUP_1 := TO_NUMBER(SUBSTR(V_GROUP_1, 2, LENGTH(V_GROUP_1)-2));
                    D_GROUP_2 := TO_NUMBER(SUBSTR(V_GROUP_2, 2, LENGTH(V_GROUP_2)-2));
                    D_GROUP_3 := TO_NUMBER(SUBSTR(V_GROUP_3, 2, LENGTH(V_GROUP_3)-2));
                    D_GROUP_4 := TO_NUMBER(SUBSTR(V_GROUP_4, 2, LENGTH(V_GROUP_4)-2));
	
	                V_IPFREQ_CURRENT :=
	                    CASE
	                        WHEN V_GROUP_5 = 'eLHFYRF' THEN 6
	                        WHEN V_GROUP_5 = 'eLMNTHF' THEN 1
	                        WHEN V_GROUP_5 = 'eLQUATF' THEN 3
	                        WHEN V_GROUP_5 = 'eLWEEKF' THEN 1
	                        WHEN V_GROUP_5 = 'eLYEARF' THEN 1
	                        WHEN SUBSTR(V_GROUP_4,1,1) = 'o' AND NVL(D_GROUP_2,0) <> 0 THEN D_GROUP_2
	                        WHEN SUBSTR(V_GROUP_4,1,1) = 'o' AND NVL(D_GROUP_3,0) <> 0 THEN D_GROUP_3
	                        WHEN NVL(D_GROUP_1,0) <> 0 THEN D_GROUP_1
	                        WHEN NVL(D_GROUP_2,0) <> 0 THEN D_GROUP_2
	                        WHEN NVL(D_GROUP_3,0) <> 0 THEN D_GROUP_3
	                        WHEN SUBSTR(V_GROUP_4,2,1) = 'B' THEN 1
	                        WHEN NVL(D_GROUP_4,0) <> 0 THEN D_GROUP_4
	                    END;
	                V_IPFREQ_RESULT := GREATEST(NVL(V_IPFREQ_RESULT,0), V_IPFREQ_CURRENT);
				END IF;        	 
            END IF;

            V_START := V_HASH_IDX;
        END LOOP;

        RETURN V_IPFREQ_RESULT;
    END CALC_IPFREQ_VAL_FUNC;

---------------------------------------------------------------------------
-- GEN_FROM_ACC_PROC
---------------------------------------------------------------------------   
    PROCEDURE GEN_FROM_ACC_PROC IS
        V_WINDOW_ID_LIST T_WINDOW_ID_ARRAY;
        V_TODAY          VARCHAR2(8);
    BEGIN
        SELECT CDC.WINDOW_ID
        BULK COLLECT INTO V_WINDOW_ID_LIST
        FROM T24_LNTNEW_ACTIVITY_ACC CDC
        WHERE EXISTS (
            SELECT 1
            FROM V_FMSB_ACC_MAPPED ACC
            WHERE ACC.RECID = CDC.RECID
            AND CDC.WINDOW_ID <= ACC.WINDOW_ID
        );
        -- ) FETCH FIRST 5000 ROWS ONLY;

        IF V_WINDOW_ID_LIST.COUNT > 0 THEN
        	SYS.DBMS_SESSION.SLEEP(0.2);
            SELECT /*+ RESULT_CACHE */ TODAY INTO V_TODAY
            FROM F_DAT_MAPPED
            WHERE RECID = 'VN0011000';

            INSERT INTO T24_LNTNEW_ACTIVITY (
                BRN, ACCTNO, LNNUM, CIFNO, ACNAME, STATUS, TYPE,
                CURTYP, ORGAMT, DRLIMT, HOLD, CBAL, OTHCHG,
                ACCINT, COMACC, PMTAMT, FNLPMT, BILPRN, BILINT,
                BILESC, BILLC, BILOC, BILMC, BILLCO, YSOBAL,
                DATOPN, FRELDT, FULLDT, MATDT, RATE, LCTYPE,
                ACCMLC, TERM, TMCODE, FREQ, IPFREQ, ODIND, PURCOD,
                WINDOW_ID, COMMIT_TS, REPLICAT_TS, MAPPED_TS, CALL_CDC
            )
            WITH PRECOMPUTED AS (
                SELECT /*+ MATERIALIZE */
                    ACC.CO_CODE             AS BRN,
                    ACC.RECID               AS ACCTNO,
                    ARR.RECID               AS ARR_RECID,
                    ACC.CUSTOMER            AS CIFNO,
                    ACC.ACNAME              AS ACNAME,
                    ARR.ARR_STATUS          AS ARR_STATUS,
                    ARR.PRODUCT_STATUS      AS PRODUCT_STATUS, 
                    ARR.PRODUCT             AS PRODUCT,                
                    ACC.CURRENCY            AS CURTYP,
                    LMT.INTERNAL_AMOUNT     AS DRLIMT,
                    ARR.ORIG_CONTRACT_DATE  AS ORIG_CONTRACT_DATE,
                    ACC.OPENING_DATE        AS OPENING_DATE,
                    ACC.WINDOW_ID           AS WINDOW_ID,
                    ACC.COMMIT_TS           AS COMMIT_TS,
                    ACC.REPLICAT_TS         AS REPLICAT_TS,
                    ACC.MAPPED_TS           AS MAPPED_TS
                FROM TABLE(V_WINDOW_ID_LIST) V
                JOIN V_FMSB_ACC_MAPPED ACC ON ACC.WINDOW_ID = V.COLUMN_VALUE
                JOIN V_FMSB_ARR_LNTNEW ARR ON ARR.LINKED_APPL_ID = ACC.RECID
                LEFT JOIN V_FMSB_LMT_MAPPED LMT ON LMT.RECID = ACC.LIMIT_KEY
                WHERE ARR.START_DATE >= V_TODAY
            ),
            ARC_AGGREGATED AS (
                SELECT 
                    ARC.ARRANGEMENT,
                    MIN(ARC.EFFECTIVE_DATE) AS MIN_EFF_DAT,
                    MAX(ARC.EFFECTIVE_DATE) AS MAX_EFF_DAT
                FROM V_FMSB_ARC_LNTNEW ARC
                WHERE EXISTS (
                    SELECT 1
                    FROM PRECOMPUTED PRE
                    WHERE PRE.ARR_RECID = ARC.ARRANGEMENT
                )
                AND EFFECTIVE_DATE <= TO_DATE(V_TODAY, 'YYYYMMDD')
                GROUP BY ARC.ARRANGEMENT
            ),
            ATA_AGGREGATED AS (
                SELECT 
                    ATA.ID_COMP_1,
                    MIN(ATA.ID_COMP_3) AS MIN_ID_COMP_3,
                    MAX(CASE 
                            WHEN ATA.ACTIVITY IN ('LENDING-NEW-ARRANGEMENT','LENDING-TAKEOVER-ARRANGEMENT')
                            THEN TO_NUMBER(ATA.AMOUNT)
                            ELSE 0
                        END) AS MAX_AMOUNT
                FROM V_FMSB_ATA_MAPPED ATA
                WHERE EXISTS (
                    SELECT 1
                    FROM PRECOMPUTED PRE
                    WHERE PRE.ARR_RECID = ATA.ID_COMP_1
                )
                GROUP BY ATA.ID_COMP_1
            ),
            ASC_AGGREGATED AS(
                SELECT 
                    ASCC.ID_COMP_1,
                    MAX(ASCC.ID_COMP_3) AS MAX_ID_COMP_3
                FROM V_FMSB_ASC_MAPPED ASCC
                WHERE EXISTS (
                    SELECT 1
                    FROM PRECOMPUTED PRE
                    WHERE PRE.ARR_RECID = ASCC.ID_COMP_1
                )
                GROUP BY ASCC.ID_COMP_1
            ),
            AIT_AGGREGATED AS(
                SELECT
                    AIT.ID_COMP_1,
                    TO_NUMBER(AIT.EFFECTIVE_RATE)/100 AS RATE,
                    ROW_NUMBER() OVER (
                        PARTITION BY AIT.ID_COMP_1
                        ORDER BY AIT.ID_COMP_3 DESC,
                                CASE WHEN AIT.ID_COMP_2 = 'LOANINTEREST'
                                    THEN TO_NUMBER(AIT.ID_COMP_3)
                                    ELSE TO_NUMBER(AIT.ID_COMP_3) - 1
                                END DESC
                    ) AS RN
                FROM V_FMSB_AIT_LNTNEW AIT
                WHERE EXISTS (
                    SELECT 1
                    FROM PRECOMPUTED PRE
                    WHERE PRE.ARR_RECID = AIT.ID_COMP_1
                )
                AND AIT.ID_COMP_3 <= V_TODAY || '.9999'
            ),
            AAC_AGGREGATED AS(
                SELECT 
                    AAC.ID_COMP_1,
                    MAX(AAC.ID_COMP_3) AS MAX_ID_COMP_3
                FROM V_FMSB_AAC_MAPPED AAC
                WHERE EXISTS (
                    SELECT 1
                    FROM PRECOMPUTED PRE
                    WHERE PRE.ARR_RECID = AAC.ID_COMP_1
                )
                AND ID_COMP_3 <= V_TODAY || '.9999'
                GROUP BY AAC.ID_COMP_1
            )
            SELECT
                PRE.BRN AS BRN,
                TO_NUMBER(PRE.ACCTNO) AS ACCTNO,
                0 AS LNNUM,
                TO_NUMBER(PRE.CIFNO) AS CIFNO,
                TRIM(PRE.ACNAME) AS ACNAME,
                CASE
                    WHEN PRE.ARR_STATUS IN ('CLOSE', 'PENDING.CLOSURE', 'CANCELLED') THEN 2
                    ELSE 4
                END AS STATUS,
                CALC_TYPE_VAL_FUNC(PRE.PRODUCT_STATUS, PRE.PRODUCT) AS TYPE,
                PRE.CURTYP AS CURTYP,
                ATA_AGG.MAX_AMOUNT AS ORGAMT,
                TO_NUMBER(PRE.DRLIMT) AS DRLIMT,
                0 AS HOLD,
                0 AS CBAL,
                0 AS OTHCHG,
                0 AS ACCINT,
                0 AS COMACC,
                CALC_PMTAMT_VAL_FUNC(ASCC.CALC_AMOUNT) AS PMTAMT,
                '' AS FNLPMT,
                0 AS BILPRN,
                0 AS BILINT,
                0 AS BILESC,
                0 AS BILLC,
                0 AS BILOC,
                0 AS BILMC,
                0 AS BILLCO,
                0 AS YSOBAL,
                TO_NUMBER(TO_CHAR(NVL(PRE.ORIG_CONTRACT_DATE, PRE.OPENING_DATE), 'YYYYDDD')) AS DATOPN,
                NVL(
                    TO_NUMBER(TO_CHAR(ARC.MIN_EFF_DAT, 'YYYYDDD')),
                    TO_NUMBER(TO_CHAR(TO_DATE(V_TODAY, 'YYYYMMDD'), 'YYYYDDD'))
                ) AS FRELDT,
                NVL(
                    TO_NUMBER(TO_CHAR(ARC.MAX_EFF_DAT, 'YYYYDDD')),
                    TO_NUMBER(TO_CHAR(TO_DATE(V_TODAY, 'YYYYMMDD'), 'YYYYDDD'))
                ) AS FULLDT,
                TO_NUMBER(TO_CHAR(NVL(ATA.MSB_OR_LNMAT_DT, ATA.MATURITY_DATE), 'YYYYDDD')) AS MATDT,
                AIT.RATE AS RATE,
                '' AS LCTYPE,
                '' AS ACCMLC,
                SUBSTR(ATA.TERM, 1, LENGTH(ATA.TERM)-1) AS TERM,
                SUBSTR(ATA.TERM, -1) AS TMCODE,
                CALC_FREQ_VAL_FUNC(ASCC.BILL_TYPE, ASCC.PROPERTY, ASCC.PAYMENT_FREQ) AS FREQ,
                CALC_IPFREQ_VAL_FUNC(ASCC.BILL_TYPE, ASCC.PROPERTY, ASCC.PAYMENT_FREQ) AS IPFREQ,
                'A' AS ODIND,
                AAC.MSB_LN_PURPOSE AS PURCOD,
                PRE.WINDOW_ID,
                PRE.COMMIT_TS,
                PRE.REPLICAT_TS,
                PRE.MAPPED_TS,
                'ACC'
            FROM PRECOMPUTED PRE
            LEFT JOIN ARC_AGGREGATED ARC ON ARC.ARRANGEMENT = PRE.ARR_RECID
            LEFT JOIN ATA_AGGREGATED ATA_AGG ON ATA_AGG.ID_COMP_1 = PRE.ARR_RECID
            LEFT JOIN V_FMSB_ATA_MAPPED ATA ON ATA.ID_COMP_1 = ATA_AGG.ID_COMP_1 AND ATA.ID_COMP_3 = ATA_AGG.MIN_ID_COMP_3
            LEFT JOIN ASC_AGGREGATED ASCC_AGG ON ASCC_AGG.ID_COMP_1 = PRE.ARR_RECID
            LEFT JOIN V_FMSB_ASC_MAPPED ASCC ON ASCC.ID_COMP_1 = ASCC_AGG.ID_COMP_1 AND ASCC.ID_COMP_3 = ASCC_AGG.MAX_ID_COMP_3
            LEFT JOIN AAC_AGGREGATED AAC_AGG ON AAC_AGG.ID_COMP_1 = PRE.ARR_RECID
            LEFT JOIN V_FMSB_AAC_MAPPED AAC ON AAC.ID_COMP_1 = AAC_AGG.ID_COMP_1 AND AAC.ID_COMP_3 = AAC_AGG.MAX_ID_COMP_3
            LEFT JOIN AIT_AGGREGATED AIT ON AIT.ID_COMP_1 = PRE.ARR_RECID AND AIT.RN = 1;

            DELETE FROM T24_LNTNEW_ACTIVITY_ACC CDC
            WHERE EXISTS (
                SELECT 1
                FROM TABLE(V_WINDOW_ID_LIST) V
                WHERE V.COLUMN_VALUE = CDC.WINDOW_ID
            );

            COMMIT;
        END IF;

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
        FROM T24_LNTNEW_ACTIVITY_ARR CDC
        WHERE EXISTS (
            SELECT 1
            FROM V_FMSB_ARR_LNTNEW ARR
            WHERE ARR.RECID = CDC.RECID
            AND CDC.WINDOW_ID <= ARR.WINDOW_ID
        );
        -- ) FETCH FIRST 5000 ROWS ONLY;

        IF V_WINDOW_ID_LIST.COUNT > 0 THEN
        	SYS.DBMS_SESSION.SLEEP(0.2);
            SELECT /*+ RESULT_CACHE */ TODAY INTO V_TODAY
            FROM F_DAT_MAPPED
            WHERE RECID = 'VN0011000';

            INSERT INTO T24_LNTNEW_ACTIVITY (
                BRN, ACCTNO, LNNUM, CIFNO, ACNAME, STATUS, TYPE,
                CURTYP, ORGAMT, DRLIMT, HOLD, CBAL, OTHCHG,
                ACCINT, COMACC, PMTAMT, FNLPMT, BILPRN, BILINT,
                BILESC, BILLC, BILOC, BILMC, BILLCO, YSOBAL,
                DATOPN, FRELDT, FULLDT, MATDT, RATE, LCTYPE,
                ACCMLC, TERM, TMCODE, FREQ, IPFREQ, ODIND, PURCOD,
                WINDOW_ID, COMMIT_TS, REPLICAT_TS, MAPPED_TS, CALL_CDC
            )
            WITH  PRECOMPUTED AS (
                SELECT /*+ MATERIALIZE */
                    ACC.CO_CODE             AS BRN,
                    ARR.LINKED_APPL_ID      AS ACCTNO,
                    ARR.RECID               AS ARR_RECID,
                    ACC.CUSTOMER            AS CIFNO,
                    ACC.ACNAME              AS ACNAME,
                    ARR.ARR_STATUS          AS ARR_STATUS,
                    ARR.PRODUCT_STATUS      AS PRODUCT_STATUS, 
                    ARR.PRODUCT             AS PRODUCT,                
                    ACC.CURRENCY            AS CURTYP,
                    LMT.INTERNAL_AMOUNT     AS DRLIMT,
                    ARR.ORIG_CONTRACT_DATE  AS ORIG_CONTRACT_DATE,
                    ACC.OPENING_DATE        AS OPENING_DATE,
                    ARR.WINDOW_ID           AS WINDOW_ID,
                    ARR.COMMIT_TS           AS COMMIT_TS,
                    ARR.REPLICAT_TS         AS REPLICAT_TS,
                    ARR.MAPPED_TS           AS MAPPED_TS
                FROM TABLE(V_WINDOW_ID_LIST) V
                JOIN V_FMSB_ARR_LNTNEW ARR ON ARR.WINDOW_ID = V.COLUMN_VALUE
                JOIN V_FMSB_ACC_MAPPED ACC ON ACC.RECID = ARR.LINKED_APPL_ID
                LEFT JOIN V_FMSB_LMT_MAPPED LMT ON LMT.RECID = ACC.LIMIT_KEY
                WHERE ARR.START_DATE >= V_TODAY
            ),
            ARC_AGGREGATED AS (
                SELECT 
                    ARC.ARRANGEMENT,
                    MIN(ARC.EFFECTIVE_DATE) AS MIN_EFF_DAT,
                    MAX(ARC.EFFECTIVE_DATE) AS MAX_EFF_DAT
                FROM V_FMSB_ARC_LNTNEW ARC
                WHERE EXISTS (
                    SELECT 1
                    FROM PRECOMPUTED PRE
                    WHERE PRE.ARR_RECID = ARC.ARRANGEMENT
                )
                AND EFFECTIVE_DATE <= TO_DATE(V_TODAY, 'YYYYMMDD')
                GROUP BY ARC.ARRANGEMENT
            ),
            ATA_AGGREGATED AS (
                SELECT 
                    ATA.ID_COMP_1,
                    MIN(ATA.ID_COMP_3) AS MIN_ID_COMP_3,
                    MAX(CASE 
                            WHEN ATA.ACTIVITY IN ('LENDING-NEW-ARRANGEMENT','LENDING-TAKEOVER-ARRANGEMENT')
                            THEN TO_NUMBER(ATA.AMOUNT)
                            ELSE 0
                        END) AS MAX_AMOUNT
                FROM V_FMSB_ATA_MAPPED ATA
                WHERE EXISTS (
                    SELECT 1
                    FROM PRECOMPUTED PRE
                    WHERE PRE.ARR_RECID = ATA.ID_COMP_1
                )
                GROUP BY ATA.ID_COMP_1
            ),
            ASC_AGGREGATED AS(
                SELECT 
                    ASCC.ID_COMP_1,
                    MAX(ASCC.ID_COMP_3) AS MAX_ID_COMP_3
                FROM V_FMSB_ASC_MAPPED ASCC
                WHERE EXISTS (
                    SELECT 1
                    FROM PRECOMPUTED PRE
                    WHERE PRE.ARR_RECID = ASCC.ID_COMP_1
                )
                GROUP BY ASCC.ID_COMP_1
            ),
            AIT_AGGREGATED AS(
                SELECT
                    AIT.ID_COMP_1,
                    TO_NUMBER(AIT.EFFECTIVE_RATE)/100 AS RATE,
                    ROW_NUMBER() OVER (
                        PARTITION BY AIT.ID_COMP_1
                        ORDER BY AIT.ID_COMP_3 DESC,
                                CASE WHEN AIT.ID_COMP_2 = 'LOANINTEREST'
                                    THEN TO_NUMBER(AIT.ID_COMP_3)
                                    ELSE TO_NUMBER(AIT.ID_COMP_3) - 1
                                END DESC
                    ) AS RN
                FROM V_FMSB_AIT_LNTNEW AIT
                WHERE EXISTS (
                    SELECT 1
                    FROM PRECOMPUTED PRE
                    WHERE PRE.ARR_RECID = AIT.ID_COMP_1
                )
                AND AIT.ID_COMP_3 <= V_TODAY || '.9999'
            ),
            AAC_AGGREGATED AS(
                SELECT 
                    AAC.ID_COMP_1,
                    MAX(AAC.ID_COMP_3) AS MAX_ID_COMP_3
                FROM V_FMSB_AAC_MAPPED AAC
                WHERE EXISTS (
                    SELECT 1
                    FROM PRECOMPUTED PRE
                    WHERE PRE.ARR_RECID = AAC.ID_COMP_1
                )
                AND ID_COMP_3 <= V_TODAY || '.9999'
                GROUP BY AAC.ID_COMP_1
            )
            SELECT
                PRE.BRN AS BRN,
                TO_NUMBER(PRE.ACCTNO) AS ACCTNO,
                0 AS LNNUM,
                TO_NUMBER(PRE.CIFNO) AS CIFNO,
                TRIM(PRE.ACNAME) AS ACNAME,
                CASE
                    WHEN PRE.ARR_STATUS IN ('CLOSE', 'PENDING.CLOSURE', 'CANCELLED') THEN 2
                    ELSE 4
                END AS STATUS,
                CALC_TYPE_VAL_FUNC(PRE.PRODUCT_STATUS, PRE.PRODUCT) AS TYPE,
                PRE.CURTYP AS CURTYP,
                ATA_AGG.MAX_AMOUNT AS ORGAMT,
                TO_NUMBER(PRE.DRLIMT) AS DRLIMT,
                0 AS HOLD,
                0 AS CBAL,
                0 AS OTHCHG,
                0 AS ACCINT,
                0 AS COMACC,
                CALC_PMTAMT_VAL_FUNC(ASCC.CALC_AMOUNT) AS PMTAMT,
                '' AS FNLPMT,
                0 AS BILPRN,
                0 AS BILINT,
                0 AS BILESC,
                0 AS BILLC,
                0 AS BILOC,
                0 AS BILMC,
                0 AS BILLCO,
                0 AS YSOBAL,
                TO_NUMBER(TO_CHAR(NVL(PRE.ORIG_CONTRACT_DATE, PRE.OPENING_DATE), 'YYYYDDD')) AS DATOPN,
                NVL(
                    TO_NUMBER(TO_CHAR(ARC.MIN_EFF_DAT, 'YYYYDDD')),
                    TO_NUMBER(TO_CHAR(TO_DATE(V_TODAY, 'YYYYMMDD'), 'YYYYDDD'))
                ) AS FRELDT,
                NVL(
                    TO_NUMBER(TO_CHAR(ARC.MAX_EFF_DAT, 'YYYYDDD')),
                    TO_NUMBER(TO_CHAR(TO_DATE(V_TODAY, 'YYYYMMDD'), 'YYYYDDD'))
                ) AS FULLDT,
                TO_NUMBER(TO_CHAR(NVL(ATA.MSB_OR_LNMAT_DT, ATA.MATURITY_DATE), 'YYYYDDD')) AS MATDT,
                AIT.RATE AS RATE,
                '' AS LCTYPE,
                '' AS ACCMLC,
                SUBSTR(ATA.TERM, 1, LENGTH(ATA.TERM)-1) AS TERM,
                SUBSTR(ATA.TERM, -1) AS TMCODE,
                CALC_FREQ_VAL_FUNC(ASCC.BILL_TYPE, ASCC.PROPERTY, ASCC.PAYMENT_FREQ) AS FREQ,
                CALC_IPFREQ_VAL_FUNC(ASCC.BILL_TYPE, ASCC.PROPERTY, ASCC.PAYMENT_FREQ) AS IPFREQ,
                'A' AS ODIND,
                AAC.MSB_LN_PURPOSE AS PURCOD,
                PRE.WINDOW_ID,
                PRE.COMMIT_TS,
                PRE.REPLICAT_TS,
                PRE.MAPPED_TS,
                'ARR'
            FROM PRECOMPUTED PRE
            LEFT JOIN ARC_AGGREGATED ARC ON ARC.ARRANGEMENT = PRE.ARR_RECID
            LEFT JOIN ATA_AGGREGATED ATA_AGG ON ATA_AGG.ID_COMP_1 = PRE.ARR_RECID
            LEFT JOIN V_FMSB_ATA_MAPPED ATA ON ATA.ID_COMP_1 = ATA_AGG.ID_COMP_1 AND ATA.ID_COMP_3 = ATA_AGG.MIN_ID_COMP_3
            LEFT JOIN ASC_AGGREGATED ASCC_AGG ON ASCC_AGG.ID_COMP_1 = PRE.ARR_RECID
            LEFT JOIN V_FMSB_ASC_MAPPED ASCC ON ASCC.ID_COMP_1 = ASCC_AGG.ID_COMP_1 AND ASCC.ID_COMP_3 = ASCC_AGG.MAX_ID_COMP_3
            LEFT JOIN AAC_AGGREGATED AAC_AGG ON AAC_AGG.ID_COMP_1 = PRE.ARR_RECID
            LEFT JOIN V_FMSB_AAC_MAPPED AAC ON AAC.ID_COMP_1 = AAC_AGG.ID_COMP_1 AND AAC.ID_COMP_3 = AAC_AGG.MAX_ID_COMP_3
            LEFT JOIN AIT_AGGREGATED AIT ON AIT.ID_COMP_1 = PRE.ARR_RECID AND AIT.RN = 1;

            DELETE FROM T24_LNTNEW_ACTIVITY_ARR CDC
            WHERE EXISTS (
                SELECT 1
                FROM TABLE(V_WINDOW_ID_LIST) V
                WHERE V.COLUMN_VALUE = CDC.WINDOW_ID
            );

            COMMIT;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END GEN_FROM_ARR_PROC;

---------------------------------------------------------------------------
-- GEN_FROM_AIT_PROC
---------------------------------------------------------------------------   
    PROCEDURE GEN_FROM_AIT_PROC IS
        V_WINDOW_ID_LIST      T_WINDOW_ID_ARRAY;
        V_TODAY               VARCHAR2(8);
    BEGIN
        SELECT CDC.WINDOW_ID
        BULK COLLECT INTO V_WINDOW_ID_LIST
        FROM T24_LNTNEW_ACTIVITY_AIT CDC
        WHERE EXISTS (
            SELECT 1
            FROM V_FMSB_AIT_LNTNEW AIT
            WHERE AIT.RECID = CDC.RECID
            AND CDC.WINDOW_ID <= AIT.WINDOW_ID
        );
        -- ) FETCH FIRST 5000 ROWS ONLY;

        IF V_WINDOW_ID_LIST.COUNT > 0 THEN
            SYS.DBMS_SESSION.SLEEP(0.2); 
            SELECT /*+ RESULT_CACHE */ TODAY INTO V_TODAY
            FROM F_DAT_MAPPED
            WHERE RECID = 'VN0011000';

            INSERT INTO T24_LNTNEW_ACTIVITY (
                BRN, ACCTNO, LNNUM, CIFNO, ACNAME, STATUS, TYPE,
                CURTYP, ORGAMT, DRLIMT, HOLD, CBAL, OTHCHG,
                ACCINT, COMACC, PMTAMT, FNLPMT, BILPRN, BILINT,
                BILESC, BILLC, BILOC, BILMC, BILLCO, YSOBAL,
                DATOPN, FRELDT, FULLDT, MATDT, RATE, LCTYPE,
                ACCMLC, TERM, TMCODE, FREQ, IPFREQ, ODIND, PURCOD,
                WINDOW_ID, COMMIT_TS, REPLICAT_TS, MAPPED_TS, CALL_CDC
            )
            WITH PRECOMPUTED AS (
                SELECT /*+ MATERIALIZE */ 
                    ACC.CO_CODE             AS BRN,
                    ARR.LINKED_APPL_ID      AS ACCTNO,
                    ARR.RECID               AS ARR_RECID,
                    ACC.CUSTOMER            AS CIFNO,
                    ACC.ACNAME              AS ACNAME,
                    ARR.ARR_STATUS          AS ARR_STATUS,
                    ARR.PRODUCT_STATUS      AS PRODUCT_STATUS, 
                    ARR.PRODUCT             AS PRODUCT,                
                    ACC.CURRENCY            AS CURTYP,
                    LMT.INTERNAL_AMOUNT     AS DRLIMT,
                    ARR.ORIG_CONTRACT_DATE  AS ORIG_CONTRACT_DATE,
                    ACC.OPENING_DATE        AS OPENING_DATE,
                    AIT.WINDOW_ID           AS WINDOW_ID,
                    AIT.COMMIT_TS           AS COMMIT_TS,
                    AIT.REPLICAT_TS         AS REPLICAT_TS,
                    AIT.MAPPED_TS           AS MAPPED_TS
                FROM TABLE(V_WINDOW_ID_LIST) V
                JOIN V_FMSB_AIT_LNTNEW AIT ON AIT.WINDOW_ID = V.COLUMN_VALUE
                LEFT JOIN V_FMSB_ARR_LNTNEW ARR ON ARR.RECID = AIT.ID_COMP_1
                JOIN V_FMSB_ACC_MAPPED ACC ON ACC.RECID = ARR.LINKED_APPL_ID
                LEFT JOIN V_FMSB_LMT_MAPPED LMT ON LMT.RECID = ACC.LIMIT_KEY
                WHERE ARR.START_DATE >= V_TODAY
            ),             
            ARC_AGGREGATED AS (
                SELECT 
                    ARC.ARRANGEMENT,
                    MIN(ARC.EFFECTIVE_DATE) AS MIN_EFF_DAT,
                    MAX(ARC.EFFECTIVE_DATE) AS MAX_EFF_DAT
                FROM V_FMSB_ARC_LNTNEW ARC
                WHERE EXISTS (
                    SELECT 1
                    FROM PRECOMPUTED PRE
                    WHERE PRE.ARR_RECID = ARC.ARRANGEMENT
                )
                AND EFFECTIVE_DATE <= TO_DATE(V_TODAY, 'YYYYMMDD')
                GROUP BY ARC.ARRANGEMENT
            ),
            ATA_AGGREGATED AS (
                SELECT 
                    ATA.ID_COMP_1,
                    MIN(ATA.ID_COMP_3) AS MIN_ID_COMP_3,
                    MAX(CASE 
                            WHEN ATA.ACTIVITY IN ('LENDING-NEW-ARRANGEMENT','LENDING-TAKEOVER-ARRANGEMENT')
                            THEN TO_NUMBER(ATA.AMOUNT)
                            ELSE 0
                        END) AS MAX_AMOUNT
                FROM V_FMSB_ATA_MAPPED ATA
                WHERE EXISTS (
                    SELECT 1
                    FROM PRECOMPUTED PRE
                    WHERE PRE.ARR_RECID = ATA.ID_COMP_1
                )
                GROUP BY ATA.ID_COMP_1
            ),
            ASC_AGGREGATED AS(
                SELECT 
                    ASCC.ID_COMP_1,
                    MAX(ASCC.ID_COMP_3) AS MAX_ID_COMP_3
                FROM V_FMSB_ASC_MAPPED ASCC
                WHERE EXISTS (
                    SELECT 1
                    FROM PRECOMPUTED PRE
                    WHERE PRE.ARR_RECID = ASCC.ID_COMP_1
                )
                GROUP BY ASCC.ID_COMP_1
            ),
            AIT_AGGREGATED AS(
                SELECT ID_COMP_1, RATE, WINDOW_ID FROM (
                    SELECT
                        AIT.ID_COMP_1,
                        TO_NUMBER(AIT.EFFECTIVE_RATE)/100 AS RATE,
                        AIT.WINDOW_ID,
                        ROW_NUMBER() OVER (
                            PARTITION BY AIT.ID_COMP_1
                            ORDER BY AIT.ID_COMP_3 DESC,
                                    CASE WHEN AIT.ID_COMP_2 = 'LOANINTEREST'
                                        THEN TO_NUMBER(AIT.ID_COMP_3)
                                        ELSE TO_NUMBER(AIT.ID_COMP_3) - 1
                                    END DESC
                        ) AS RN
                    FROM V_FMSB_AIT_LNTNEW AIT
                    WHERE EXISTS (
                        SELECT 1
                        FROM PRECOMPUTED PRE
                        WHERE PRE.ARR_RECID = AIT.ID_COMP_1
                    )
                    AND AIT.ID_COMP_3 <= V_TODAY || '.9999'
                )
                WHERE RN = 1
            ),
            AAC_AGGREGATED AS(
                SELECT 
                    AAC.ID_COMP_1,
                    MAX(AAC.ID_COMP_3) AS MAX_ID_COMP_3
                FROM V_FMSB_AAC_MAPPED AAC
                WHERE EXISTS (
                    SELECT 1
                    FROM PRECOMPUTED PRE
                    WHERE PRE.ARR_RECID = AAC.ID_COMP_1
                )
                AND ID_COMP_3 <= V_TODAY || '.9999'
                GROUP BY AAC.ID_COMP_1
            )
            SELECT
                PRE.BRN AS BRN,
                TO_NUMBER(PRE.ACCTNO) AS ACCTNO,
                0 AS LNNUM,
                TO_NUMBER(PRE.CIFNO) AS CIFNO,
                TRIM(PRE.ACNAME) AS ACNAME,
                CASE
                    WHEN PRE.ARR_STATUS IN ('CLOSE', 'PENDING.CLOSURE', 'CANCELLED') THEN 2
                    ELSE 4
                END AS STATUS,
                CALC_TYPE_VAL_FUNC(PRE.PRODUCT_STATUS, PRE.PRODUCT) AS TYPE,
                PRE.CURTYP AS CURTYP,
                ATA_AGG.MAX_AMOUNT AS ORGAMT,
                TO_NUMBER(PRE.DRLIMT) AS DRLIMT,
                0 AS HOLD,
                0 AS CBAL,
                0 AS OTHCHG,
                0 AS ACCINT,
                0 AS COMACC,
                CALC_PMTAMT_VAL_FUNC(ASCC.CALC_AMOUNT) AS PMTAMT,
                '' AS FNLPMT,
                0 AS BILPRN,
                0 AS BILINT,
                0 AS BILESC,
                0 AS BILLC,
                0 AS BILOC,
                0 AS BILMC,
                0 AS BILLCO,
                0 AS YSOBAL,
                TO_NUMBER(TO_CHAR(NVL(PRE.ORIG_CONTRACT_DATE, PRE.OPENING_DATE), 'YYYYDDD')) AS DATOPN,
                NVL(
                    TO_NUMBER(TO_CHAR(ARC.MIN_EFF_DAT, 'YYYYDDD')),
                    TO_NUMBER(TO_CHAR(TO_DATE(V_TODAY, 'YYYYMMDD'), 'YYYYDDD'))
                ) AS FRELDT,
                NVL(
                    TO_NUMBER(TO_CHAR(ARC.MAX_EFF_DAT, 'YYYYDDD')),
                    TO_NUMBER(TO_CHAR(TO_DATE(V_TODAY, 'YYYYMMDD'), 'YYYYDDD'))
                ) AS FULLDT,
                TO_NUMBER(TO_CHAR(NVL(ATA.MSB_OR_LNMAT_DT, ATA.MATURITY_DATE), 'YYYYDDD')) AS MATDT,
                AIT.RATE AS RATE,
                '' AS LCTYPE,
                '' AS ACCMLC,
                SUBSTR(ATA.TERM, 1, LENGTH(ATA.TERM)-1) AS TERM,
                SUBSTR(ATA.TERM, -1) AS TMCODE,
                CALC_FREQ_VAL_FUNC(ASCC.BILL_TYPE, ASCC.PROPERTY, ASCC.PAYMENT_FREQ) AS FREQ,
                CALC_IPFREQ_VAL_FUNC(ASCC.BILL_TYPE, ASCC.PROPERTY, ASCC.PAYMENT_FREQ) AS IPFREQ,
                'A' AS ODIND,
                AAC.MSB_LN_PURPOSE AS PURCOD,
                PRE.WINDOW_ID,
                PRE.COMMIT_TS,
                PRE.REPLICAT_TS,
                PRE.MAPPED_TS,
                'AIT'
            FROM PRECOMPUTED PRE
            LEFT JOIN AIT_AGGREGATED AIT ON AIT.ID_COMP_1 = PRE.ARR_RECID AND AIT.WINDOW_ID = PRE.WINDOW_ID
            LEFT JOIN ARC_AGGREGATED ARC ON ARC.ARRANGEMENT = PRE.ARR_RECID
            LEFT JOIN ATA_AGGREGATED ATA_AGG ON ATA_AGG.ID_COMP_1 = PRE.ARR_RECID
            LEFT JOIN V_FMSB_ATA_MAPPED ATA ON ATA.ID_COMP_1 = ATA_AGG.ID_COMP_1 AND ATA.ID_COMP_3 = ATA_AGG.MIN_ID_COMP_3
            LEFT JOIN ASC_AGGREGATED ASCC_AGG ON ASCC_AGG.ID_COMP_1 = PRE.ARR_RECID
            LEFT JOIN V_FMSB_ASC_MAPPED ASCC ON ASCC.ID_COMP_1 = ASCC_AGG.ID_COMP_1 AND ASCC.ID_COMP_3 = ASCC_AGG.MAX_ID_COMP_3
            LEFT JOIN AAC_AGGREGATED AAC_AGG ON AAC_AGG.ID_COMP_1 = PRE.ARR_RECID
            LEFT JOIN V_FMSB_AAC_MAPPED AAC ON AAC.ID_COMP_1 = AAC_AGG.ID_COMP_1 AND AAC.ID_COMP_3 = AAC_AGG.MAX_ID_COMP_3;

            DELETE FROM T24_LNTNEW_ACTIVITY_AIT CDC
            WHERE EXISTS (
                SELECT 1
                FROM TABLE(V_WINDOW_ID_LIST) V
                WHERE V.COLUMN_VALUE = CDC.WINDOW_ID
            );

            COMMIT;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END GEN_FROM_AIT_PROC;

---------------------------------------------------------------------------
-- GEN_FROM_ASC_PROC
---------------------------------------------------------------------------   
    PROCEDURE GEN_FROM_ASC_PROC IS
        V_WINDOW_ID_LIST T_WINDOW_ID_ARRAY;
        V_TODAY          VARCHAR2(8);
    BEGIN
        SELECT CDC.WINDOW_ID
        BULK COLLECT INTO V_WINDOW_ID_LIST
        FROM T24_LNTNEW_ACTIVITY_ASC CDC
        WHERE EXISTS (
            SELECT 1
            FROM V_FMSB_ASC_MAPPED ASCC
            WHERE ASCC.RECID = CDC.RECID
            AND CDC.WINDOW_ID <= ASCC.WINDOW_ID
        );
        -- ) FETCH FIRST 5000 ROWS ONLY;

        IF V_WINDOW_ID_LIST.COUNT > 0 THEN
        	SYS.DBMS_SESSION.SLEEP(0.2);
            SELECT /*+ RESULT_CACHE */ TODAY INTO V_TODAY
            FROM F_DAT_MAPPED
            WHERE RECID = 'VN0011000';

            INSERT INTO T24_LNTNEW_ACTIVITY (
                BRN, ACCTNO, LNNUM, CIFNO, ACNAME, STATUS, TYPE,
                CURTYP, ORGAMT, DRLIMT, HOLD, CBAL, OTHCHG,
                ACCINT, COMACC, PMTAMT, FNLPMT, BILPRN, BILINT,
                BILESC, BILLC, BILOC, BILMC, BILLCO, YSOBAL,
                DATOPN, FRELDT, FULLDT, MATDT, RATE, LCTYPE,
                ACCMLC, TERM, TMCODE, FREQ, IPFREQ, ODIND, PURCOD,
                WINDOW_ID, COMMIT_TS, REPLICAT_TS, MAPPED_TS, CALL_CDC
            )
            WITH /*+ MATERIALIZE */ PRECOMPUTED AS (
                SELECT
                    ACC.CO_CODE             AS BRN,
                    ARR.LINKED_APPL_ID      AS ACCTNO,
                    ARR.RECID               AS ARR_RECID,
                    ACC.CUSTOMER            AS CIFNO,
                    ACC.ACNAME              AS ACNAME,
                    ARR.ARR_STATUS          AS ARR_STATUS,
                    ARR.PRODUCT_STATUS      AS PRODUCT_STATUS, 
                    ARR.PRODUCT             AS PRODUCT,                
                    ACC.CURRENCY            AS CURTYP,
                    LMT.INTERNAL_AMOUNT     AS DRLIMT,
                    ARR.ORIG_CONTRACT_DATE  AS ORIG_CONTRACT_DATE,
                    ACC.OPENING_DATE        AS OPENING_DATE,
                    ASCC.WINDOW_ID          AS WINDOW_ID,
                    ASCC.COMMIT_TS          AS COMMIT_TS,
                    ASCC.REPLICAT_TS        AS REPLICAT_TS,
                    ASCC.MAPPED_TS          AS MAPPED_TS
                FROM TABLE(V_WINDOW_ID_LIST) V
                JOIN V_FMSB_ASC_MAPPED ASCC ON ASCC.WINDOW_ID = V.COLUMN_VALUE
                LEFT JOIN V_FMSB_ARR_LNTNEW ARR ON ARR.RECID = ASCC.ID_COMP_1
                JOIN V_FMSB_ACC_MAPPED ACC ON ACC.RECID = ARR.LINKED_APPL_ID
                LEFT JOIN V_FMSB_LMT_MAPPED LMT ON LMT.RECID = ACC.LIMIT_KEY
                WHERE ARR.START_DATE >= V_TODAY
            ), 
            ARC_AGGREGATED AS (
                SELECT 
                    ARC.ARRANGEMENT,
                    MIN(ARC.EFFECTIVE_DATE) AS MIN_EFF_DAT,
                    MAX(ARC.EFFECTIVE_DATE) AS MAX_EFF_DAT
                FROM V_FMSB_ARC_LNTNEW ARC
                WHERE EXISTS (
                    SELECT 1
                    FROM PRECOMPUTED PRE
                    WHERE PRE.ARR_RECID = ARC.ARRANGEMENT
                )
                AND EFFECTIVE_DATE <= TO_DATE(V_TODAY, 'YYYYMMDD')
                GROUP BY ARC.ARRANGEMENT
            ),
            ATA_AGGREGATED AS (
                SELECT 
                    ATA.ID_COMP_1,
                    MIN(ATA.ID_COMP_3) AS MIN_ID_COMP_3,
                    MAX(CASE 
                            WHEN ATA.ACTIVITY IN ('LENDING-NEW-ARRANGEMENT','LENDING-TAKEOVER-ARRANGEMENT')
                            THEN TO_NUMBER(ATA.AMOUNT)
                            ELSE 0
                        END) AS MAX_AMOUNT
                FROM V_FMSB_ATA_MAPPED ATA
                WHERE EXISTS (
                    SELECT 1
                    FROM PRECOMPUTED PRE
                    WHERE PRE.ARR_RECID = ATA.ID_COMP_1
                )
                GROUP BY ATA.ID_COMP_1
            ),
            ASC_AGGREGATED AS(
                SELECT ID_COMP_1, ID_COMP_3, BILL_TYPE, PROPERTY, PAYMENT_FREQ, CALC_AMOUNT, WINDOW_ID
                FROM (
                    SELECT
                        ASCC.ID_COMP_1,
                        ASCC.ID_COMP_3,
                        ASCC.BILL_TYPE,
                        ASCC.PROPERTY,
                        ASCC.PAYMENT_FREQ,
                        ASCC.CALC_AMOUNT,
                        ASCC.WINDOW_ID,
                        ROW_NUMBER() OVER (
                            PARTITION BY ASCC.ID_COMP_1
                            ORDER BY TO_NUMBER(ASCC.ID_COMP_3) DESC
                        ) AS RN
                    FROM V_FMSB_ASC_MAPPED ASCC
                    WHERE EXISTS (
                        SELECT 1
                        FROM PRECOMPUTED PRE
                        WHERE PRE.ARR_RECID = ASCC.ID_COMP_1
                    )
                )
                WHERE RN = 1
            ),
            AIT_AGGREGATED AS(
                SELECT ID_COMP_1, RATE FROM (
                    SELECT
                        AIT.ID_COMP_1,
                        TO_NUMBER(AIT.EFFECTIVE_RATE)/100 AS RATE,
                        ROW_NUMBER() OVER (
                            PARTITION BY AIT.ID_COMP_1
                            ORDER BY AIT.ID_COMP_3 DESC,
                                    CASE WHEN AIT.ID_COMP_2 = 'LOANINTEREST'
                                        THEN TO_NUMBER(AIT.ID_COMP_3)
                                        ELSE TO_NUMBER(AIT.ID_COMP_3) - 1
                                    END DESC
                        ) AS RN
                    FROM V_FMSB_AIT_LNTNEW AIT
                    WHERE EXISTS (
                        SELECT 1
                        FROM PRECOMPUTED PRE
                        WHERE PRE.ARR_RECID = AIT.ID_COMP_1
                    )
                    AND AIT.ID_COMP_3 <= V_TODAY || '.9999'
                )
                WHERE RN = 1
            ),
            AAC_AGGREGATED AS(
                SELECT 
                    AAC.ID_COMP_1,
                    MAX(AAC.ID_COMP_3) AS MAX_ID_COMP_3
                FROM V_FMSB_AAC_MAPPED AAC
                WHERE EXISTS (
                    SELECT 1
                    FROM PRECOMPUTED PRE
                    WHERE PRE.ARR_RECID = AAC.ID_COMP_1
                )
                AND ID_COMP_3 <= V_TODAY || '.9999'
                GROUP BY AAC.ID_COMP_1
            )
            SELECT
                PRE.BRN AS BRN,
                TO_NUMBER(PRE.ACCTNO) AS ACCTNO,
                0 AS LNNUM,
                TO_NUMBER(PRE.CIFNO) AS CIFNO,
                TRIM(PRE.ACNAME) AS ACNAME,
                CASE
                    WHEN PRE.ARR_STATUS IN ('CLOSE', 'PENDING.CLOSURE', 'CANCELLED') THEN 2
                    ELSE 4
                END AS STATUS,
                CALC_TYPE_VAL_FUNC(PRE.PRODUCT_STATUS, PRE.PRODUCT) AS TYPE,
                PRE.CURTYP AS CURTYP,
                ATA_AGG.MAX_AMOUNT AS ORGAMT,
                TO_NUMBER(PRE.DRLIMT) AS DRLIMT,
                0 AS HOLD,
                0 AS CBAL,
                0 AS OTHCHG,
                0 AS ACCINT,
                0 AS COMACC,
                CALC_PMTAMT_VAL_FUNC(ASCC.CALC_AMOUNT) AS PMTAMT,
                '' AS FNLPMT,
                0 AS BILPRN,
                0 AS BILINT,
                0 AS BILESC,
                0 AS BILLC,
                0 AS BILOC,
                0 AS BILMC,
                0 AS BILLCO,
                0 AS YSOBAL,
                TO_NUMBER(TO_CHAR(NVL(PRE.ORIG_CONTRACT_DATE, PRE.OPENING_DATE), 'YYYYDDD')) AS DATOPN,
                NVL(
                    TO_NUMBER(TO_CHAR(ARC.MIN_EFF_DAT, 'YYYYDDD')),
                    TO_NUMBER(TO_CHAR(TO_DATE(V_TODAY, 'YYYYMMDD'), 'YYYYDDD'))
                ) AS FRELDT,
                NVL(
                    TO_NUMBER(TO_CHAR(ARC.MAX_EFF_DAT, 'YYYYDDD')),
                    TO_NUMBER(TO_CHAR(TO_DATE(V_TODAY, 'YYYYMMDD'), 'YYYYDDD'))
                ) AS FULLDT,
                TO_NUMBER(TO_CHAR(NVL(ATA.MSB_OR_LNMAT_DT, ATA.MATURITY_DATE), 'YYYYDDD')) AS MATDT,
                AIT.RATE AS RATE,
                '' AS LCTYPE,
                '' AS ACCMLC,
                SUBSTR(ATA.TERM, 1, LENGTH(ATA.TERM)-1) AS TERM,
                SUBSTR(ATA.TERM, -1) AS TMCODE,
                CALC_FREQ_VAL_FUNC(ASCC.BILL_TYPE, ASCC.PROPERTY, ASCC.PAYMENT_FREQ) AS FREQ,
                CALC_IPFREQ_VAL_FUNC(ASCC.BILL_TYPE, ASCC.PROPERTY, ASCC.PAYMENT_FREQ) AS IPFREQ,
                'A' AS ODIND,
                AAC.MSB_LN_PURPOSE AS PURCOD,
                PRE.WINDOW_ID,
                PRE.COMMIT_TS,
                PRE.REPLICAT_TS,
                PRE.MAPPED_TS,
                'ASC'
            FROM PRECOMPUTED PRE
            LEFT JOIN ASC_AGGREGATED ASCC ON ASCC.ID_COMP_1 = PRE.ARR_RECID and ASCC.WINDOW_ID = PRE.WINDOW_ID
            LEFT JOIN ARC_AGGREGATED ARC ON ARC.ARRANGEMENT = PRE.ARR_RECID
            LEFT JOIN ATA_AGGREGATED ATA_AGG ON ATA_AGG.ID_COMP_1 = PRE.ARR_RECID
            LEFT JOIN V_FMSB_ATA_MAPPED ATA ON ATA.ID_COMP_1 = ATA_AGG.ID_COMP_1 AND ATA.ID_COMP_3 = ATA_AGG.MIN_ID_COMP_3
            LEFT JOIN AAC_AGGREGATED AAC_AGG ON AAC_AGG.ID_COMP_1 = PRE.ARR_RECID
            LEFT JOIN V_FMSB_AAC_MAPPED AAC ON AAC.ID_COMP_1 = AAC_AGG.ID_COMP_1 AND AAC.ID_COMP_3 = AAC_AGG.MAX_ID_COMP_3
            LEFT JOIN AIT_AGGREGATED AIT ON AIT.ID_COMP_1 = PRE.ARR_RECID;

            DELETE FROM T24_LNTNEW_ACTIVITY_ASC CDC
            WHERE EXISTS (
                SELECT 1
                FROM TABLE(V_WINDOW_ID_LIST) V
                WHERE V.COLUMN_VALUE = CDC.WINDOW_ID
            );

            COMMIT;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END GEN_FROM_ASC_PROC;      
    
END T24_LNTNEW_ACTIVITY_PKG;
