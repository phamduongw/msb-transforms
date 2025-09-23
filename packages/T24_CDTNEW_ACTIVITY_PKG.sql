   CREATE OR REPLACE PACKAGE T24DB_OGGDS.T24_CDTNEW_ACTIVITY_PKG IS

    FUNCTION CALC_RATE_VAL_FUNC(
        P_ARR_ID IN VARCHAR2,
        P_TODAY IN VARCHAR2
    ) RETURN NUMBER;

    FUNCTION CALC_PERIODIC_PERIOD_FUNC(
        P_ARR_ID IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION CALC_TERM_FUNC(
        P_ARR_ID IN VARCHAR2
    ) RETURN VARCHAR2;

    PROCEDURE GEN_FROM_ACC_PROC;

    PROCEDURE GEN_FROM_ARR_PROC;

    PROCEDURE GEN_FROM_ATA_PROC;

END T24_CDTNEW_ACTIVITY_PKG;

CREATE OR REPLACE PACKAGE BODY T24DB_OGGDS.T24_CDTNEW_ACTIVITY_PKG IS 

    FUNCTION CALC_PERIODIC_PERIOD_FUNC(
        P_ARR_ID IN VARCHAR2
    ) RETURN VARCHAR2 IS
        V_PERIODIC_PERIOD VARCHAR2(10);
    BEGIN
        SELECT PERIODIC_PERIOD INTO V_PERIODIC_PERIOD
        FROM FMSB_AIT_CDTNEW AIT
        WHERE ID_COMP_1 = P_ARR_ID
        AND ID_COMP_3 = (
            SELECT MAX_ID_COMP_3 
            FROM VW_FMSB_AIT_CDTNEW MV
            WHERE MV.ID_COMP_1 = AIT.ID_COMP_1
        );
        RETURN V_PERIODIC_PERIOD;
    END CALC_PERIODIC_PERIOD_FUNC;

    FUNCTION CALC_TERM_FUNC(
        P_ARR_ID IN VARCHAR2
    ) RETURN VARCHAR2 IS 
        V_TERM VARCHAR2(10);
    BEGIN
        SELECT TERM INTO V_TERM
        FROM FMSB_ATA_MAPPED ATA
        WHERE ID_COMP_1 = P_ARR_ID
        AND ID_COMP_3 = (
            SELECT MIN_ID_COMP_3 
            FROM VW_FMSB_ATA_CDTNEW MV
            WHERE MV.ID_COMP_1 = ATA.ID_COMP_1
        );
        RETURN V_TERM;
    END CALC_TERM_FUNC;

    FUNCTION CALC_RATE_VAL_FUNC(
        P_ARR_ID IN VARCHAR2,
        P_TODAY IN VARCHAR2
    ) RETURN NUMBER IS
        V_MAX_DATE VARCHAR2(8) := '00000000';
        V_RESULT   NUMBER;
    BEGIN
        FOR rec IN (
            SELECT SUBSTR(ID_COMP_3,1,8) as ID_COMP_3_DATE, EFFECTIVE_RATE
            FROM FMSB_AIT_CDTNEW
            WHERE ID_COMP_1 = P_ARR_ID
            AND SUBSTR(ID_COMP_3,1,8) <= P_TODAY
            ORDER BY SUBSTR(ID_COMP_3,1,8)
        ) LOOP
            IF rec.ID_COMP_3_DATE >= V_MAX_DATE THEN
                V_MAX_DATE := rec.ID_COMP_3_DATE;
                V_RESULT   := TO_NUMBER(rec.EFFECTIVE_RATE) /100;              	
            END IF;
        END LOOP; 

        RETURN V_RESULT;
    END CALC_RATE_VAL_FUNC;

    PROCEDURE GEN_FROM_ACC_PROC IS
        V_WINDOW_ID_LIST T_WINDOW_ID_ARRAY;
        V_TODAY          VARCHAR2(8);
    BEGIN
        DELETE FROM T24_CDTNEW_ACTIVITY_ACC CDC
        WHERE EXISTS (
            SELECT 1 FROM FMSB_ACC_MAPPED ACC
            WHERE ACC.RECID = CDC.RECID AND CDC.WINDOW_ID <= ACC.WINDOW_ID
        )
        AND ROWNUM <= 5000
        RETURNING CDC.WINDOW_ID BULK COLLECT INTO V_WINDOW_ID_LIST;
    
        SELECT TODAY INTO V_TODAY
        FROM F_DAT_MAPPED
        WHERE RECID = 'VN0011000';

        INSERT INTO T24_CDTNEW_ACTIVITY (
            BANKNO, ACCTNO, ACTYPE, ACNAME, CIFNO, TYPE, BRN, STATUS,
            CDNUM, ORGBAL, CBAL, HOLD, ACCINT, WDRWH, RNWCTR, PENAMT,
            ISSDT, MATDT, CDTERM, CDTCOD, RENEW, DACTN, RATE, CURTYP, CDMUID, RS2DT7,
            WINDOW_ID,COMMIT_TS,REPLICAT_TS,MAPPED_TS,CALL_CDC
        )
        SELECT
            27, --BANKNO
            TO_NUMBER(ACC.RECID), --ACCTNO
            'T', --ACTYPE
            TRIM(ACC.ACNAME), --ACNAME
            ACC.CUSTOMER, --CIFNO
            ARR.ACTIVE_PRODUCT, --TYPE
            ACC.CO_CODE, --BRN
            CASE
                WHEN ARR.ARR_STATUS IN ('CLOSE', 'PENDING.CLOSURE', 'CANCELLED') THEN 2
                ELSE 4
            END, --STATUS
            TO_NUMBER(ACC.RECID), --CDNUM
            ( 
                SELECT TO_NUMBER(ATA.AMOUNT)
                FROM FMSB_ATA_MAPPED ATA
                WHERE ATA.ID_COMP_1 = ARR.RECID
                AND ATA.ID_COMP_3 = (
                    SELECT MV.MIN_ID_COMP_3
                    FROM VW_FMSB_ATA_CDTNEW MV
                    WHERE MV.ID_COMP_1 = ATA.ID_COMP_1
                )
            ), --ORGBAL
            0, --CBAL
            0, --HOLD
            0, --ACCINT
            0, --WDRWH
            0, --RNWCTR
            0, --PENAMT
            TO_NUMBER(TO_CHAR(ARR.START_DATE, 'YYYYDDD')), --ISSDT
            TO_NUMBER(TO_CHAR(ADL.MATURITY_DATE, 'YYYYDDD')), --MATDT
            ( 
				REGEXP_REPLACE(NVL(
                    CALC_PERIODIC_PERIOD_FUNC(ARR.RECID),
                    CALC_TERM_FUNC(ARR.RECID)),
                '[^0-9]')
            ), --CDTERM
            (
				REGEXP_REPLACE(NVL(
                    CALC_PERIODIC_PERIOD_FUNC(ARR.RECID),
                    CALC_TERM_FUNC(ARR.RECID)),
                '[^A-Z]')
            ), --CDTCOD
            (
                SELECT
                    CASE
                        WHEN CHG.CHANGE_PERIOD IS NOT NULL OR CHG.CHANGE_DATE IS NOT NULL THEN 'Y'
                        ELSE 'N'
                    END
                    FROM FMSB_CHG_MAPPED CHG
                    WHERE CHG.ID_COMP_1 = ARR.RECID
                    AND CHG.ID_COMP_3 = (
                        SELECT MV.MAX_ID_COMP_3
                        FROM VW_FMSB_CHG_CDTNEW MV
                        WHERE MV.ID_COMP_1 = CHG.ID_COMP_1 
                    )
            ), --RENEW
            '', --DACTN
            CALC_RATE_VAL_FUNC(ARR.RECID, V_TODAY), --RATE
            ARR.CURRENCY, --CURTYP
            REGEXP_SUBSTR(ACC.INPUTTER,'[^_]+',1,2), --CDMUID
            TO_NUMBER(TO_CHAR(ADL.RENEWAL_DATE, 'YYYYDDD')), --RS2DT7
            ACC.WINDOW_ID,
            ACC.COMMIT_TS,
            ACC.REPLICAT_TS,
            ACC.MAPPED_TS,
            'ACC'
        FROM TABLE(V_WINDOW_ID_LIST) V
            JOIN FMSB_ACC_MAPPED ACC ON ACC.WINDOW_ID = V.COLUMN_VALUE
            JOIN FMSB_ARR_CD ARR ON ARR.LINKED_APPL_ID = ACC.RECID
            LEFT JOIN FMSB_ADL_MAPPED ADL ON ADL.RECID = ARR.RECID
        WHERE ARR.START_DATE >= TO_DATE(V_TODAY,'YYYYMMDD');
--        WHERE ARR.START_DATE >= TO_DATE('20250917','YYYYMMDD');

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
        DELETE FROM T24_CDTNEW_ACTIVITY_ARR CDC
        WHERE EXISTS (
            SELECT 1 FROM FMSB_ARR_CD ARR
            WHERE ARR.RECID = CDC.RECID AND CDC.WINDOW_ID <= ARR.WINDOW_ID
        )
        AND ROWNUM <= 5000
        RETURNING CDC.WINDOW_ID BULK COLLECT INTO V_WINDOW_ID_LIST;
    
        SELECT TODAY INTO V_TODAY
        FROM F_DAT_MAPPED
        WHERE RECID = 'VN0011000';

        INSERT INTO T24_CDTNEW_ACTIVITY (
            BANKNO, ACCTNO, ACTYPE, ACNAME, CIFNO, TYPE, BRN, STATUS,
            CDNUM, ORGBAL, CBAL, HOLD, ACCINT, WDRWH, RNWCTR, PENAMT,
            ISSDT, MATDT, CDTERM, CDTCOD, RENEW, DACTN, RATE, CURTYP, CDMUID, RS2DT7,
            WINDOW_ID,COMMIT_TS,REPLICAT_TS,MAPPED_TS,CALL_CDC
        )
        SELECT
            27, --BANKNO
            TO_NUMBER(ARR.LINKED_APPL_ID), --ACCTNO
            'T', --ACTYPE
            TRIM(ACC.ACNAME), --ACNAME
            ACC.CUSTOMER, --CIFNO
            ARR.ACTIVE_PRODUCT, --TYPE
            ACC.CO_CODE, --BRN
            CASE
                WHEN ARR.ARR_STATUS IN ('CLOSE', 'PENDING.CLOSURE', 'CANCELLED') THEN 2
                ELSE 4
            END, --STATUS
            TO_NUMBER(ARR.LINKED_APPL_ID), --CDNUM
            ( 
                SELECT TO_NUMBER(ATA.AMOUNT)
                FROM FMSB_ATA_MAPPED ATA
                WHERE ATA.ID_COMP_1 = ARR.RECID
                AND ATA.ID_COMP_3 = (
                    SELECT MV.MIN_ID_COMP_3
                    FROM VW_FMSB_ATA_CDTNEW MV
                    WHERE MV.ID_COMP_1 = ATA.ID_COMP_1
                )
            ), --ORGBAL
            0, --CBAL
            0, --HOLD
            0, --ACCINT
            0, --WDRWH
            0, --RNWCTR
            0, --PENAMT
            TO_NUMBER(TO_CHAR(ARR.START_DATE, 'YYYYDDD')), --ISSDT
            TO_NUMBER(TO_CHAR(ADL.MATURITY_DATE, 'YYYYDDD')), --MATDT
            ( 
				REGEXP_REPLACE(NVL(
                    CALC_PERIODIC_PERIOD_FUNC(ARR.RECID),
                    CALC_TERM_FUNC(ARR.RECID)),
                '[^0-9]')
            ), --CDTERM
            (
				REGEXP_REPLACE(NVL(
                    CALC_PERIODIC_PERIOD_FUNC(ARR.RECID),
                    CALC_TERM_FUNC(ARR.RECID)),
                '[^A-Z]')
            ), --CDTCOD
            (
                SELECT
                    CASE
                        WHEN CHG.CHANGE_PERIOD IS NOT NULL OR CHG.CHANGE_DATE IS NOT NULL THEN 'Y'
                        ELSE 'N'
                    END
                    FROM FMSB_CHG_MAPPED CHG
                    WHERE CHG.ID_COMP_1 = ARR.RECID
                    AND CHG.ID_COMP_3 = (
                        SELECT MV.MAX_ID_COMP_3
                        FROM VW_FMSB_CHG_CDTNEW MV
                        WHERE MV.ID_COMP_1 = CHG.ID_COMP_1
                    )
            ), --RENEW
            '', --DACTN
            CALC_RATE_VAL_FUNC(ARR.RECID, V_TODAY), --RATE
            ARR.CURRENCY, --CURTYP
            REGEXP_SUBSTR(ACC.INPUTTER,'[^_]+',1,2), --CDMUID
            TO_NUMBER(TO_CHAR(ADL.RENEWAL_DATE, 'YYYYDDD')), --RS2DT7
            ARR.WINDOW_ID,
            ARR.COMMIT_TS,
            ARR.REPLICAT_TS,
            ARR.MAPPED_TS,
            'ARR'
        FROM TABLE(V_WINDOW_ID_LIST) V
            JOIN FMSB_ARR_CD ARR ON ARR.WINDOW_ID = V.COLUMN_VALUE
            JOIN FMSB_ACC_MAPPED ACC ON ARR.LINKED_APPL_ID = ACC.RECID
            LEFT JOIN FMSB_ADL_MAPPED ADL ON ADL.RECID = ARR.RECID
        WHERE ARR.START_DATE >= TO_DATE(V_TODAY,'YYYYMMDD');
--        WHERE ARR.START_DATE >= TO_DATE('20250917','YYYYMMDD');

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END GEN_FROM_ARR_PROC;

    PROCEDURE GEN_FROM_ATA_PROC IS
        V_WINDOW_ID_LIST T_WINDOW_ID_ARRAY;
        V_TODAY          VARCHAR2(8);
    BEGIN
        DELETE FROM T24_CDTNEW_ACTIVITY_ATA CDC
        WHERE EXISTS (
            SELECT 1 FROM FMSB_ATA_MAPPED ATA
            WHERE ATA.RECID = CDC.RECID AND CDC.WINDOW_ID <= ATA.WINDOW_ID
        )
        AND ROWNUM <= 5000
        RETURNING CDC.WINDOW_ID BULK COLLECT INTO V_WINDOW_ID_LIST;
    
        SELECT TODAY INTO V_TODAY
        FROM F_DAT_MAPPED
        WHERE RECID = 'VN0011000';

        INSERT INTO T24_CDTNEW_ACTIVITY (
            BANKNO, ACCTNO, ACTYPE, ACNAME, CIFNO, TYPE, BRN, STATUS,
            CDNUM, ORGBAL, CBAL, HOLD, ACCINT, WDRWH, RNWCTR, PENAMT,
            ISSDT, MATDT, CDTERM, CDTCOD, RENEW, DACTN, RATE, CURTYP, CDMUID, RS2DT7,
            WINDOW_ID, COMMIT_TS, REPLICAT_TS, MAPPED_TS, CALL_CDC
        )
        WITH PRECOMPUTED AS (
            SELECT
                ARR.RECID AS ARR_RECID,
                27 AS BANKNO,
                ARR.LINKED_APPL_ID AS ARR_LINKED_APPL_ID,
                'T' AS ACTYPE,
                ACC.ACNAME AS ACNAME,
                ACC.CUSTOMER AS CIFNO,
                ARR.ACTIVE_PRODUCT AS TYPE,
                ACC.CO_CODE AS BRN,
                CASE
                    WHEN ARR.ARR_STATUS IN ('CLOSE', 'PENDING.CLOSURE', 'CANCELLED') THEN 2
                    ELSE 4
                END AS STATUS,
                0 AS CBAL,
                0 AS HOLD,
                0 AS ACCINT,
                0 AS WDRWH,
                0 AS RNWCTR,
                0 AS PENAMT,
                ARR.START_DATE AS START_DATE,
                ADL.MATURITY_DATE AS MATURITY_DATE,
                CALC_PERIODIC_PERIOD_FUNC(ARR.RECID) AS PERIODIC_PERIOD,
                (
                    SELECT
                        CASE
                            WHEN CHG.CHANGE_PERIOD IS NOT NULL OR CHG.CHANGE_DATE IS NOT NULL THEN 'Y'
                            ELSE 'N'
                        END
                        FROM FMSB_CHG_MAPPED CHG
                        WHERE CHG.ID_COMP_1 = ARR.RECID
                        AND CHG.ID_COMP_3 = (
                            SELECT MV.MAX_ID_COMP_3
                            FROM VW_FMSB_CHG_CDTNEW MV
                            WHERE MV.ID_COMP_1 = CHG.ID_COMP_1
                        )
                ) AS RENEW,  
                '' AS DACTN,              
                CALC_RATE_VAL_FUNC(ARR.RECID, V_TODAY) AS RATE,
                ARR.CURRENCY AS CURTYP,
                ACC.INPUTTER AS INPUTTER,
                ADL.RENEWAL_DATE AS RENEWAL_DATE,
                ATA.WINDOW_ID AS WINDOW_ID,
                ATA.COMMIT_TS AS COMMIT_TS,
                ATA.REPLICAT_TS AS REPLICAT_TS,
                ATA.MAPPED_TS AS MAPPED_TS
            FROM TABLE(V_WINDOW_ID_LIST) V
            JOIN FMSB_ATA_MAPPED ATA ON ATA.WINDOW_ID = V.COLUMN_VALUE
            JOIN FMSB_ARR_CD ARR ON ARR.RECID = ATA.ID_COMP_1
	        JOIN FMSB_ACC_MAPPED ACC ON ARR.LINKED_APPL_ID = ACC.RECID
            LEFT JOIN FMSB_ADL_MAPPED ADL ON ADL.RECID = ARR.RECID
        WHERE ARR.START_DATE >= V_TODAY            
        ),
        AGGREGATED AS (
            SELECT ATA.ID_COMP_1, ATA.ID_COMP_3, ATA.AMOUNT, ATA.TERM, ATA.WINDOW_ID
            FROM FMSB_ATA_MAPPED ATA
            WHERE EXISTS (
                SELECT 1 FROM PRECOMPUTED PRE
                WHERE PRE.ARR_RECID = ATA.ID_COMP_1)
            AND ATA.ID_COMP_3 = (
                SELECT MV.MAX_ID_COMP_3
                FROM VW_FMSB_ATA_CDTNEW MV 
                WHERE MV.ID_COMP_1 = ATA.ID_COMP_1)
        )
        SELECT
            PRE.BANKNO,
            TO_NUMBER(PRE.ARR_LINKED_APPL_ID) AS ACCTNO,
            PRE.ACTYPE,
            TRIM(PRE.ACNAME),
            PRE.CIFNO,
            PRE.TYPE,
            PRE.BRN,
            PRE.STATUS,
            TO_NUMBER(PRE.ARR_LINKED_APPL_ID) AS CDNUM,
            AGG.AMOUNT AS ORGBAL,
            PRE.CBAL,
            PRE.HOLD,
            PRE.ACCINT,
            PRE.WDRWH,
            PRE.RNWCTR,
            PRE.PENAMT,
            TO_NUMBER(TO_CHAR(PRE.START_DATE, 'YYYYDDD')) AS ISSDT,
            TO_NUMBER(TO_CHAR(PRE.MATURITY_DATE, 'YYYYDDD')) AS MATDT,
            REGEXP_REPLACE(NVL(PRE.PERIODIC_PERIOD,AGG.TERM),'[^0-9]') AS CDTERM,
            REGEXP_REPLACE(NVL(PRE.PERIODIC_PERIOD,AGG.TERM),'[^A-Z]') AS CDTCOD,
            PRE.RENEW,
            PRE.DACTN,
            PRE.RATE,
            PRE.CURTYP,
            REGEXP_SUBSTR(PRE.INPUTTER,'[^_]+',1,2) AS CDMUID,
            TO_NUMBER(TO_CHAR(PRE.RENEWAL_DATE, 'YYYYDDD')) AS RS2DT7,
            PRE.WINDOW_ID,
            PRE.COMMIT_TS,
            PRE.REPLICAT_TS,
            PRE.MAPPED_TS,
            'ATA'
        FROM PRECOMPUTED PRE
        JOIN AGGREGATED AGG ON PRE.ARR_RECID = AGG.ID_COMP_1
        WHERE PRE.WINDOW_ID = AGG.WINDOW_ID;
        

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END GEN_FROM_ATA_PROC;

END T24_CDTNEW_ACTIVITY_PKG;