create or replace PROCEDURE add_employee(
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
    
        work_life_balance();
    
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
    
        DBMS_OUTPUT.PUT_LINE('Employee "' || p_first_name || ' ' || p_last_name || '" with job "'
         || p_job_id || '" and department "' || p_department_id || '" has been added successfully.');
        COMMIT;
        log_utils.log_finish(p_proc_name => 'add_employee');
    
    EXCEPTION
            
        WHEN v_non_existent_job THEN
            log_utils.log_error(p_proc_name => 'add_employee', 
                               p_sqlerrm => 'Non-existent job_id "' || p_job_id || '"');
            RAISE_APPLICATION_ERROR(-20001, 'Non-existent job_id "' || p_job_id || '"');
            
        WHEN v_non_existent_department THEN
            log_utils.log_error(p_proc_name => 'add_employee', 
                               p_sqlerrm => 'Non-existent department_id "' || p_department_id || '"');
            RAISE_APPLICATION_ERROR(-20001, 'Non-existent department_id "' || p_department_id || '"');
            
        WHEN v_salary_error THEN
            log_utils.log_error(p_proc_name => 'add_employee', 
                               p_sqlerrm => 'Salary ' || p_salary || ' is out of range for job_id "' || p_job_id || '"');
            RAISE_APPLICATION_ERROR(-20001, 'Salary ' || p_salary || ' is out of range for job_id "' || p_job_id || '".');
            
        WHEN OTHERS THEN
            log_utils.log_error(p_proc_name => 'add_employee', p_sqlerrm => SQLERRM);
            RAISE;
    END add_employee;