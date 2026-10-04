create or replace PACKAGE BODY util_project AS


    PROCEDURE work_life_balance is
            v_is_exist NUMBER;
            v_time VARCHAR2(10);
            v_day_num NUMBER;
            v_is_not_working_hours EXCEPTION;

    BEGIN
        log_utils.log_start(p_proc_name => 'work_life_balance');

        v_time := TO_CHAR(SYSDATE, 'HH24:MI');
        v_day_num := TO_NUMBER(TO_CHAR(SYSDATE, 'd'));

        IF v_day_num BETWEEN 1 AND 5 
            AND v_time BETWEEN '08:00' AND '18:00' THEN
            NULL;
        ELSE
            RAISE v_is_not_working_hours;
        END IF;
            EXCEPTION
            WHEN v_is_not_working_hours THEN
                log_utils.log_error(p_proc_name => 'work_life_balance', 
                                   p_sqlerrm => 'You cannot implement changes now. Lets keep this to working hours to maintain proper work-life balance. Thank you.');
                RAISE_APPLICATION_ERROR(-20001, 'You cannot implement changes now. Lets keep this to working hours to maintain proper work-life balance. Thank you.');           
            WHEN OTHERS THEN
                log_utils.log_error(p_proc_name => 'work_life_balance', p_sqlerrm => SQLERRM);
                RAISE;
        
        log_utils.log_finish(p_proc_name => 'work_life_balance');            
    END work_life_balance;


    PROCEDURE add_employee(
        p_first_name       IN VARCHAR2,
        p_last_name        IN VARCHAR2,
        p_email            IN VARCHAR2,
        p_phone_number     IN VARCHAR2,
        p_hire_date        IN DATE DEFAULT TRUNC(SYSDATE, 'dd'),
        p_job_id           IN VARCHAR2,
        p_salary           IN NUMBER,
        p_commission_pct   IN VARCHAR2 DEFAULT NULL,
        p_manager_id       IN NUMBER DEFAULT 100,
        p_department_id    IN VARCHAR2
    )
    IS
        v_min_salary jobs.min_salary%type;
        v_max_salary jobs.max_salary%type;
        v_is_exist NUMBER;

        v_non_existent_job EXCEPTION;
        v_non_existent_department EXCEPTION;
        v_salary_error EXCEPTION;
    
    BEGIN
        log_utils.log_start(p_proc_name => 'add_employee');
    
        util_project.work_life_balance();
    
        SELECT COUNT(*)
        INTO v_is_exist
        FROM jobs j
        WHERE j.job_id = p_job_id;
    
        IF v_is_exist = 0 THEN
            RAISE v_non_existent_job;
        ELSE
            SELECT j.min_salary, j.max_salary
            INTO v_min_salary, v_max_salary
            FROM jobs j
            WHERE j.job_id = p_job_id; 
    
            IF p_salary < v_min_salary OR p_salary > v_max_salary THEN
                RAISE v_salary_error;
            END IF;
        END IF;
    
        SELECT COUNT(*)
        INTO v_is_exist
        FROM departments dp
        WHERE dp.department_id = p_department_id;
    
        IF v_is_exist = 0 THEN
            RAISE v_non_existent_department;
        END IF;
    
        INSERT INTO employees(
            first_name, last_name, email, phone_number,
            hire_date, job_id, salary, commission_pct, manager_id, department_id
        )
        VALUES(        
            p_first_name, p_last_name, p_email, p_phone_number,
            p_hire_date, p_job_id, p_salary, p_commission_pct, p_manager_id, p_department_id
        );
    
        DBMS_OUTPUT.PUT_LINE('Employee ' || p_first_name || ' ' || p_last_name || ' with job '
         || p_job_id || ' and department ' || p_department_id || ' has been added successfully.');
        COMMIT;
        log_utils.log_finish(p_proc_name => 'add_employee');
    
    EXCEPTION
            
        WHEN v_non_existent_job THEN
            log_utils.log_error(p_proc_name => 'add_employee', 
                               p_sqlerrm => 'Non-existent job_id ' || p_job_id || '');
            RAISE_APPLICATION_ERROR(-20001, 'Non-existent job_id ' || p_job_id || '');
            
        WHEN v_non_existent_department THEN
            log_utils.log_error(p_proc_name => 'add_employee', 
                               p_sqlerrm => 'Non-existent department_id ' || p_department_id || '');
            RAISE_APPLICATION_ERROR(-20001, 'Non-existent department_id ' || p_department_id || '');
            
        WHEN v_salary_error THEN
            log_utils.log_error(p_proc_name => 'add_employee', 
                               p_sqlerrm => 'Salary ' || p_salary || ' is out of range for job_id ' || p_job_id || '');
            RAISE_APPLICATION_ERROR(-20001, 'Salary ' || p_salary || ' is out of range for job_id ' || p_job_id || '.');
            
        WHEN OTHERS THEN
            log_utils.log_error(p_proc_name => 'add_employee', p_sqlerrm => SQLERRM);
            RAISE;
    END add_employee;


    PROCEDURE change_attribute_employee(
        p_employee_id    IN NUMBER,
        p_first_name     IN VARCHAR2 DEFAULT NULL,
        p_last_name      IN VARCHAR2 DEFAULT NULL,
        p_email          IN VARCHAR2 DEFAULT NULL,
        p_phone_number   IN VARCHAR2 DEFAULT NULL,
        p_job_id         IN VARCHAR2 DEFAULT NULL,
        p_salary         IN NUMBER DEFAULT NULL,
        p_commission_pct IN NUMBER DEFAULT NULL,
        p_manager_id     IN NUMBER DEFAULT NULL,
        p_department_id  IN NUMBER DEFAULT NULL
    ) IS
        v_exist                   NUMBER;
        v_all_null                EXCEPTION;
        v_non_existent_employee   EXCEPTION;
        v_sql_update              VARCHAR2(2000);

    BEGIN
        log_utils.log_start(p_proc_name => 'change_attribute_employee');
        util_project.work_life_balance();

        SELECT COUNT(*)
        INTO v_exist
        FROM employees
        WHERE employee_id = p_employee_id;

        IF v_exist = 0 THEN
            log_utils.log_finish(p_proc_name => 'change_attribute_employee');
            RAISE v_non_existent_employee;
        ELSIF p_first_name IS NULL
            AND p_last_name IS NULL
            AND p_email IS NULL
            AND p_phone_number IS NULL
            AND p_job_id IS NULL
            AND p_salary IS NULL
            AND p_commission_pct IS NULL
            AND p_manager_id IS NULL
            AND p_department_id IS NULL
        THEN
            log_utils.log_finish(p_proc_name => 'change_attribute_employee');
            DBMS_OUTPUT.PUT_LINE(
            'No Updated Employee''s attributes '
            );
            RAISE v_all_null;
        END IF;

        v_sql_update := 'UPDATE employees
            SET first_name = NVL(:p_first_name, first_name),
                last_name = NVL(:p_last_name, last_name),
                email = NVL(:p_email, email),
                phone_number = NVL(:p_phone_number, phone_number),
                job_id = NVL(:p_job_id, job_id),
                salary = NVL(:p_salary, salary),
                commission_pct = NVL(:p_commission_pct, commission_pct),
                manager_id = NVL(:p_manager_id, manager_id),
                department_id = NVL(:p_department_id, department_id)
            WHERE employee_id = :p_employee_id';

        EXECUTE IMMEDIATE v_sql_update
        USING 
            p_first_name,
            p_last_name,
            p_email,
            p_phone_number,
            p_job_id,
            p_salary,
            p_commission_pct,
            p_manager_id,
            p_department_id,
            p_employee_id;

        DBMS_OUTPUT.PUT_LINE(
            'Employee''s attributes ' || p_employee_id || ' updated successfully'
        );

        COMMIT;
        log_utils.log_finish(p_proc_name => 'change_attribute_employee');

    EXCEPTION
        WHEN v_non_existent_employee THEN
            log_utils.log_error(
                p_proc_name => 'change_attribute_employee',
                p_sqlerrm => 'Non-existent employee_id ' || p_employee_id || ''
            );
            RAISE_APPLICATION_ERROR(-20001, 'Non-existent employee_id ' || p_employee_id || '');

        WHEN v_all_null THEN
            log_utils.log_error(
                p_proc_name => 'change_attribute_employee',
                p_sqlerrm => 'At least one parameter should be provided: p_first_name, p_last_name, p_email, p_phone_number, p_job_id, p_salary, p_commission_pct, p_manager_id, p_department_id'
            );
            RAISE_APPLICATION_ERROR(-20002, 'At least one parameter should be provided: p_first_name, p_last_name, p_email, p_phone_number, p_job_id, p_salary, p_commission_pct, p_manager_id, p_department_id');

        WHEN OTHERS THEN
            log_utils.log_error(
                p_proc_name => 'change_attribute_employee',
                p_sqlerrm => SQLERRM
            );
            RAISE;
    END change_attribute_employee;


    PROCEDURE fire_an_employee (
       p_employee_id IN NUMBER,
       p_fire_date   IN DATE DEFAULT sysdate,
       p_status      IN VARCHAR2 DEFAULT 'Terminated'
    ) IS
       v_is_exist      NUMBER;
       v_non_existent_employee_id EXCEPTION;
       v_employee_id   NUMBER;
       v_first_name    VARCHAR2(100);
       v_last_name     VARCHAR2(100);
       v_email         VARCHAR2(100);
       v_phone_number  VARCHAR2(100);
       v_hire_date     VARCHAR2(10);
       v_job_id        VARCHAR2(10);
       v_salary        NUMBER;
       v_manager_id    NUMBER;
       v_department_id NUMBER;
    BEGIN
       log_utils.log_start(p_proc_name => 'fire_an_employee');
       util_project.work_life_balance();
            SELECT COUNT(*)
            INTO v_is_exist
            FROM employees ee
            WHERE ee.employee_id = p_employee_id;

            IF v_is_exist = 0 THEN
                RAISE v_non_existent_employee_id;
            END IF;

          SELECT employee_id,
                 first_name,
                 last_name,
                 email,
                 phone_number,
                 hire_date,
                 job_id,
                 salary,
                 manager_id,
                 department_id
            INTO
             v_employee_id,
             v_first_name,
             v_last_name,
             v_email,
             v_phone_number,
             v_hire_date,
             v_job_id,
             v_salary,
             v_manager_id,
             v_department_id
            FROM employees
           WHERE employee_id = p_employee_id;

          INSERT INTO employees_history (
             employee_id,
             first_name,
             last_name,
             email,
             phone_number,
             hire_date,
             fire_date,
             status,
             job_id,
             salary,
             manager_id,
             department_id
          ) VALUES
             ( v_employee_id,
               v_first_name,
               v_last_name,
               v_email,
               v_phone_number,
               v_hire_date,
               p_fire_date,
               p_status,
               v_job_id,
               v_salary,
               v_manager_id,
               v_department_id );

          DELETE FROM employees
           WHERE employee_id = p_employee_id;


        util_project.work_life_balance();
        log_utils.log_finish(p_proc_name => 'fire_an_employee');


    EXCEPTION
        WHEN v_non_existent_employee_id THEN
              log_utils.log_error(p_proc_name => 'fire_an_employee', 
                                 p_sqlerrm => 'Non-existent employee_id ' || p_employee_id || '');
              RAISE_APPLICATION_ERROR(-20001, 'Employee ' || p_employee_id || ' does not exist');
        WHEN OTHERS THEN
              log_utils.log_error(p_proc_name => 'fire_an_employee', p_sqlerrm => SQLERRM);
              ROLLBACK;
              RAISE;

    END fire_an_employee;


    FUNCTION table_from_list(p_list_val  IN VARCHAR2,
                                               p_separator IN VARCHAR2 DEFAULT ',') RETURN tab_value_list PIPELINED IS
      out_rec tab_value_list := tab_value_list();
      l_cur   SYS_REFCURSOR;
    BEGIN
      OPEN l_cur FOR
        SELECT (TRIM(REGEXP_SUBSTR(p_list_val, '[^'||p_separator||']+', 1, LEVEL))) AS cur_value
          FROM dual
         CONNECT BY LEVEL <= REGEXP_COUNT(p_list_val, p_separator) + 1;
      BEGIN
        LOOP
          EXIT WHEN l_cur%NOTFOUND;
          FETCH l_cur BULK COLLECT
           INTO out_rec;
          FOR i IN 1 .. out_rec.count LOOP
            PIPE ROW(out_rec(i));
          END LOOP;
        END LOOP;
        CLOSE l_cur;
      EXCEPTION
        WHEN OTHERS THEN
          IF (l_cur%ISOPEN) THEN
            CLOSE l_cur;
            RAISE;
          ELSE
            RAISE;
          END IF;
      END;
    END table_from_list;


    PROCEDURE copy_table(
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
        log_utils.log_start(p_proc_name => 'copy_table');
        util_project.work_life_balance();
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
            BEGIN
                EXECUTE IMMEDIATE cc.ddl_code;

                IF p_copy_data THEN
                    EXECUTE IMMEDIATE 'INSERT INTO ' || v_target || '.' || cc.table_name ||
                                      ' SELECT * FROM ' || v_source || '.' || cc.table_name;
                    COMMIT;
                    to_log(p_appl_proc => 'copy_table', p_message => 'Table ' || cc.table_name || ' copied successfully ' || 'into ' || v_target || ' from ' || v_source);
                END IF;

                v_ok_cnt := v_ok_cnt + 1;
            EXCEPTION
                WHEN OTHERS THEN
                    v_err_cnt := v_err_cnt + 1;
                    log_utils.log_error(p_proc_name => 'copy_table',
                                        p_sqlerrm   => SQLERRM);
                    CONTINUE;
            END;

        END LOOP;

        po_result := 'Copied: ' || v_ok_cnt || ', skipped: ' || v_err_cnt;
        DBMS_OUTPUT.PUT_LINE(po_result);
        COMMIT;
        log_utils.log_finish(p_proc_name => 'copy_table');
    END copy_table;


    FUNCTION get_needed_curr(p_valcode IN VARCHAR2 DEFAULT 'USD',
                                               p_date    IN DATE DEFAULT SYSDATE) RETURN VARCHAR2 IS
      v_json VARCHAR2(1000);
      v_date VARCHAR2(15) := TO_CHAR(p_date,'YYYYMMDD');
    BEGIN
      SELECT sys.get_nbu(p_url => 'https://bank.gov.ua/NBUStatService/v1/statdirectory/exchange?valcode='||p_valcode||'&date='||v_date||'&json') AS res
        INTO v_json
        FROM dual;
      RETURN v_json;
    END get_needed_curr;


    PROCEDURE api_nbu_sync IS
        v_list_currencies VARCHAR2(2000);
    BEGIN
        log_utils.log_start(p_proc_name => 'api_nbu_sync');
        util_project.work_life_balance();

        BEGIN
            SELECT value_text
              INTO v_list_currencies
              FROM sys_params
             WHERE param_name = 'list_currencies';
        EXCEPTION
            WHEN OTHERS THEN
                log_utils.log_error(p_proc_name => 'api_nbu_sync',
                                    p_sqlerrm   => SQLERRM);
                RAISE_APPLICATION_ERROR(-20001,
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


END util_project;
