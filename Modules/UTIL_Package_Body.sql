CREATE OR REPLACE PACKAGE BODY util AS

    FUNCTION get_job_title(
          p_job_id VARCHAR2
      )
    RETURN VARCHAR2
    IS
        v_job_title jobs.job_title%TYPE;
    BEGIN

        SELECT job_title
        INTO v_job_title
        FROM jobs
        WHERE job_id = p_job_id;

        RETURN v_job_title;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 'Job not found';

    END get_job_title;


    FUNCTION get_dep_name(
              p_employee_id NUMBER
          )
    RETURN VARCHAR2
    IS
        v_department_name departments.department_name%TYPE;
    BEGIN

        SELECT d.department_name
        INTO v_department_name
        FROM employees e
        JOIN departments d
            ON e.department_id = d.department_id
        WHERE e.employee_id = p_employee_id;

        RETURN v_department_name;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 'Department not found';

    END get_dep_name;


    PROCEDURE check_work_time IS
        v_day VARCHAR2(10);
        v_day_num NUMBER;
        v_is_workday VARCHAR2(3);
    BEGIN
        v_day := TO_CHAR(SYSDATE-3, 'day');
        v_day_num := TO_CHAR(SYSDATE-3, 'd');

        IF v_day_num BETWEEN 1 AND 5 THEN
            v_is_workday := 'YES';
        ELSE
            dbms_output.put_line('You cannot insert data today. Please do so on working days. '||'. '||SQLERRM||'. '||SQLCODE);
        END IF;

        DBMS_OUTPUT.PUT_LINE('Current day: ' || v_day);
        DBMS_OUTPUT.PUT_LINE('Is work day: ' || v_is_workday);

    END check_work_time;


    PROCEDURE del_jobs(
              p_job_id  IN VARCHAR2,
              po_result OUT VARCHAR2
          )
    IS
        v_delete_no_data_found EXCEPTION;
    BEGIN
        util.check_work_time;

        BEGIN
            DELETE FROM jobs
            WHERE job_id = p_job_id;

            IF SQL%ROWCOUNT = 0 THEN
                RAISE v_delete_no_data_found;
            END IF;

            po_result := 'Position ' || p_job_id || ' was removed';

        EXCEPTION
            WHEN v_delete_no_data_found THEN
                RAISE_APPLICATION_ERROR(-20001, 'Position ' || p_job_id || ' does not exist');
        END;

    END del_jobs;


    FUNCTION get_sum_price_sales(
              p_table IN VARCHAR2
          ) RETURN NUMBER
    IS
        v_sum NUMBER;
        v_table_name VARCHAR2(20);
        v_message VARCHAR2(500);
    BEGIN
        IF p_table NOT IN ('products', 'products_old') THEN
            v_message := 'Table ' || p_table || '. Unexpected '|| p_table ;
            RAISE_APPLICATION_ERROR(-2000, 'Unexpected ' || p_table );
        END IF;

        v_table_name := p_table;

        EXECUTE IMMEDIATE 'SELECT SUM(price_sales) FROM ' || v_table_name
            INTO v_sum;

        v_message := 'Sum retrieved from ' || v_table_name || ': ' || v_sum;
        dbms_output.put_line(v_message);
        RETURN v_sum;

    EXCEPTION
        WHEN OTHERS THEN
            to_log(p_appl_proc => 'get_sum_price_sales', p_message => NVL(v_message, SQLERRM));
            RAISE;
    END get_sum_price_sales;


    PROCEDURE export_project_report IS
        file_handle UTL_FILE.FILE_TYPE;
        file_location VARCHAR2(200) := 'FILES_FROM_SERVER';
        file_name VARCHAR2(200) := 'TOTAL_PROJ_INDEX_Nataliia_Yakymyshyn.csv';
        file_content VARCHAR2(10000) := '';
    BEGIN

        file_content := 'project_id,project_name,department_name,count_employees,count_managers,sum_salary' || CHR(10);

        FOR cc IN (SELECT pj.project_id, pj.project_name, dp.department_name,
                                    COUNT(em.employee_id) as count_employees,
                                    COUNT(DISTINCT em.manager_id) as count_managers,
                                    SUM(em.salary) as sum_salary
                             FROM rep_project_dep_v pj
                             LEFT JOIN employees em ON em.department_id = pj.department_id
                             LEFT JOIN departments dp ON dp.department_id = pj.department_id
                             GROUP BY pj.project_id, pj.project_name, dp.department_name) LOOP

            file_content := file_content || cc.project_id || ',' ||
                                             cc.project_name || ',' ||
                                             cc.department_name || ',' ||
                                             cc.count_employees || ',' ||
                                             cc.count_managers || ',' ||
                                             cc.sum_salary || CHR(10);
        END LOOP;

        file_handle := UTL_FILE.FOPEN(file_location, file_name, 'W');

        UTL_FILE.PUT_RAW(file_handle, UTL_RAW.CAST_TO_RAW(file_content));

        UTL_FILE.FCLOSE(file_handle);

        DBMS_OUTPUT.PUT_LINE('Report exported successfully to ' || file_name);

    EXCEPTION
        WHEN OTHERS THEN
            RAISE;
    END export_project_report;


    PROCEDURE download_ibank_index_ua IS
    BEGIN

        INSERT INTO interbank_index_ua_history (dt, id_api, value, special)
        SELECT * FROM interbank_index_ua;

        COMMIT;

    END download_ibank_index_ua;


END util;
/
