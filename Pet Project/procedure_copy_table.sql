CREATE OR REPLACE PROCEDURE copy_table(
    p_source_scheme IN  VARCHAR2,
    p_target_scheme IN  VARCHAR2 DEFAULT USER,
    p_list_table    IN  VARCHAR2,
    p_copy_data     IN  BOOLEAN  DEFAULT FALSE,
    po_result       OUT VARCHAR2
) IS
    v_source  VARCHAR2(128) := UPPER(p_source_scheme);
    v_target  VARCHAR2(128) := UPPER(p_target_scheme);
    v_ok_cnt  NUMBER := 0;
    v_err_cnt NUMBER := 0;
BEGIN
    to_log(p_appl_proc => 'copy_table',
           p_message   => 'Start: ' || v_source || ' -> ' || v_target || ', tables: ' || p_list_table);

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
                                        FROM TABLE(util.table_from_list(p_list_val => p_list_table))))
         GROUP BY table_name
    ) LOOP
        BEGIN
            EXECUTE IMMEDIATE cc.ddl_code;

            IF p_copy_data THEN
                EXECUTE IMMEDIATE 'INSERT INTO ' || v_target || '.' || cc.table_name ||
                                  ' SELECT * FROM ' || v_source || '.' || cc.table_name;
                COMMIT;
            END IF;

            v_ok_cnt := v_ok_cnt + 1;
        EXCEPTION
            WHEN OTHERS THEN
                v_err_cnt := v_err_cnt + 1;
                to_log(p_appl_proc => 'copy_table',
                       p_message   => 'Skipped ' || cc.table_name || ': ' || SQLERRM);
                CONTINUE;
        END;

        to_log(p_appl_proc => 'copy_table',
               p_message   => 'Table ' || cc.table_name || ' copied to ' || v_target ||
                              CASE WHEN p_copy_data THEN ' with data' ELSE ' (structure only)' END);
    END LOOP;

    po_result := 'Copied: ' || v_ok_cnt || ', skipped: ' || v_err_cnt;
    to_log(p_appl_proc => 'copy_table', p_message => 'Finish. ' || po_result);
END copy_table;
/