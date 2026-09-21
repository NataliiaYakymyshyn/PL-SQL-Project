CREATE OR REPLACE PROCEDURE change_attribute_employee(
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
    work_life_balance();

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
            p_sqlerrm => 'Non-existent employee_id "' || p_employee_id || '"'
        );
        RAISE_APPLICATION_ERROR(-20001, 'Non-existent employee_id "' || p_employee_id || '"');
        
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