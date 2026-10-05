CREATE OR REPLACE PROCEDURE copy_table(
        p_source_scheme IN  VARCHAR2,
        p_target_scheme IN  VARCHAR2 DEFAULT USER,
        p_list_table    IN  VARCHAR2,
        p_copy_data     IN  BOOLEAN  DEFAULT FALSE,
        po_result       OUT VARCHAR2
    ) IS
        v_source        VARCHAR2(128) := UPPER(p_source_scheme);
        v_target        VARCHAR2(128) := UPPER(p_target_scheme);
        v_table_cnt     NUMBER :=0;  
        v_found_cnt     NUMBER :=0;  
        v_ok_cnt        NUMBER :=0;  
        v_exist_cnt     NUMBER :=0;  
        v_err_cnt       NUMBER :=0;  
        v_wrong_cnt     NUMBER :=0; 
        v_exists        NUMBER :=0;
        no_p_list_table EXCEPTION;
    BEGIN
        log_utils.log_start(p_proc_name => 'copy_table');
        util_project.work_life_balance();
        
        SELECT COUNT(DISTINCT UPPER(TRIM(value_list)))
          INTO v_table_cnt
          FROM TABLE(util_project.table_from_list(p_list_val => p_list_table))
         WHERE TRIM(value_list) IS NOT NULL;
    
        IF v_table_cnt = 0 THEN
            RAISE no_p_list_table;
        END IF;

    FOR w IN (
        
            SELECT DISTINCT UPPER(TRIM(value_list)) AS table_name
              FROM TABLE(util_project.table_from_list(p_list_val => p_list_table))
             WHERE TRIM(value_list) IS NOT NULL
               AND UPPER(TRIM(value_list)) NOT IN (SELECT table_name
                                                     FROM all_tables
                                                    WHERE owner = v_source)
        ) LOOP
            v_wrong_cnt:=v_wrong_cnt+1;
            to_log(p_appl_proc => 'copy_table',
                   p_message   => 'Table ' || w.table_name || ' does not exist in ' || v_source || ' - skipped');
    END LOOP;

    FOR cc IN (
            SELECT table_name,
                   'CREATE TABLE ' || v_target || '.' || table_name || ' (' ||
                   LISTAGG(column_name || ' ' || data_type || count_symbol, ', ')
                       WITHIN GROUP (ORDER BY column_id) || ')' AS ddl_code
              FROM (SELECT table_name,
                           column_name,
                           data_type,
                           CASE
                             WHEN data_type IN ('VARCHAR2', 'CHAR') THEN '(' || data_length || ')'
                             WHEN data_type = 'DATE' THEN NULL
                             WHEN data_type = 'NUMBER'
                               THEN REPLACE('(' || data_precision || ',' || data_scale || ')', '(,)', NULL)
                           END AS count_symbol,
                           column_id
                      FROM all_tab_columns
                     WHERE owner = v_source
                       AND table_name IN (SELECT UPPER(value_list)
                                            FROM TABLE(util_project.table_from_list(p_list_val => p_list_table))))
             GROUP BY table_name
        ) LOOP
        v_found_cnt := v_found_cnt + 1;

        BEGIN

                SELECT COUNT(*)
                  INTO v_exists
                  FROM all_tables
                 WHERE owner      = v_target
                   AND table_name = cc.table_name;
    
                IF v_exists > 0 THEN
                    v_exist_cnt := v_exist_cnt + 1;
                    to_log(p_appl_proc => 'copy_table',
                           p_message   => 'Table ' || cc.table_name || ' already exists in ' || v_target || ' - skipped');

                ELSE
                    EXECUTE IMMEDIATE cc.ddl_code;
    
                    IF p_copy_data THEN
                        EXECUTE IMMEDIATE 'INSERT INTO ' || v_target || '.' || cc.table_name ||
                                          ' SELECT * FROM ' || v_source || '.' || cc.table_name;
                        COMMIT;
                    END IF;
    
                    v_ok_cnt := v_ok_cnt + 1;
                    to_log(p_appl_proc => 'copy_table',
                           p_message   => 'Table ' || cc.table_name || ' created in ' || v_target ||
                                          ' from ' || v_source ||
                                          CASE WHEN p_copy_data THEN ' (with data)' END);
                END IF;
    
            EXCEPTION
                WHEN OTHERS THEN
                    v_err_cnt := v_err_cnt + 1;
                    log_utils.log_error(p_proc_name => 'copy_table',
                                        p_sqlerrm   => cc.table_name || ': ' || SQLERRM);
                CONTINUE;
            END;
        END LOOP;

        po_result := 'Copied: '                || v_ok_cnt    ||
                     ', already existed: '     || v_exist_cnt ||
                     ', errors: '              || v_err_cnt   ||
                     ', incorrect table name: '|| v_wrong_cnt;
    
        log_utils.log_finish(p_proc_name => 'copy_table');
    
    EXCEPTION
        WHEN no_p_list_table THEN
            log_utils.log_error(p_proc_name => 'copy_table',
                                p_sqlerrm   => 'p_list_table parameter is empty');
            RAISE_APPLICATION_ERROR(-20008, 'p_list_table parameter should be specified.');
    END copy_table;
/
