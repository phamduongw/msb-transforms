
CREATE OR REPLACE PACKAGE T24RAWOGG.T24_TMTRAN_PKG IS

	FUNCTION CALC_PP_VAL_FUNC(
        P_LOC_FIELD_NAME_STR IN VARCHAR2,
        P_LOC_FIELD_VALUE_STR    IN VARCHAR2,
        P_VALUE      IN VARCHAR2
    ) RETURN VARCHAR2;

    PROCEDURE GEN_FROM_STM_PROC;
   

END T24_TMTRAN_PKG;



CREATE OR REPLACE PACKAGE BODY T24RAWOGG.T24_TMTRAN_PKG IS


---------------------------------------------------------------------------
-- FUNCTION 
---------------------------------------------------------------------------   
	FUNCTION CALC_PP_VAL_FUNC(
        P_LOC_FIELD_NAME_STR IN VARCHAR2,
        P_LOC_FIELD_VALUE_STR    IN VARCHAR2,
        P_VALUE      IN VARCHAR2
    ) RETURN VARCHAR2 IS
        V_START           NUMBER := 1;
        V_FOUND_INDEX 	  NUMBER := 0;
        V_LOC_FIELD_NAME_VAL       VARCHAR2(255);
        V_LOC_FIELD_VALIE_VAL       VARCHAR2(255);
    BEGIN
        IF P_LOC_FIELD_NAME_STR IS NULL OR P_LOC_FIELD_VALUE_STR IS NULL OR p_VALUE IS NULL THEN 
        	RETURN NULL ;
        END IF;
       
       	LOOP
       		V_LOC_FIELD_NAME_VAL := regexp_substr(P_LOC_FIELD_NAME_STR,'#[0-9]+:([^#]*)',1,V_START,NULL,1);
       		EXIT WHEN V_LOC_FIELD_NAME_VAL IS NULL;
--       		DBMS_OUTPUT.PUT_LINE('index ' || V_START || 'source ' || P_LOC_FIELD_NAME_STR);
       		IF V_LOC_FIELD_NAME_VAL = p_VALUE THEN 
       			V_FOUND_INDEX := V_START;
       			EXIT;
       		END IF;
       		
       		V_START := V_START + 1;
       	END LOOP;
        
       	IF V_FOUND_INDEX = 0 THEN
       		RETURN NULL;
       	END IF;
--        DBMS_OUTPUT.PUT_LINE('index ' || V_FOUND_INDEX || ' sink ' || P_LOC_FIELD_VALUE_STR);

       	V_LOC_FIELD_VALIE_VAL := regexp_substr(P_LOC_FIELD_VALUE_STR,'#[0-9]+:([^#]*)',1,V_FOUND_INDEX,NULL,1);
