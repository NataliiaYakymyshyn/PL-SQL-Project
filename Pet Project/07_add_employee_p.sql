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
    v_time VARCHAR2(10);
    v_day_num NUMBER;
    v_is_not_working_hours EXCEPTION;
    v_non_existent_job EXCEPTION;
    v_non_existent_department EXCEPTION;
    v_salary_error EXCEPTION;

BEGIN
    log_utils.log_start;

    v_time := TO_CHAR(SYSDATE, 'HH24:MI');
    v_day_num := TO_CHAR(SYSDATE, 'd');
    IF v_day_num BETWEEN 1 AND 5 
       AND v_time BETWEEN '08:00' AND '18:00' THEN
       continue;
    ELSE
        raise v_is_not_working_hours;
        EXIT;
    END IF;


    SELECT COUNT(*)
    INTO v_is_exist
    FROM jobs j
    WHERE j.job_id = p_job_id;
    IF v_is_exist = 0 THEN
        RAISE v_non_existent_job;
        EXIT;
    ELSE
        SELECT j.min_salary, j.max_salary
        into v_min_salary, v_max_salary
        FROM jobs j
        WHERE j.job_id = p_job_id; 
        
        IF p_salary < v_min_salary OR p_salary > v_max_salary THEN
            RAISE v_salary_error;
            EXIT;
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
        employee_id,
        first_name,
        last_name,
        email,
        phone_number,
        hire_date,
        job_id,
        salary,
        commission_pct,
        manager_id,
        department_id
    )
    VALUES(
        employee_seq.NEXTVAL,
        p_first_name,
        p_last_name,
        p_email,
        p_phone_number,
        p_hire_date,
        p_job_id,
        p_salary,
        p_commission_pct,
        p_manager_id,
        p_department_id
    );
    exception
        when v_is_not_working_hours then
            RAISE_APPLICATION_ERROR(-20001, 'You can insert data only on working hours.');
            dbms_output.put_line('You cannot insert data today. Please do so on working days. '||'. '||SQLERRM||'. '||SQLCODE);
        when v_non_existent_job then
            RAISE_APPLICATION_ERROR(-20001, 'Non-existent job_id "' || p_job_id || '" is added');
            dbms_output.put_line('Non-existent job_id "' || p_job_id || '" is added. Please check. '||'. '||SQLERRM||'. '||SQLCODE);
        when v_non_existent_department then
            RAISE_APPLICATION_ERROR(-20001, 'Non-existent department_id "' || p_department_id || '" is added');
            dbms_output.put_line('Non-existent department_id "' || p_department_id || '" is added. Please check. '||'. '||SQLERRM||'. '||SQLCODE);
        when v_salary_error then
            RAISE_APPLICATION_ERROR(-20001, 'Salary ' || p_salary || ' is out of range for job_id "' || p_job_id || '". Please check.');
            dbms_output.put_line('Salary ' || p_salary || ' is out of range for job_id "' || p_job_id || '". Please check. '||'. '||SQLERRM||'. '||SQLCODE);
        WHEN OTHERS THEN
            log_utils.log_error(p_proc_name => 'add_employee', p_sqlerrm => SQLERRM);
            RAISE;

    dbms_output.put_line('Employee "' || p_first_name || ' ' || p_last_name || '" with job "'
     || p_job_id || '" and department "' || p_department_id || '" has been added successfully. ');
    commit;
    log_utils.log_finish; 
END add_employee;
