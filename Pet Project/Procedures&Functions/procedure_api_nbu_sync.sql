create or replace PROCEDURE api_nbu_sync IS
        v_list_currencies VARCHAR2(2000);
    BEGIN
        log_utils.log_start(p_proc_name => 'api_nbu_sync');

        BEGIN
            SELECT value_text
              INTO v_list_currencies
              FROM sys_params
             WHERE param_name = 'list_currencies';
        EXCEPTION
            WHEN OTHERS THEN
                log_utils.log_error(p_proc_name => 'api_nbu_sync',
                                    p_sqlerrm   => SQLERRM);
                RAISE_APPLICATION_ERROR(-20009,
                    'Error with parameter list_currencies: ' || SQLERRM);
        END;

        FOR cc IN (SELECT value_list AS curr
                     FROM TABLE(util_project.table_from_list(p_list_val => v_list_currencies))) LOOP

                    INSERT INTO cur_exchange (r030, txt, rate, cur, exchangedate)
                    SELECT tt.r030,
                           tt.txt,
                           tt.rate,
                           tt.cur,
                           TO_DATE(tt.exchangedate, 'DD.MM.YYYY')
                      FROM (SELECT get_needed_curr(p_valcode => cc.curr) AS json_value FROM dual) j
                     CROSS JOIN JSON_TABLE(j.json_value, '$[*]'
                                  COLUMNS (r030         NUMBER        PATH '$.r030',
                                           txt          VARCHAR2(100) PATH '$.txt',
                                           rate         NUMBER        PATH '$.rate',
                                           cur          VARCHAR2(10)  PATH '$.cc',
                                           exchangedate VARCHAR2(20)  PATH '$.exchangedate')) tt;

        END LOOP;

        COMMIT;

        log_utils.log_finish(p_proc_name => 'api_nbu_sync');
    END api_nbu_sync;
