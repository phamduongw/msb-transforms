CREATE OR REPLACE PACKAGE T24DB_OGGDS.T24_LNTNEW_ACTIVITY_PKG IS

    FUNCTION CALC_PMTAMT_VAL_FUNC(
        P_CALC_AMOUNT   IN VARCHAR2
    ) RETURN NUMBER;

    FUNCTION CALC_TYPE_VAL_FUNC(
        P_PRODUCT_STATUS IN VARCHAR2,
        P_PRODUCT        IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION CALC_FREQ_VAL_FUNC(
        P_BILL_TYPE    IN VARCHAR2,
        P_PROPERTY IN VARCHAR2,
        P_PAYMENT_FREQ IN VARCHAR2
    ) RETURN NUMBER;

    FUNCTION CALC_PURCOD_VAL_FUNC(
        P_ARR_ID IN VARCHAR2,
        P_TODAY IN VARCHAR2
    ) RETURN VARCHAR2;
   
   	FUNCTION CALC_IPFREQ_VAL_FUNC(
        P_BILL_TYPE    IN VARCHAR2,
        P_PROPERTY IN VARCHAR2,
        P_PAYMENT_FREQ IN VARCHAR2
    ) RETURN NUMBER;

    PROCEDURE GEN_FROM_ACC_PROC;

    PROCEDURE GEN_FROM_ARR_PROC;

END T24_LNTNEW_ACTIVITY_PKG;

CREATE OR REPLACE PACKAGE BODY T24DB_OGGDS.T24_LNTNEW_ACTIVITY_PKG IS 

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
        V_HASH_IDX := INSTR(P_CALC_AMOUNT, '#', V_COLON_IDX);
        IF V_HASH_IDX = 0 THEN
            V_HASH_IDX := V_LEN + 1;
        END IF;

        V_POS := SUBSTR(P_CALC_AMOUNT, 1, V_COLON_IDX - 1);
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
        V_POS            VARCHAR2(6);
        V_PRODUCT_STATUS  VARCHAR2(255);
    BEGIN
        IF P_PRODUCT_STATUS IS NULL THEN
            RETURN 0;
        END IF;

        WHILE V_START <= V_LEN LOOP
            V_COLON_IDX := INSTR(P_PRODUCT_STATUS, ':', V_START) + 1;
            V_HASH_IDX := INSTR(P_PRODUCT_STATUS, '#', V_COLON_IDX);

            IF V_HASH_IDX = 0 THEN
                V_HASH_IDX := V_LEN + 1;
            END IF;

            V_POS := SUBSTR(P_PRODUCT_STATUS, V_START, V_COLON_IDX - V_START);
            V_PRODUCT_STATUS := SUBSTR(P_PRODUCT_STATUS, V_COLON_IDX, V_HASH_IDX - V_COLON_IDX);

            IF V_PRODUCT_STATUS IN ('CURRENT')
             THEN
                V_TYPE :=  T24_UTILS_PKG.GET_STR_VAL_BY_POS_FUNC(P_PRODUCT, V_POS);
            END IF;

            V_START := V_HASH_IDX;
        END LOOP;

        RETURN V_TYPE;
    END CALC_TYPE_VAL_FUNC;

    FUNCTION CALC_FREQ_VAL_FUNC(
        P_BILL_TYPE    IN VARCHAR2,
        P_PROPERTY IN VARCHAR2,
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

            V_POS        := SUBSTR(P_BILL_TYPE, V_START, V_COLON_IDX - V_START);
            V_BILL_TYPE    := SUBSTR(P_BILL_TYPE, V_COLON_IDX, V_HASH_IDX - V_COLON_IDX);
            V_PROPERTY     := T24_UTILS_PKG.GET_STR_VAL_BY_POS_FUNC(P_PROPERTY, V_POS);

            IF V_BILL_TYPE IN ('INSTALLMENT','INVESTORBILL','PAYMENT')
            AND V_PROPERTY = 'ACCOUNT'
            THEN
                V_PAYMENT_FREQ := T24_UTILS_PKG.GET_STR_VAL_BY_POS_FUNC(P_PAYMENT_FREQ, V_POS);
               
               	IF V_PAYMENT_FREQ IS NOT NULL THEN

	                V_GROUP_1 := REGEXP_SUBSTR(V_PAYMENT_FREQ,'(\S+)',1,1);
	                V_GROUP_2 := REGEXP_SUBSTR(V_PAYMENT_FREQ,'(\S+)',1,2);
	                V_GROUP_3 := REGEXP_SUBSTR(V_PAYMENT_FREQ,'(\S+)',1,3);
	                V_GROUP_4 := REGEXP_SUBSTR(V_PAYMENT_FREQ,'(\S+)',1,4);
	                V_GROUP_5 := REGEXP_SUBSTR(V_PAYMENT_FREQ,'(\S+)',1,5);
	
	                D_GROUP_1 := TO_NUMBER(REGEXP_SUBSTR(V_GROUP_1,'\d+'));
	                D_GROUP_2 := TO_NUMBER(REGEXP_SUBSTR(V_GROUP_2,'\d+'));
	                D_GROUP_3 := TO_NUMBER(REGEXP_SUBSTR(V_GROUP_3,'\d+'));
	                D_GROUP_4 := TO_NUMBER(REGEXP_SUBSTR(V_GROUP_4,'\d+'));
	                D_GROUP_5 := TO_NUMBER(REGEXP_SUBSTR(V_GROUP_5,'\d+'));
	
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

    FUNCTION CALC_PURCOD_VAL_FUNC(
        P_ARR_ID IN VARCHAR2,
        P_TODAY IN VARCHAR2
    ) RETURN VARCHAR2 IS
        V_MAX_DATE VARCHAR2(8) := '00000000';
        V_RESULT   VARCHAR2(5);
    BEGIN
        FOR rec IN (
            SELECT SUBSTR(ID_COMP_3,1,8) as ID_COMP_3_DATE, MSB_LN_PURPOSE
            FROM FMSB_AAC_MAPPED
            WHERE ID_COMP_1 = P_ARR_ID
            AND SUBSTR(ID_COMP_3,1,8) <= P_TODAY
            ORDER BY SUBSTR(ID_COMP_3,1,8)
        ) LOOP
            IF rec.ID_COMP_3_DATE >= V_MAX_DATE THEN
                V_MAX_DATE := rec.ID_COMP_3_DATE;
                V_RESULT   := rec.MSB_LN_PURPOSE;              	
            END IF;
        END LOOP;

        RETURN V_RESULT;
    END CALC_PURCOD_VAL_FUNC;
   
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
        V_GROUP_1        VARCHAR2(15);
        V_GROUP_2        VARCHAR2(15);
        V_GROUP_3        VARCHAR2(15);
        V_GROUP_4        VARCHAR2(15);
        V_GROUP_5        VARCHAR2(15);
        D_GROUP_1        NUMBER;
        D_GROUP_2        NUMBER;
        D_GROUP_3        NUMBER;
        D_GROUP_4        NUMBER;
        D_GROUP_5        NUMBER;
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

            V_POS := SUBSTR(P_BILL_TYPE, V_START, V_COLON_IDX - V_START);
            V_BILL_TYPE := SUBSTR(P_BILL_TYPE, V_COLON_IDX, V_HASH_IDX - V_COLON_IDX);
            V_PROPERTY      := T24_UTILS_PKG.GET_STR_VAL_BY_POS_FUNC(P_PROPERTY, V_POS);

            IF V_BILL_TYPE IN ('INSTALLMENT','INVESTORBILL','PAYMENT')
            AND V_PROPERTY IN ('LOANINTEREST','LNINTPREBUY','INVESTORINT','RISKINTEREST')
            THEN
                V_PAYMENT_FREQ := T24_UTILS_PKG.GET_STR_VAL_BY_POS_FUNC(P_PAYMENT_FREQ, V_POS);
               	
                IF V_PAYMENT_FREQ IS NOT NULL THEN
	
	                V_GROUP_1 := REGEXP_SUBSTR(V_PAYMENT_FREQ,'(\S+)',1,1);
	                V_GROUP_2 := REGEXP_SUBSTR(V_PAYMENT_FREQ,'(\S+)',1,2);
	                V_GROUP_3 := REGEXP_SUBSTR(V_PAYMENT_FREQ,'(\S+)',1,3);
	                V_GROUP_4 := REGEXP_SUBSTR(V_PAYMENT_FREQ,'(\S+)',1,4);
	                V_GROUP_5 := REGEXP_SUBSTR(V_PAYMENT_FREQ,'(\S+)',1,5);
	
	                D_GROUP_1 := TO_NUMBER(REGEXP_SUBSTR(V_GROUP_1,'\d+'));
	                D_GROUP_2 := TO_NUMBER(REGEXP_SUBSTR(V_GROUP_2,'\d+'));
	                D_GROUP_3 := TO_NUMBER(REGEXP_SUBSTR(V_GROUP_3,'\d+'));
	                D_GROUP_4 := TO_NUMBER(REGEXP_SUBSTR(V_GROUP_4,'\d+'));
	                D_GROUP_5 := TO_NUMBER(REGEXP_SUBSTR(V_GROUP_5,'\d+'));
	
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

    PROCEDURE GEN_FROM_ACC_PROC IS
        V_WINDOW_ID_LIST T_WINDOW_ID_ARRAY;
        V_TODAY          VARCHAR2(8);
    BEGIN
        DELETE FROM T24_LNTNEW_ACTIVITY_ACC CDC
        WHERE EXISTS (
            SELECT 1 FROM FMSB_ACC_MAPPED ACC
            WHERE ACC.RECID = CDC.RECID AND CDC.WINDOW_ID <= ACC.WINDOW_ID
        )
        AND ROWNUM <= 5000
        RETURNING CDC.WINDOW_ID BULK COLLECT INTO V_WINDOW_ID_LIST;
    
        SELECT TODAY INTO V_TODAY
        FROM F_DAT_MAPPED
        WHERE RECID = 'VN0011000';

        INSERT INTO T24_LNTNEW_ACTIVITY (
            BRN, ACCTNO, LNNUM, CIFNO, ACNAME, STATUS, TYPE,
            CURTYP, ORGAMT, DRLIMT, HOLD, CBAL, OTHCHG,
            ACCINT, COMACC, PMTAMT, FNLPMT, BILPRN, BILINT,
            BILESC, BILLC, BILOC, BILMC, BILLCO, YSOBAL,
            DATOPN, FRELDT, FULLDT, MATDT, RATE, LCTYPE,
            ACCMLC, TERM, TMCODE, FREQ, IPFREQ, ODIND, PURCOD,
            WINDOW_ID,COMMIT_TS,REPLICAT_TS,MAPPED_TS,CALL_CDC
        )
        SELECT
            ACC.CO_CODE, --BRN
            TO_NUMBER(ACC.RECID), --ACCTNO
            0, --LNNUM
            TO_NUMBER(ACC.CUSTOMER), --CIFNO
            TRIM(ACC.ACNAME), --ACNAME
            CASE
                WHEN ARR.ARR_STATUS IN ('CLOSE', 'PENDING.CLOSURE', 'CANCELLED') THEN 2
                ELSE 4
            END, --STATUS
            CALC_TYPE_VAL_FUNC(ARR.PRODUCT_STATUS, ARR.PRODUCT), --TYPE
            ACC.CURRENCY, --CURTYP
            ( 
                SELECT TO_NUMBER(ATA.ORGAMT) 
--                FROM MV_FMSB_ATA_LNTNEW ATA
				FROM VW_FMSB_ATA_LNTNEW ATA
                WHERE ATA.ID_COMP_1 = ARR.RECID
            ), --ORGAMT
            TO_NUMBER(LMT.INTERNAL_AMOUNT), --DRLIMT
            0, --HOLD
            0, --CBAL
            0, --OTHCHG
            0, --ACCINT
            0, --COMACC
            (
                SELECT T24_LNTNEW_ACTIVITY_PKG.CALC_PMTAMT_VAL_FUNC(ASCC.CALC_AMOUNT)
                FROM FMSB_ASC_MAPPED ASCC
                WHERE ASCC.ID_COMP_1 = ARR.RECID
                AND ASCC.ID_COMP_3 = (
                    SELECT MV.MAX_ID_COMP_3
--                    FROM MV_FMSB_ASC_LNTNEW MV
					FROM VW_FMSB_ASC_LNTNEW MV
                    WHERE MV.ID_COMP_1 = ASCC.ID_COMP_1
                )                
            ), --PMTAMT
            '', --FNLPMT
            0, --BILPRN
            0, --BILINT
            0, --BILESC
            0, --BILLC
            0, --BILOC
            0, --BILMC
            0, --BILLCO
            0, --YSOBAL
            TO_NUMBER(TO_CHAR(NVL(ARR.ORIG_CONTRACT_DATE, ACC.OPENING_DATE), 'YYYYDDD')), --DATOPN 
            (
                SELECT TO_NUMBER(TO_CHAR(MIN_EFF_DAT, 'YYYYDDD'))
--                FROM MV_FMSB_ARC_LNTNEW
				FROM VW_FMSB_ARC_LNTNEW
                WHERE ARRANGEMENT = ARR.RECID
                AND MIN_EFF_DAT <= TO_DATE(V_TODAY, 'YYYYMMDD')
            ), --FRELDT
            (
            	SELECT TO_NUMBER(TO_CHAR(MAX(EFFECTIVE_DATE), 'YYYYDDD'))
				FROM FMSB_ARC_LNTNEW
				WHERE ARRANGEMENT = ARR.RECID
				AND EFFECTIVE_DATE <= TO_DATE(V_TODAY,'YYYYMMDD')
                GROUP BY ARRANGEMENT
            ), --FULDT
            (
                SELECT TO_NUMBER(TO_CHAR(NVL(ATA.MSB_OR_LNMAT_DT, ATA.MATURITY_DATE), 'YYYYDDD'))
                FROM FMSB_ATA_MAPPED ATA
                WHERE ID_COMP_1 = ARR.RECID
                AND ATA.ID_COMP_3 = (
                    SELECT MV.MIN_ID_COMP_3
--                    FROM MV_FMSB_ATA_LNTNEW MV
					FROM VW_FMSB_ATA_LNTNEW MV
                    WHERE MV.ID_COMP_1 = ATA.ID_COMP_1                    
                )
            ), --MATDT
            (
				SELECT RATE 
				FROM(
					SELECT TO_NUMBER(AIT.EFFECTIVE_RATE) / 100 AS RATE,
					ROW_NUMBER() OVER (
						PARTITION BY AIT.ID_COMP_1 
						ORDER BY AIT.ID_COMP_3 DESC, 
							(CASE WHEN AIT.ID_COMP_2 = 'LOANINTEREST' THEN to_number(AIT.ID_COMP_3) else to_number(AIT.ID_COMP_3) - 1  end) DESC) AS row_num
						FROM FMSB_AIT_LNTNEW AIT
						where AIT.ID_COMP_1 = ARR.RECID
						-- and AIT.ID_COMP_2 in ('DEPOSITINT', 'LOANINTEREST','LNINTPREBUY','INVESTORINT','RISKINTEREST')
						and TO_DATE(REGEXP_SUBSTR(AIT.ID_COMP_3, '[^.]+', 1, 1), 'YYYYMMDD') <= TO_DATE(V_TODAY,'YYYYMMDD')
				)WHERE row_num = 1          	
            ), --RATE
            '', --LCTYPE
            '',--ACCMLC
            (
                SELECT REGEXP_SUBSTR(ATA.TERM, '\d+',1)
                FROM FMSB_ATA_MAPPED ATA
                WHERE ATA.ID_COMP_1 = ARR.RECID
                AND ATA.ID_COMP_3 = (
                    SELECT MV.MIN_ID_COMP_3
--                    FROM MV_FMSB_ATA_LNTNEW MV
					FROM VW_FMSB_ATA_LNTNEW MV 
                    WHERE MV.ID_COMP_1 = ATA.ID_COMP_1                    
                )
            ), --TERM
            (
                SELECT REGEXP_SUBSTR(ATA.TERM, '\D+',1)
                FROM FMSB_ATA_MAPPED ATA
                WHERE ATA.ID_COMP_1 = ARR.RECID
                AND ATA.ID_COMP_3 = (
                    SELECT MV.MIN_ID_COMP_3
--                    FROM MV_FMSB_ATA_LNTNEW MV
					FROM VW_FMSB_ATA_LNTNEW MV 
                    WHERE MV.ID_COMP_1 = ATA.ID_COMP_1                    
                )
            ), --TMCODE
            (
                SELECT T24_LNTNEW_ACTIVITY_PKG.CALC_FREQ_VAL_FUNC(ASCC.BILL_TYPE, ASCC.PROPERTY, ASCC.PAYMENT_FREQ)
                FROM FMSB_ASC_MAPPED ASCC
                WHERE ASCC.ID_COMP_1 = ARR.RECID
                AND ASCC.ID_COMP_3 = (
                    SELECT MV.MAX_ID_COMP_3
--                    FROM MV_FMSB_ASC_LNTNEW MV
					FROM VW_FMSB_ASC_LNTNEW MV 
                    WHERE MV.ID_COMP_1 = ASCC.ID_COMP_1
                )
            ), --FREQ
            (
                SELECT T24_LNTNEW_ACTIVITY_PKG.CALC_IPFREQ_VAL_FUNC(ASCC.BILL_TYPE, ASCC.PROPERTY, ASCC.PAYMENT_FREQ)
                FROM FMSB_ASC_MAPPED ASCC
                WHERE ASCC.ID_COMP_1 = ARR.RECID
                AND ASCC.ID_COMP_3 = (
                    SELECT MV.MAX_ID_COMP_3
--                    FROM MV_FMSB_ASC_LNTNEW MV
					FROM VW_FMSB_ASC_LNTNEW MV 
                    WHERE MV.ID_COMP_1 = ASCC.ID_COMP_1
                )            
            ), --IPFREQ
            'A', --ODIND
            CALC_PURCOD_VAL_FUNC(ARR.RECID, V_TODAY), --PURCOD
            ACC.WINDOW_ID,
            ACC.COMMIT_TS,
            ACC.REPLICAT_TS,
            ACC.MAPPED_TS,
            'ACC'
        FROM TABLE(V_WINDOW_ID_LIST) V
	        JOIN FMSB_ACC_MAPPED ACC ON ACC.WINDOW_ID = V.COLUMN_VALUE
	        JOIN FMSB_ARR_LNTNEW ARR ON ARR.LINKED_APPL_ID = ACC.RECID
	        LEFT JOIN FMSB_LMT_MAPPED LMT ON LMT.RECID = ACC.LIMIT_KEY
        WHERE ARR.START_DATE >= V_TODAY;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END GEN_FROM_ACC_PROC;

    PROCEDURE GEN_FROM_ARR_PROC IS
        V_WINDOW_ID_LIST T_WINDOW_ID_ARRAY;
        V_TODAY          VARCHAR2(8);
    BEGIN
        DELETE FROM T24_LNTNEW_ACTIVITY_ARR CDC
        WHERE EXISTS (
            SELECT 1 FROM FMSB_ARR_LNTNEW ARR
            WHERE ARR.RECID = CDC.RECID AND CDC.WINDOW_ID <= ARR.WINDOW_ID
        )
        AND ROWNUM <= 5000
        RETURNING CDC.WINDOW_ID BULK COLLECT INTO V_WINDOW_ID_LIST;
    
        SELECT TODAY INTO V_TODAY
        FROM F_DAT_MAPPED
        WHERE RECID = 'VN0011000';

        INSERT INTO T24_LNTNEW_ACTIVITY (
            BRN, ACCTNO, LNNUM, CIFNO, ACNAME, STATUS, TYPE,
            CURTYP, ORGAMT, DRLIMT, HOLD, CBAL, OTHCHG,
            ACCINT, COMACC, PMTAMT, FNLPMT, BILPRN, BILINT,
            BILESC, BILLC, BILOC, BILMC, BILLCO, YSOBAL,
            DATOPN, FRELDT, FULLDT, MATDT, RATE, LCTYPE,
            ACCMLC, TERM, TMCODE, FREQ, IPFREQ, ODIND, PURCOD,
            WINDOW_ID,COMMIT_TS,REPLICAT_TS,MAPPED_TS,CALL_CDC
        )
        SELECT
            ACC.CO_CODE, --BRN
            TO_NUMBER(ARR.LINKED_APPL_ID), --ACCTNO
            0, --LNNUM
            TO_NUMBER(ACC.CUSTOMER), --CIFNO
            TRIM(ACC.ACNAME), --ACNAME
            CASE
                WHEN ARR.ARR_STATUS IN ('CLOSE', 'PENDING.CLOSURE', 'CANCELLED') THEN 2
                ELSE 4
            END, --STATUS
            CALC_TYPE_VAL_FUNC(ARR.PRODUCT_STATUS, ARR.PRODUCT), --TYPE
            ACC.CURRENCY, --CURTYP
            (
                SELECT TO_NUMBER(ATA.ORGAMT) 
--                FROM MV_FMSB_ATA_LNTNEW ATA
				FROM VW_FMSB_ATA_LNTNEW ATA
                WHERE ATA.ID_COMP_1 = ARR.RECID
            ), --ORIGINAL
           TO_NUMBER(LMT.INTERNAL_AMOUNT), --DRLIMT
            0, --HOLD
            0, --CBAL
            0, --OTHCHG
            0, --ACCINT
            0, --COMACC
            (
                SELECT T24_LNTNEW_ACTIVITY_PKG.CALC_PMTAMT_VAL_FUNC(ASCC.CALC_AMOUNT)
                FROM FMSB_ASC_MAPPED ASCC
                WHERE ASCC.ID_COMP_1 = ARR.RECID
                AND ASCC.ID_COMP_3 = (
                    SELECT MV.MAX_ID_COMP_3
--                    FROM MV_FMSB_ASC_LNTNEW MV
					FROM VW_FMSB_ASC_LNTNEW MV
                    WHERE MV.ID_COMP_1 = ASCC.ID_COMP_1
                )                
            ), --PMTAMT
            '', --FNLPMT
            0, --BILPRN
            0, --BILINT
            0, --BILESC
            0, --BILLC
            0, --BILOC
            0, --BILMC
            0, --BILLCO
            0, --YSOBAL
            TO_NUMBER(TO_CHAR(NVL(ARR.ORIG_CONTRACT_DATE, ACC.OPENING_DATE), 'YYYYDDD')), --DATOPN 
            (
                SELECT TO_NUMBER(TO_CHAR(MIN_EFF_DAT, 'YYYYDDD'))
--                FROM MV_FMSB_ARC_LNTNEW
				FROM VW_FMSB_ARC_LNTNEW
                WHERE ARRANGEMENT = ARR.RECID
                AND MIN_EFF_DAT <= TO_DATE(V_TODAY, 'YYYYMMDD')
            ), --FRELDT
            (
            	SELECT TO_NUMBER(TO_CHAR(MAX(EFFECTIVE_DATE), 'YYYYDDD'))
				FROM FMSB_ARC_LNTNEW
				WHERE ARRANGEMENT = ARR.RECID
				AND EFFECTIVE_DATE <= TO_DATE(V_TODAY,'YYYYMMDD')
                GROUP BY ARRANGEMENT
            ), --FULDT
            (
                SELECT TO_NUMBER(TO_CHAR(NVL(ATA.MSB_OR_LNMAT_DT, ATA.MATURITY_DATE), 'YYYYDDD'))
                FROM FMSB_ATA_MAPPED ATA
                WHERE ID_COMP_1 = ARR.RECID
                AND ATA.ID_COMP_3 = (
                    SELECT MV.MIN_ID_COMP_3
--                    FROM MV_FMSB_ATA_LNTNEW MV
					FROM VW_FMSB_ATA_LNTNEW MV
                    WHERE MV.ID_COMP_1 = ATA.ID_COMP_1                    
                )
            ), --MATDT
            (
				SELECT RATE 
				FROM(
					SELECT TO_NUMBER(AIT.EFFECTIVE_RATE) / 100 AS RATE,
					ROW_NUMBER() OVER (
						PARTITION BY AIT.ID_COMP_1 
						ORDER BY AIT.ID_COMP_3 DESC, 
							(CASE WHEN AIT.ID_COMP_2 = 'LOANINTEREST' THEN to_number(AIT.ID_COMP_3) else to_number(AIT.ID_COMP_3) - 1  end) DESC) AS row_num
						FROM FMSB_AIT_LNTNEW AIT
						where AIT.ID_COMP_1 = ARR.RECID
						-- and AIT.ID_COMP_2 in ('DEPOSITINT', 'LOANINTEREST','LNINTPREBUY','INVESTORINT','RISKINTEREST')
						and TO_DATE(REGEXP_SUBSTR(AIT.ID_COMP_3, '[^.]+', 1, 1), 'YYYYMMDD') <= TO_DATE(V_TODAY,'YYYYMMDD')
				)WHERE row_num = 1          	
            ), --RATE     
            '', --LCTYPE
            '',--ACCMLC
            (
                SELECT REGEXP_SUBSTR(ATA.TERM, '\d+',1)
                FROM FMSB_ATA_MAPPED ATA
                WHERE ATA.ID_COMP_1 = ARR.RECID
                AND ATA.ID_COMP_3 = (
                    SELECT MV.MIN_ID_COMP_3
--                    FROM MV_FMSB_ATA_LNTNEW MV
					FROM VW_FMSB_ATA_LNTNEW MV
                    WHERE MV.ID_COMP_1 = ATA.ID_COMP_1                    
                )
            ) AS TERM, --TERM
            (
                SELECT REGEXP_SUBSTR(ATA.TERM, '\D+',1)
                FROM FMSB_ATA_MAPPED ATA
                WHERE ATA.ID_COMP_1 = ARR.RECID
                AND ATA.ID_COMP_3 = (
                    SELECT MV.MIN_ID_COMP_3
--                    FROM MV_FMSB_ATA_LNTNEW MV
					FROM VW_FMSB_ATA_LNTNEW MV
                    WHERE MV.ID_COMP_1 = ATA.ID_COMP_1                    
                )
            ) AS TMCODE, --TMCODE
            (
                SELECT T24_LNTNEW_ACTIVITY_PKG.CALC_FREQ_VAL_FUNC(ASCC.BILL_TYPE, ASCC.PROPERTY, ASCC.PAYMENT_FREQ)
                FROM FMSB_ASC_MAPPED ASCC
                WHERE ASCC.ID_COMP_1 = ARR.RECID
                AND ASCC.ID_COMP_3 = (
                    SELECT MV.MAX_ID_COMP_3
--                    FROM MV_FMSB_ASC_LNTNEW MV
					FROM VW_FMSB_ASC_LNTNEW MV
                    WHERE MV.ID_COMP_1 = ASCC.ID_COMP_1
                )
            ) AS FREQ, --FREQ
            (
                SELECT T24_LNTNEW_ACTIVITY_PKG.CALC_IPFREQ_VAL_FUNC(ASCC.BILL_TYPE, ASCC.PROPERTY, ASCC.PAYMENT_FREQ)
                FROM FMSB_ASC_MAPPED ASCC
                WHERE ASCC.ID_COMP_1 = ARR.RECID
                AND ASCC.ID_COMP_3 = (
                    SELECT MV.MAX_ID_COMP_3
--                    FROM MV_FMSB_ASC_LNTNEW MV
					FROM VW_FMSB_ASC_LNTNEW MV
                    WHERE MV.ID_COMP_1 = ASCC.ID_COMP_1
                )           
            ), --IPFREQ
            'A', --ODIND
            CALC_PURCOD_VAL_FUNC(ARR.RECID, V_TODAY), --PURCOD
            ARR.WINDOW_ID,
            ARR.COMMIT_TS,
            ARR.REPLICAT_TS,
            ARR.MAPPED_TS,
            'ARR'
        FROM TABLE(V_WINDOW_ID_LIST) V
	        JOIN FMSB_ARR_LNTNEW ARR ON ARR.WINDOW_ID = V.COLUMN_VALUE
	        JOIN FMSB_ACC_MAPPED ACC ON ARR.LINKED_APPL_ID = ACC.RECID
	        LEFT JOIN FMSB_LMT_MAPPED LMT ON LMT.RECID = ACC.LIMIT_KEY
        WHERE ARR.START_DATE >= V_TODAY;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END GEN_FROM_ARR_PROC;
    
END T24_LNTNEW_ACTIVITY_PKG;
