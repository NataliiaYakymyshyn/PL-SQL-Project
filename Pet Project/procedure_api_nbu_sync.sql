create or replace PROCEDURE api_nbu_sync IS
    v_list_currencies VARCHAR2(2000);
BEGIN

    BEGIN
        SELECT value_text
          INTO v_list_currencies
          FROM sys_params
         WHERE param_name = 'list_currencies';
    EXCEPTION
        WHEN OTHERS THEN
            log_utils.log_error(p_proc_name => 'util_project.api_nbu_sync',
                                p_sqlerrm   => SQLERRM);
            RAISE_APPLICATION_ERROR(-20001,
                'Error with parameter list_currencies: ' || SQLERRM);
    END;

    -- Steps 3-4: loop over currencies and insert data from the API
    FOR cc IN (SELECT value_list AS curr
                 FROM TABLE(util_project.table_from_list(p_list_val => v_list_currencies))) LOOP

        INSERT INTO cur_exchange (r030, txt, rate, cur, exchangedate)
        SELECT r030, txt, rate, cur, exchangedate
          FROM TABLE(util_project.get_needed_curr(p_currency => cc.curr));

    END LOOP;

    COMMIT;

    log_utils.log_finish(p_proc_name => 'util_project.api_nbu_sync');
END api_nbu_sync;