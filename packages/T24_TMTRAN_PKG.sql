CREATE OR REPLACE PACKAGE BODY T24_TMTRAN_PKG IS

    

    PROCEDURE GEN_FROM_STM_PROC IS
        V_WINDOW_ID_LIST T_WINDOW_ID_ARRAY;
        V_TODAY          VARCHAR2(8);
    BEGIN
        
	    
	  
        SELECT CDC.WINDOW_ID
        BULK COLLECT INTO V_WINDOW_ID_LIST
        FROM T24_TMTRAN_STM CDC
        WHERE EXISTS (
            SELECT 1
            FROM FMSB_STM_MAPPED STM
            WHERE STM.RECID = CDC.RECID
            AND CDC.WINDOW_ID <= STM.WINDOW_ID
        );


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
                            COMMIT_TS, 
                            REPLICAT_TS, 
                            MAPPED_TS, 
                            CALL_CDC
            )
            select
                case
                    when to_date(stm.BOOKING_DATE, 'YYYYMMDD') = to_date(V_TODAY, 'YYYYMMDD') - 2 then 'PP'
                    when to_date(stm.BOOKING_DATE, 'YYYYMMDD') = to_date(V_TODAY, 'YYYYMMDD') - 1 then 'PT'
                    when stm.RECORD_STATUS = 'REVE'
                    and to_date(stm.BOOKING_DATE, 'YYYYMMDD') = to_date(V_TODAY, 'YYYYMMDD') then 'PT'
                end TMTXSTAT,
                case
                    when stm.SYSTEM_ID = 'FT' then ft.MSB_TRANS_SEQ
                    when stm.SYSTEM_ID = 'AC' then acc.MSB_TRANS_SEQ
                    WHEN stm.SYSTEM_ID = 'PP' THEN CASE
                        WHEN tmv.RESERVED1 IS NOT NULL THEN tmv.RESERVED1
                        when sup.LOC_FIELD_NAME ='MSB.TRANS.CODE' then sup.LOC_FIELD_VALUE --             WHERE sup.LOC_FIELD_NAME ='MSB.TRANS.CODE'
                    END
                end TMOFFSET,
                -- bo xung them PO 
                CASE
                    WHEN stm.PRODUCT_CATEGORY = '12800' THEN 'y'
                END TMIBTTRN,
                CASE
                    WHEN stm.PRODUCT_CATEGORY IN ('14016', '18711', '8712') THEN 'E'
                    WHEN stm.PRODUCT_CATEGORY = '12800' THEN 'I'
                    WHEN stm.PRODUCT_CATEGORY = '56101' THEN 'P'
                END TMEQVTRN,
                por.OUTPUTCHANNEL TMSUMTRN,
                REGEXP_SUBSTR(stm.INPUTTER, '[^_]+', 1, 2) TMTELLID,
                stm.recid TMTXSEQ,
                CASE
                    WHEN stm.SYSTEM_ID = 'PP' THEN CASE
                        WHEN tmv.RESERVED2 IS NOT NULL THEN tmv.RESERVED2
                        ELSE sup.LOC_FIELD_VALUE --             WHERE sup.LOC_FIELD_NAME ='MSB.TRANS.CODE'
                    END
                    WHEN stm.SYSTEM_ID = 'FT' THEN ft.MSB_TRANS_CODE
                    WHEN stm.SYSTEM_ID = 'AC'
                    AND SUBSTR(stm.TRANS_REFERENCE, 1, 3) = 'CHG' THEN acc.MSB_TRANS_CODE
                END TMTXCD,
                to_number(stm.BOOKING_DATE) TMENTDT7,
        to_number(stm.VALUE_DATE) TMEFFDT7,
        CASE
            WHEN arr.PRODUCT_LINE = 'DEPOSITS' THEN 'T'
            WHEN arr.PRODUCT_LINE = 'ACCOUNTS' THEN CASE
                WHEN ac.CATEGORY BETWEEN 6000
                AND 6100 THEN 'S'
                ELSE 'D'
            END
            WHEN arr.PRODUCT_LINE = 'LENDING' THEN 'L'
        END TMAPPTYPE,
        to_number(stm.TRANSACTION_CODE) TMHOSTTXCD,
        CASE
            WHEN SUBSTR(stm.DATE_TIME, 1, 6) = SUBSTR(stm.BOOKING_DATE,3,6) THEN to_number(SUBSTR(stm.DATE_TIME, 7) || '00')
            WHEN to_number(SUBSTR(stm.DATE_TIME, 1, 6)) > to_number(SUBSTR(stm.BOOKING_DATE,3,6)) THEN 235959
            ELSE 1
        END TMTIMENT,
        CASE
            WHEN stm.CURRENCY = 'VND' THEN ABS(to_number(stm.AMOUNT_LCY))
            WHEN stm.CURRENCY <> 'VND' THEN ABS(to_number(stm.AMOUNT_FCY))
            ELSE 0
        END TMORGAMT,
        CASE
            WHEN stm.CURRENCY = 'VND' THEN ABS(to_number(stm.AMOUNT_LCY))
            WHEN stm.CURRENCY <> 'VND' THEN ABS(to_number(stm.AMOUNT_FCY))
            ELSE 0
        END TMTXAMT,
                stm.CURRENCY TMGLCUR,
                stm.ACCOUNT_NUMBER TMACCTNO,
                CASE
                    WHEN stm.CURRENCY <> 'VND' THEN CASE
                        WHEN stm.AMOUNT_FCY < 0 THEN 'D'
                        ELSE 'C'
                    END
                    ELSE CASE
                        WHEN stm.AMOUNT_LCY < 0 THEN 'D'
                        ELSE 'C'
                    END
                END TMDORC,
                REGEXP_SUBSTR(stm.RECID, '[^.]+', 1, 2) TMSSEQ,
                CASE
                    WHEN stm.TRANS_REFERENCE LIKE 'CHG%' THEN CASE
                        WHEN stm.TRANSACTION_CODE = '5021' THEN 'VAT - ' || acc.REMARKS
                        ELSE acc.REMARKS
                    END
                    WHEN stm.SYSTEM_ID IN ('ACSW', 'ACCP') THEN 'Sweep ' || stm.THEIR_REFERENCE
                    WHEN stm.SYSTEM_ID IN ('LCM', 'LCC', 'LCD', 'MD') THEN CASE
                        WHEN stm.TRANSACTION_CODE = '5021' THEN tr.NARRATIVE_1 || ' ' || stm.OUR_REFERENCE
                        ELSE tr.NARRATIVE_2 || ' ' || stm.OUR_REFERENCE
                    END
                    WHEN stm.SYSTEM_ID = 'FX' THEN CASE
                        WHEN fx.NOTES IS NOT NULL THEN fx.NOTES
                        ELSE 'MBNT MUA: ' || fx.AMOUNT_BOUGHT || fx.CURRENCY_BOUGHT || ', BAN: ' || fx.AMOUNT_SOLD || fx.CURRENCY_SOLD
                    END
                    WHEN stm.SYSTEM_ID = 'FT' THEN CASE
                        WHEN stm.TRANSACTION_CODE = '422' THEN stm.NARRATIVE_1 || '# Thu phi - ' || ft.PAYMENT_DETAILS
                        WHEN stm.TRANSACTION_CODE = '5021' THEN stm.NARRATIVE_1 || '# VAT - ' || ft.PAYMENT_DETAILS
                        ELSE stm.NARRATIVE
                    END
                    ELSE stm.NARRATIVE
                END TMEFTH,
                stm.DATE_TIME TMRESV07,
                stm.COMMIT_TS, 
                stm.REPLICAT_TS, 
                stm.MAPPED_TS,
                'STM'
            FROM TABLE(V_WINDOW_ID_LIST) V
            join T24DB_OGGDS.fmsb_stm_tmtran stm on stm.WINDOW_ID = V.COLUMN_VALUE
            left join T24DB_OGGDS.fmsb_ft_mapped ft on stm.our_reference = ft.recid
            left join T24DB_OGGDS.fmsb_ac_mapped acc on stm.our_reference = acc.recid -- ac_charge_request
            left join T24DB_OGGDS.F_POR_TMTRAN por on stm.our_reference = por.recid
            left join T24DB_OGGDS.F_SUP_TMTRAN sup on por.recid = sup.recid
            left join T24DB_OGGDS.F_TMV_TMTRAN tmv on stm.our_reference = tmv.PAYMENTDIRECTION
            left join T24DB_OGGDS.fmsb_acc_mapped ac on stm.ACCOUNT_NUMBER = ac.recid -- account 
            left join T24DB_OGGDS.fmsb_arr_mapped arr on ac.recid = arr.LINKED_APPL_ID
            left join T24DB_OGGDS.fmsb_fx_mapped fx on stm.our_reference = fx.recid
            left join T24DB_OGGDS.fmsb_tr_mapped tr on stm.transaction_code = tr.recid
        where stm.BOOKING_DATE between to_date(V_TODAY, 'YYYYMMDD') - 2 and to_date(V_TODAY, 'YYYYMMDD') and stm.OP_TYPE <> 'D';

        end if;

         COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END GEN_FROM_STM_PROC;

    PROCEDURE GEN_FROM_FT_PROC IS
        V_WINDOW_ID_LIST T_WINDOW_ID_ARRAY;
        V_TODAY          VARCHAR2(8);
    BEGIN

    SELECT CDC.WINDOW_ID
        BULK COLLECT INTO V_WINDOW_ID_LIST
        FROM T24_TMTRAN_FT CDC
        WHERE EXISTS (
            SELECT 1
            FROM FMSB_FUNDS_TRANSFER_MAPPED FT
            WHERE FT.RECID = CDC.RECID
            AND CDC.WINDOW_ID <= FT.WINDOW_ID
        );


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
                            COMMIT_TS, 
                            REPLICAT_TS, 
                            MAPPED_TS, 
                            CALL_CDC
            )
            select
        case
            when to_date(stm.BOOKING_DATE, 'YYYYMMDD') = to_date(V_TODAY, 'YYYYMMDD') - 2 then 'PP'
            when to_date(stm.BOOKING_DATE, 'YYYYMMDD') = to_date(V_TODAY, 'YYYYMMDD') - 1 then 'PT'
            when stm.RECORD_STATUS = 'REVE'
            and to_date(stm.BOOKING_DATE, 'YYYYMMDD') = to_date(V_TODAY, 'YYYYMMDD') then 'PT'
        end TMTXSTAT,
        ft.MSB_TRANS_SEQ TMOFFSET,
        -- bo xung them PO 
        CASE
                    WHEN stm.PRODUCT_CATEGORY = '12800' THEN 'y'
                END TMIBTTRN,
        CASE
            WHEN stm.PRODUCT_CATEGORY IN ('14016', '18711', '8712') THEN 'E'
            WHEN stm.PRODUCT_CATEGORY = '12800' THEN 'I'
            WHEN stm.PRODUCT_CATEGORY = '56101' THEN 'P'
        END TMEQVTRN,
        -- por.OUTPUTCHANNEL TMSUMTRN,
        null TMSUMTRN,
        REGEXP_SUBSTR(stm.INPUTTER, '[^_]+', 1, 2) TMTELLID,
        stm.recid TMTXSEQ,
        ft.MSB_TRANS_CODE TMTXCD,
        to_number(stm.BOOKING_DATE) TMENTDT7,
        to_number(stm.VALUE_DATE) TMEFFDT7,
        CASE
            WHEN arr.PRODUCT_LINE = 'DEPOSITS' THEN 'T'
            WHEN arr.PRODUCT_LINE = 'ACCOUNTS' THEN CASE
                WHEN ac.CATEGORY BETWEEN 6000
                AND 6100 THEN 'S'
                ELSE 'D'
            END
            WHEN arr.PRODUCT_LINE = 'LENDING' THEN 'L'
        END TMAPPTYPE,
        to_number(stm.TRANSACTION_CODE) TMHOSTTXCD,
        CASE
            WHEN SUBSTR(stm.DATE_TIME, 1, 6) = SUBSTR(stm.BOOKING_DATE,3,6) THEN to_number(SUBSTR(stm.DATE_TIME, 7) || '00')
            WHEN to_number(SUBSTR(stm.DATE_TIME, 1, 6)) > to_number(SUBSTR(stm.BOOKING_DATE,3,6)) THEN 235959
            ELSE 1
        END TMTIMENT,
        CASE
            WHEN stm.CURRENCY = 'VND' THEN ABS(to_number(stm.AMOUNT_LCY))
            WHEN stm.CURRENCY <> 'VND' THEN ABS(to_number(stm.AMOUNT_FCY))
            ELSE 0
        END TMORGAMT,
        CASE
            WHEN stm.CURRENCY = 'VND' THEN ABS(to_number(stm.AMOUNT_LCY))
            WHEN stm.CURRENCY <> 'VND' THEN ABS(to_number(stm.AMOUNT_FCY))
            ELSE 0
        END TMTXAMT,
        stm.CURRENCY TMGLCUR,
        stm.ACCOUNT_NUMBER TMACCTNO,
        CASE
            WHEN stm.CURRENCY <> 'VND' THEN CASE
                WHEN stm.AMOUNT_FCY < 0 THEN 'D'
                ELSE 'C'
            END
            ELSE CASE
                WHEN stm.AMOUNT_LCY < 0 THEN 'D'
                ELSE 'C'
            END
        END TMDORC,
        REGEXP_SUBSTR(stm.RECID, '[^.]+', 1, 2) TMSSEQ,
        case
            WHEN stm.SYSTEM_ID = 'FT' THEN CASE
                WHEN stm.TRANSACTION_CODE = '422' THEN stm.NARRATIVE_1 || '# Thu phi - ' || ft.PAYMENT_DETAILS
                WHEN stm.TRANSACTION_CODE = '5021' THEN stm.NARRATIVE_1 || '# VAT - ' || ft.PAYMENT_DETAILS
                ELSE stm.NARRATIVE
            END
        END TMEFTH,
        stm.DATE_TIME TMRESV07,
        ft.COMMIT_TS, 
                ft.REPLICAT_TS, 
                ft.MAPPED_TS,
                'FT'
    FROM TABLE(V_WINDOW_ID_LIST) V
        JOIN T24DB_OGGDS.fmsb_ft_mapped ft on ft.WINDOW_ID = V.COLUMN_VALUE
        join T24DB_OGGDS.fmsb_stm_tmtran stm on stm.our_reference = ft.recid
        left join T24DB_OGGDS.fmsb_acc_mapped ac on stm.ACCOUNT_NUMBER = ac.recid -- account 
        left join T24DB_OGGDS.fmsb_arr_mapped arr on ac.recid = arr.LINKED_APPL_ID
        left join T24DB_OGGDS.fmsb_fx_mapped fx on stm.our_reference = fx.recid
        left join T24DB_OGGDS.fmsb_tr_mapped tr on stm.transaction_code = tr.recid
    where stm.BOOKING_DATE between to_date(V_TODAY, 'YYYYMMDD') - 2 and to_date(V_TODAY, 'YYYYMMDD') and ft.OP_TYPE <> 'D';

    end if;
       

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END GEN_FROM_FT_PROC;

     PROCEDURE GEN_FROM_ACC_PROC IS
        V_WINDOW_ID_LIST T_WINDOW_ID_ARRAY;
        V_TODAY          VARCHAR2(8);
    BEGIN

        SELECT CDC.WINDOW_ID
        BULK COLLECT INTO V_WINDOW_ID_LIST
        FROM T24_TMTRAN_ACC CDC
        WHERE EXISTS (
            SELECT 1
            FROM FMSB_AC_MAPPED AC
            WHERE AC.RECID = CDC.RECID
            AND CDC.WINDOW_ID <= AC.WINDOW_ID
        );


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
                            TMENTDT7,--
                            TMEFFDT7,--
                            TMAPPTYPE,
                            TMHOSTTXCD,--
                            TMTIMENT,--
                            TMORGAMT,--
                            TMTXAMT,--
                            TMGLCUR,
                            TMACCTNO,
                            TMDORC,
                            TMSSEQ,
                            TMEFTH,
                            TMRESV07,
                            COMMIT_TS, 
                            REPLICAT_TS, 
                            MAPPED_TS, 
                            CALL_CDC
            )
            select
        case
            when to_date(stm.BOOKING_DATE, 'YYYYMMDD') = to_date(V_TODAY, 'YYYYMMDD') - 2 then 'PP'
            when to_date(stm.BOOKING_DATE, 'YYYYMMDD') = to_date(V_TODAY, 'YYYYMMDD') - 1 then 'PT'
            when stm.RECORD_STATUS = 'REVE'
            and to_date(stm.BOOKING_DATE, 'YYYYMMDD') = to_date(V_TODAY, 'YYYYMMDD') then 'PT'
        end TMTXSTAT,
        acc.MSB_TRANS_SEQ TMOFFSET,
        -- bo xung them PO 
        CASE
                    WHEN stm.PRODUCT_CATEGORY = '12800' THEN 'y'
                END TMIBTTRN,
        CASE
            WHEN stm.PRODUCT_CATEGORY IN ('14016', '18711', '8712') THEN 'E'
            WHEN stm.PRODUCT_CATEGORY = '12800' THEN 'I'
            WHEN stm.PRODUCT_CATEGORY = '56101' THEN 'P'
        END TMEQVTRN,
        -- por.OUTPUTCHANNEL TMSUMTRN,
        null TMSUMTRN,
        REGEXP_SUBSTR(stm.INPUTTER, '[^_]+', 1, 2) TMTELLID,
        stm.recid TMTXSEQ,
        acc.MSB_TRANS_CODE TMTXCD,
        to_number(stm.BOOKING_DATE) TMENTDT7,
        to_number(stm.VALUE_DATE) TMEFFDT7,
        CASE
            WHEN arr.PRODUCT_LINE = 'DEPOSITS' THEN 'T'
            WHEN arr.PRODUCT_LINE = 'ACCOUNTS' THEN CASE
                WHEN ac.CATEGORY BETWEEN 6000
                AND 6100 THEN 'S'
                ELSE 'D'
            END
            WHEN arr.PRODUCT_LINE = 'LENDING' THEN 'L'
        END TMAPPTYPE,
        to_number(stm.TRANSACTION_CODE) TMHOSTTXCD,
        CASE
            WHEN SUBSTR(stm.DATE_TIME, 1, 6) = SUBSTR(stm.BOOKING_DATE,3,6) THEN to_number(SUBSTR(stm.DATE_TIME, 7) || '00')
            WHEN to_number(SUBSTR(stm.DATE_TIME, 1, 6)) > to_number(SUBSTR(stm.BOOKING_DATE,3,6)) THEN 235959
            ELSE 1
        END TMTIMENT,
        CASE
            WHEN stm.CURRENCY = 'VND' THEN ABS(to_number(stm.AMOUNT_LCY))
            WHEN stm.CURRENCY <> 'VND' THEN ABS(to_number(stm.AMOUNT_FCY))
            ELSE 0
        END TMORGAMT,
        CASE
            WHEN stm.CURRENCY = 'VND' THEN ABS(to_number(stm.AMOUNT_LCY))
            WHEN stm.CURRENCY <> 'VND' THEN ABS(to_number(stm.AMOUNT_FCY))
            ELSE 0
        END TMTXAMT,
        stm.CURRENCY TMGLCUR,
        stm.ACCOUNT_NUMBER TMACCTNO,
        CASE
            WHEN stm.CURRENCY <> 'VND' THEN CASE
                WHEN stm.AMOUNT_FCY < 0 THEN 'D'
                ELSE 'C'
            END
            ELSE CASE
                WHEN stm.AMOUNT_LCY < 0 THEN 'D'
                ELSE 'C'
            END
        END TMDORC,
        REGEXP_SUBSTR(stm.RECID, '[^.]+', 1, 2) TMSSEQ,
        CASE
            WHEN stm.TRANS_REFERENCE LIKE 'CHG%' THEN CASE
                WHEN stm.TRANSACTION_CODE = '5021' THEN 'VAT - ' || acc.REMARKS
                ELSE acc.REMARKS
            END
        END TMEFTH,
        stm.DATE_TIME TMRESV07,
        acc.COMMIT_TS, 
                acc.REPLICAT_TS, 
                acc.MAPPED_TS,
                'ACC'
    FROM TABLE(V_WINDOW_ID_LIST) V
        JOIN T24DB_OGGDS.fmsb_ac_mapped acc on acc.WINDOW_ID = V.COLUMN_VALUE
        join T24DB_OGGDS.fmsb_stm_tmtran stm on stm.our_reference = acc.recid -- ac_charge_request
        left join T24DB_OGGDS.fmsb_acc_mapped ac on stm.ACCOUNT_NUMBER = ac.recid -- account 
        left join T24DB_OGGDS.fmsb_arr_mapped arr on ac.recid = arr.LINKED_APPL_ID
        left join T24DB_OGGDS.fmsb_fx_mapped fx on stm.our_reference = fx.recid
        left join T24DB_OGGDS.fmsb_tr_mapped tr on stm.transaction_code = tr.recid
    where stm.BOOKING_DATE between to_date(V_TODAY, 'YYYYMMDD') - 2 and to_date(V_TODAY, 'YYYYMMDD') and acc.OP_TYPE <> 'D';

        end if;


     COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
       
    END GEN_FROM_ACC_PROC;

    PROCEDURE GEN_FROM_POR_PROC IS
        V_WINDOW_ID_LIST T_WINDOW_ID_ARRAY;
        V_TODAY          VARCHAR2(8);
    BEGIN

        --   DELETE FROM T24_TMTRAN_POR CDC
        -- WHERE EXISTS (
        --     SELECT 1
        --     FROM F_POR_MAPPED POR
        --     WHERE POR.RECID = CDC.RECID
        --     AND CDC.WINDOW_ID <= POR.WINDOW_ID
        -- )
        -- -- AND ROWNUM <= 5000
        -- RETURNING CDC.WINDOW_ID BULK COLLECT INTO V_WINDOW_ID_LIST;

         SELECT CDC.WINDOW_ID
        BULK COLLECT INTO V_WINDOW_ID_LIST
        FROM T24_TMTRAN_ACC CDC
        WHERE EXISTS (
            SELECT 1
            FROM FMSB_AC_MAPPED AC
            WHERE AC.RECID = CDC.RECID
            AND CDC.WINDOW_ID <= AC.WINDOW_ID
        );


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
                            COMMIT_TS, 
                            REPLICAT_TS, 
                            MAPPED_TS, 
                            CALL_CDC
            )
            select
        case
            when to_date(stm.BOOKING_DATE, 'YYYYMMDD') = to_date(V_TODAY, 'YYYYMMDD') - 2 then 'PP'
            when to_date(stm.BOOKING_DATE, 'YYYYMMDD') = to_date(V_TODAY, 'YYYYMMDD') - 1 then 'PT'
            when stm.RECORD_STATUS = 'REVE'
            and to_date(stm.BOOKING_DATE, 'YYYYMMDD') = to_date(V_TODAY, 'YYYYMMDD') then 'PT'
        end TMTXSTAT,
        case
            
            WHEN stm.SYSTEM_ID = 'PP' THEN CASE
                WHEN tmv.RESERVED1 IS NOT NULL THEN tmv.RESERVED1
                when sup.LOC_FIELD_NAME ='MSB.TRANS.CODE' then sup.LOC_FIELD_VALUE --             WHERE sup.LOC_FIELD_NAME ='MSB.TRANS.CODE'
                end
        end TMOFFSET,
        -- bo xung them PO 
        CASE
                    WHEN stm.PRODUCT_CATEGORY = '12800' THEN 'y'
                END TMIBTTRN,
        CASE
            WHEN stm.PRODUCT_CATEGORY IN ('14016', '18711', '8712') THEN 'E'
            WHEN stm.PRODUCT_CATEGORY = '12800' THEN 'I'
            WHEN stm.PRODUCT_CATEGORY = '56101' THEN 'P'
        END TMEQVTRN,
        por.OUTPUTCHANNEL TMSUMTRN,
        REGEXP_SUBSTR(stm.INPUTTER, '[^_]+', 1, 2) TMTELLID,
        stm.recid TMTXSEQ,
        CASE
            WHEN stm.SYSTEM_ID = 'PP' THEN CASE
                WHEN tmv.RESERVED2 IS NOT NULL THEN tmv.RESERVED2
                ELSE sup.LOC_FIELD_VALUE --             WHERE sup.LOC_FIELD_NAME ='MSB.TRANS.CODE'
            end
        END TMTXCD,
        to_number(stm.BOOKING_DATE) TMENTDT7,
        to_number(stm.VALUE_DATE) TMEFFDT7,
        CASE
            WHEN arr.PRODUCT_LINE = 'DEPOSITS' THEN 'T'
            WHEN arr.PRODUCT_LINE = 'ACCOUNTS' THEN CASE
                WHEN ac.CATEGORY BETWEEN 6000
                AND 6100 THEN 'S'
                ELSE 'D'
            END
            WHEN arr.PRODUCT_LINE = 'LENDING' THEN 'L'
        END TMAPPTYPE,
        to_number(stm.TRANSACTION_CODE) TMHOSTTXCD,
        CASE
            WHEN SUBSTR(stm.DATE_TIME, 1, 6) = SUBSTR(stm.BOOKING_DATE,3,6) THEN to_number(SUBSTR(stm.DATE_TIME, 7) || '00')
            WHEN to_number(SUBSTR(stm.DATE_TIME, 1, 6)) > to_number(SUBSTR(stm.BOOKING_DATE,3,6)) THEN 235959
            ELSE 1
        END TMTIMENT,
        CASE
            WHEN stm.CURRENCY = 'VND' THEN ABS(to_number(stm.AMOUNT_LCY))
            WHEN stm.CURRENCY <> 'VND' THEN ABS(to_number(stm.AMOUNT_FCY))
            ELSE 0
        END TMORGAMT,
        CASE
            WHEN stm.CURRENCY = 'VND' THEN ABS(to_number(stm.AMOUNT_LCY))
            WHEN stm.CURRENCY <> 'VND' THEN ABS(to_number(stm.AMOUNT_FCY))
            ELSE 0
        END TMTXAMT,
        stm.CURRENCY TMGLCUR,
        stm.ACCOUNT_NUMBER TMACCTNO,
        CASE
            WHEN stm.CURRENCY <> 'VND' THEN CASE
                WHEN stm.AMOUNT_FCY < 0 THEN 'D'
                ELSE 'C'
            END
            ELSE CASE
                WHEN stm.AMOUNT_LCY < 0 THEN 'D'
                ELSE 'C'
            END
        END TMDORC,
        REGEXP_SUBSTR(stm.RECID, '[^.]+', 1, 2) TMSSEQ,
        stm.NARRATIVE TMEFTH,
        stm.DATE_TIME TMRESV07,
        por.COMMIT_TS, 
                por.REPLICAT_TS, 
                por.MAPPED_TS,
                'POR'
    FROM TABLE(V_WINDOW_ID_LIST) V
        JOIN T24DB_OGGDS.F_POR_TMTRAN por on por.WINDOW_ID = V.COLUMN_VALUE
        join T24DB_OGGDS.fmsb_stm_tmtran stm on stm.our_reference = por.recid
        join T24DB_OGGDS.F_SUP_TMTRAN sup on por.recid = sup.recid
        join T24DB_OGGDS.F_TMV_TMTRAN tmv on stm.our_reference = tmv.PAYMENTDIRECTION
        left join T24DB_OGGDS.fmsb_acc_mapped ac on stm.ACCOUNT_NUMBER = ac.recid -- account 
        left join T24DB_OGGDS.fmsb_arr_mapped arr on ac.recid = arr.LINKED_APPL_ID
        left join T24DB_OGGDS.fmsb_fx_mapped fx on stm.our_reference = fx.recid
        left join T24DB_OGGDS.fmsb_tr_mapped tr on stm.transaction_code = tr.recid
    where stm.BOOKING_DATE between to_date(V_TODAY, 'YYYYMMDD') - 2 and to_date(V_TODAY, 'YYYYMMDD') and por.OP_TYPE <> 'D';

        end if;
       

         COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END GEN_FROM_POR_PROC;
    
END T24_TMTRAN_PKG;