--        DBMS_OUTPUT.PUT_LINE('result: ' || V_LOC_FIELD_VALIE_VAL);
        RETURN V_LOC_FIELD_VALIE_VAL;
    END CALC_PP_VAL_FUNC;


 PROCEDURE GEN_FROM_STM_PROC IS
        V_WINDOW_ID_LIST T_WINDOW_ID_ARRAY;
        V_TODAY          VARCHAR2(8);
    BEGIN


	select WINDOW_ID 
	BULK COLLECT INTO  V_WINDOW_ID_LIST
	from (
	  select 
	WINDOW_ID
	from T24_TMTRAN_STM_TRIGGER cdc
	where SYSTEM_ID not in ('FT','AC','PP','AA') 
	  union all
	  select
	WINDOW_ID
	from T24_TMTRAN_STM_TRIGGER cdc
	where EXISTS (
	    select 1
	    from fmsb_ft_mapped ft 
	where  cdc.JOIN_KEY = ft.RECID)
	union all
	select
	WINDOW_ID
	from T24_TMTRAN_STM_TRIGGER cdc
	where EXISTS (
	    select 1
	    from fmsb_ac_mapped ac WHERE cdc.JOIN_KEY = ac.recid)
	union all
	select
	WINDOW_ID
	from T24_TMTRAN_STM_TRIGGER cdc
	where EXISTS (
	    select 1
	    from fmsb_arr_mapped arr WHERE cdc.JOIN_KEY = arr.LINKED_APPL_ID)
	UNION all
	select
	WINDOW_ID
	from T24_TMTRAN_STM_TRIGGER cdc
	where EXISTS (
	    select 1
	    from T24_TMTRAN_STM_TRIGGER tpor
	    join F_POR_MAPPED por on tpor.JOIN_KEY = por.recid   
	where por.STATUS_CODE IN ('999', '677', '687','680','988','993','996') and cdc.JOIN_KEY = por.recid 
	)) cdc
	where EXISTS (
	    select 1
	    from FMSB_STM_MAPPED stm 
	    where stm.WINDOW_ID = cdc.WINDOW_ID
	)
	; 
        


    IF V_WINDOW_ID_LIST.COUNT > 0 THEN


       
        SELECT /*+ RESULT_CACHE */ TODAY INTO V_TODAY
            FROM F_DAT_MAPPED
            WHERE RECID = 'VN0011000';
            INSERT INTO T24_TMTRAN (
                            TMTXSTAT,
                            TMOFFSET,
                            TMIBTTRN,
                            TMEQVTRN,
                            TMSUMTRN,
                            TMTELLID,
                            TMTXSEQ,
                            TMTXCD,
                            TMENTDT7,
                            TMEFFDT7,
                            TMAPPTYPE,
                            TMHOSTTXCD,
                            TMTIMENT,
                            TMORGAMT,
                            TMTXAMT,
                            TMGLCUR,
                            TMACCTNO,
                            TMDORC,
                            TMSSEQ,
                            TMEFTH,
                            TMRESV07,
                            TMTKTN,
                            WINDOW_ID,
                            COMMIT_TS, 
                            REPLICAT_TS, 
                            MAPPED_TS, 
                            CALL_CDC
            )
            with stmt as (
				    select 
				    stm.RECID ,
				    stm.COMMIT_TS, 
				    stm.REPLICAT_TS, 
				    stm.MAPPED_TS,
					stm.WINDOW_ID , 
				    stm.ACCOUNT_NUMBER,
					stm.AMOUNT_FCY ,  
					stm.AMOUNT_LCY ,  
					stm.BOOKING_DATE  ,
					stm.CURRENCY  ,
					stm.DATE_TIME  ,
				    REGEXP_SUBSTR(nvl(stm.INPUTTER,'0'), '[^_]+', 1, 2)  INPUTTER,
					stm.NARRATIVE_1  ,
					stm.NARRATIVE  ,
					stm.OUR_REFERENCE,  
					to_char(stm.PRODUCT_CATEGORY) PRODUCT_CATEGORY,
					stm.RECORD_STATUS,  
					stm.SYSTEM_ID  ,
					stm.TRANS_REFERENCE,  
					stm.THEIR_REFERENCE , 
					stm.TRANSACTION_CODE , 
					stm.VALUE_DATE  
				    from TABLE(V_WINDOW_ID_LIST) tmv
                    inner join T24RAWOGG.FMSB_STM_MAPPED stm on tmv.COLUMN_VALUE = stm.WINDOW_ID
				    where  (stm.OP_TYPE = 'I' OR stm.RECORD_STATUS = 'REVE')
				       AND stm.PRODUCT_CATEGORY <= 9999
				       AND stm.CONSOL_KEY IS NOT NULL
				),
	            acc_arr as (
	                select 
	                    arr.LINKED_APPL_ID  RECID,
	                    acc.CATEGORY CATEGORY,
	                    arr.PRODUCT_LINE PRODUCT_LINE
	                from T24RAWOGG.fmsb_arr_mapped arr 
	                left join T24RAWOGG.fmsb_acc_mapped acc  on arr.LINKED_APPL_ID = acc.recid 
	            )
				select
                case
                    when stm.BOOKING_DATE = to_date(V_TODAY, 'YYYYMMDD') - 2 then 'PP'
                    when stm.BOOKING_DATE = to_date(V_TODAY, 'YYYYMMDD') - 1 then 'PT'
                    when stm.RECORD_STATUS = 'REVE'
                    and stm.BOOKING_DATE = to_date(V_TODAY, 'YYYYMMDD') then 'CE'
                    else ' '
                end TMTXSTAT,
                case
                    when stm.SYSTEM_ID = 'FT' then nvl(ft.MSB_TRANS_SEQ,' ')
                    when stm.SYSTEM_ID = 'AC' then nvl(ac.MSB_TRANS_SEQ,' ')
                    WHEN stm.SYSTEM_ID = 'PP' THEN nvl(nvl(tmv.RESERVED1,CALC_PP_VAL_FUNC(sup.LOC_FIELD_NAME,substr(sup.LOC_FIELD_VALUE,1,4000),'MSB.TRANS.SEQ')),' ')
                    else ' '
                end TMOFFSET,
                -- bo xung them PO 
                CASE
                    WHEN stm.PRODUCT_CATEGORY = '12800' THEN 'y'
                    else ' '
                END TMIBTTRN,
                CASE
                    WHEN stm.PRODUCT_CATEGORY IN ('14016', '18711', '8712') THEN 'E'
                    WHEN stm.PRODUCT_CATEGORY = '12800' THEN 'I'
                    WHEN stm.PRODUCT_CATEGORY = '56101' THEN 'P'
                    else ' '
                END TMEQVTRN,
                nvl(por.OUTPUT_CHANNEL,' ') TMSUMTRN,
                nvl(stm.INPUTTER,' ') TMTELLID,
                stm.recid TMTXSEQ,
                CASE
                    WHEN stm.SYSTEM_ID = 'PP' THEN nvl(nvl(tmv.RESERVED2,CALC_PP_VAL_FUNC(sup.LOC_FIELD_NAME,substr(sup.LOC_FIELD_VALUE,1,4000),'MSB.TRANS.CODE')),' ')
                    WHEN stm.SYSTEM_ID = 'FT' THEN nvl(ft.MSB_TRANS_CODE,' ')
                    WHEN stm.SYSTEM_ID = 'AC'
                    AND SUBSTR(stm.TRANS_REFERENCE, 1, 3) = 'CHG' THEN nvl(ac.MSB_TRANS_CODE,' ')
                    else ' '
                END TMTXCD,
                nvl(to_number(TO_CHAR(BOOKING_DATE,'YYYYDDD')),0) TMENTDT7,
        nvl(to_number(TO_CHAR(VALUE_DATE,'YYYYDDD')),0) TMEFFDT7,
        CASE
            WHEN acc.PRODUCT_LINE = 'DEPOSITS' THEN 'T'
            WHEN acc.PRODUCT_LINE = 'ACCOUNTS' THEN CASE
                WHEN nvl(to_number(acc.CATEGORY),0) BETWEEN 6000 AND 6100 THEN 'S'
                ELSE 'D'
            END
            WHEN acc.PRODUCT_LINE = 'LENDING' THEN 'L'
            else ' '
        END TMAPPTYPE,
        nvl(to_number(stm.TRANSACTION_CODE),0) TMHOSTTXCD,
        CASE
            WHEN trunc(cast(stm.DATE_TIME as date)) = stm.BOOKING_DATE THEN nvl(to_number(REPLACE(TO_CHAR(stm.date_time,'HH24:MI:SS'),':','')),0)
            WHEN trunc(cast(stm.DATE_TIME as date)) > stm.BOOKING_DATE THEN 235959
            ELSE 1
        END TMTIMENT,
        CASE
            WHEN stm.CURRENCY = 'VND' THEN ABS(nvl(stm.AMOUNT_LCY,0))
            WHEN stm.CURRENCY <> 'VND' THEN ABS(nvl(stm.AMOUNT_FCY,0))
            ELSE 0
        END TMORGAMT,
        CASE
            WHEN stm.CURRENCY = 'VND' THEN ABS(nvl(stm.AMOUNT_LCY,0))
            WHEN stm.CURRENCY <> 'VND' THEN ABS(nvl(stm.AMOUNT_FCY,0))
            ELSE 0
        END TMTXAMT,
                nvl(stm.CURRENCY,' ') TMGLCUR,
                CASE WHEN substr(stm.ACCOUNT_NUMBER,0,1) = '0'  THEN nvl(substr(stm.ACCOUNT_NUMBER,2),' ') ELSE nvl(stm.ACCOUNT_NUMBER,' ') end  TMACCTNO,
                CASE
                    WHEN stm.CURRENCY <> 'VND' THEN CASE
                        WHEN nvl(stm.AMOUNT_FCY,0) < 0 THEN 'D'
                        ELSE 'C'
                    END
                    ELSE CASE
                        WHEN nvl(stm.AMOUNT_LCY,0) < 0 THEN 'D'
                        ELSE 'C'
                    END
                END TMDORC,
                nvl(REGEXP_SUBSTR(stm.RECID, '[^.]+', 1, 2),' ') TMSSEQ,
                CASE
                    WHEN stm.TRANS_REFERENCE LIKE 'CHG%' THEN CASE
                        WHEN stm.TRANSACTION_CODE = '5021' THEN substr('VAT - ' || REGEXP_REPLACE(regexp_replace(cast(ac.REMARKS as varchar2(4000)),'(^#1:|#$)',''),'(#[0-9]+:)','# ')1,500)
                        ELSE substr(REGEXP_REPLACE(regexp_replace(cast(nvl(ac.REMARKS,' ') as varchar2(4000)),'(^#1:|#$)',''),'(#[0-9]+:)','# '),1,500)
                    END
                    WHEN stm.SYSTEM_ID IN ('ACSW', 'ACCP') THEN substr('Chuyen tien tu dong - ' || stm.THEIR_REFERENCE,1,500)
                    WHEN stm.SYSTEM_ID IN ('LCM', 'LCC', 'LCD', 'MD') THEN CASE
                        WHEN stm.TRANSACTION_CODE = '5021' THEN substr(tr.NARRATIVE_1 || ' ' || stm.OUR_REFERENCE,1,500)
                        ELSE substr(tr.NARRATIVE_2 || ' ' || stm.OUR_REFERENCE,1,500)
                    END
                    WHEN stm.SYSTEM_ID = 'FX' THEN CASE
                        WHEN fx.NOTES IS NOT NULL THEN substr(fx.NOTES,1,500)
                        ELSE substr('MBNT MUA: ' || fx.AMOUNT_BOUGHT || fx.CURRENCY_BOUGHT || ', BAN: ' || fx.AMOUNT_SOLD || fx.CURRENCY_SOLD,1,500)
                    END
                    WHEN stm.SYSTEM_ID = 'FT' THEN CASE
                        WHEN stm.TRANSACTION_CODE = '422' THEN substr(stm.NARRATIVE_1 || '# Thu phi - ' || REGEXP_REPLACE(regexp_replace(cast(ft.PAYMENT_DETAILS as varchar2(4000)),'(^#1:|#$)',''),'(#[0-9]+:)','# '),1,500)
                        WHEN stm.TRANSACTION_CODE = '5021' THEN substr(stm.NARRATIVE_1 || '# VAT - ' || REGEXP_REPLACE(regexp_replace(cast(ft.PAYMENT_DETAILS as varchar2(4000)),'(^#1:|#$)',''),'(#[0-9]+:)','# '),1,500)
                        ELSE substr(nvl(stm.NARRATIVE,' '),1,500)
                    END
                    ELSE substr(nvl(stm.NARRATIVE,' '),1,500)
                END TMEFTH,
                nvl(TO_CHAR(stm.DATE_TIME,'yyyyMMddHH24miss'),' ') TMRESV07,
                regexp_replace(nvl(stm.trans_reference,' '),'\\[0-9A-Z]+$') TMTKTN,
                stm.WINDOW_ID ,
                stm.COMMIT_TS, 
                stm.REPLICAT_TS, 
                stm.MAPPED_TS,
                'STM'
            FROM stmt stm 
            left join T24RAWOGG.fmsb_ft_mapped ft on stm.our_reference = ft.recid
            left join T24RAWOGG.fmsb_ac_mapped ac on stm.our_reference = ac.recid -- ac_charge_request
            left join T24RAWOGG.F_POR_MAPPED por on stm.our_reference = por.recid AND por.STATUS_CODE IN ('999', '677', '687')
            left join T24RAWOGG.F_SUP_MAPPED sup on por.recid = sup.recid
            left join T24RAWOGG.F_TMV_TMTRAN tmv on stm.our_reference = tmv.ORIGINAL_FT_NUMBER
            left join acc_arr acc on stm.ACCOUNT_NUMBER = acc.recid
            left join T24RAWOGG.fmsb_fx_mapped fx on stm.our_reference = fx.recid
            left join T24RAWOGG.fmsb_tr_mapped tr on stm.transaction_code = tr.recid;

        DELETE FROM T24_TMTRAN_STM_TRIGGER CDC
        WHERE EXISTS (
                SELECT 1
                FROM TABLE(V_WINDOW_ID_LIST) TMP
            WHERE TMP.COLUMN_VALUE = CDC.WINDOW_ID
        );

        COMMIT;
    end if;
    exception
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
   END GEN_FROM_STM_PROC;


    
END T24_TMTRAN_PKG;
