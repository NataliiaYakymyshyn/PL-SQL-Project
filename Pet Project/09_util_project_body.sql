create or replace PACKAGE BODY util_project AS


    PROCEDURE work_life_balance IS
            v_is_exist NUMBER;
            v_time VARCHAR2(10);
            v_day_num NUMBER;
            v_is_not_working_hours EXCEPTION;    
    BEGIN    
        v_time := to_char(sysdate, 'HH24:MI');
        v_day_num := to_number(to_char(sysdate, 'd'));
    
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
                raise_application_error(-20001, 'You cannot implement changes now. Lets keep this to working hours to maintain proper work-life balance. Thank you.');           
            WHEN OTHERS THEN
                log_utils.log_error(p_proc_name => 'work_life_balance', p_sqlerrm => sqlerrm);
                RAISE;    
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
          
        EXCEPTION
           WHEN v_non_existent_employee_id THEN
              log_utils.log_error(p_proc_name => 'fire_an_employee', 
                                 p_sqlerrm => 'Non-existent employee_id "' || p_employee_id || '"');
              RAISE_APPLICATION_ERROR(-20001, 'Employee ' || p_employee_id || ' does not exist');
           WHEN OTHERS THEN
              log_utils.log_error(p_proc_name => 'fire_an_employee', p_sqlerrm => SQLERRM);
              ROLLBACK;
              RAISE;
    
       log_utils.log_finish(p_proc_name => 'fire_an_employee');
    END fire_an_employee;

END util_project;