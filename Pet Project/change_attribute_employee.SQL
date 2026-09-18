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
) is

v_all_null EXCEPTION;
v_non_existent_employee_id EXCEPTION;
    
    BEGIN
   log_utils.log_start(p_proc_name => 'change_attribute_employee');
   work_life_balance();
    NULL;
    IF p_first_name IS NULL
       AND p_last_name IS NULL
       AND p_email IS NULL
       AND p_phone_number IS NULL
       AND p_job_id IS NULL
       AND p_salary IS NULL
       AND p_commission_pct IS NULL
       AND p_manager_id IS NULL
       AND p_department_id IS NULL
    THEN
        RAISE v_all_null;
    END IF;

    BEGIN
        UPDATE employees
        SET first_name = NVL(p_first_name, first_name),
            last_name = NVL(p_last_name, last_name),
            email = NVL(p_email, email),
            phone_number = NVL(p_phone_number, phone_number),
            job_id = NVL(p_job_id, job_id),
            salary = NVL(p_salary, salary),
            commission_pct = NVL(p_commission_pct, commission_pct),
            manager_id = NVL(p_manager_id, manager_id),
            department_id = NVL(p_department_id, department_id)
        WHERE employee_id = p_employee_id;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE v_non_existent_employee_id;
        END IF;

        DBMS_OUTPUT.PUT_LINE(
            'Employee''s attributes ' || p_employee_id || ' updated successfully'
        );
    EXCEPTION
        WHEN OTHERS THEN
            log_utils.log_error(
                p_proc_name => 'change_attribute_employee',
                p_sqlerrm => SQLERRM
            );
            RAISE;
    END;

    COMMIT;
    log_utils.log_finish(p_proc_name => 'change_attribute_employee');
EXCEPTION
    WHEN v_all_null THEN
        log_utils.log_error(
            p_proc_name => 'change_attribute_employee',
            p_sqlerrm => 'At least one employee attribute must be provided'
        );
        RAISE_APPLICATION_ERROR(-20001, 'At least one employee attribute must be provided');
    WHEN v_non_existent_employee_id THEN
        log_utils.log_error(
            p_proc_name => 'change_attribute_employee',
            p_sqlerrm => 'Employee ' || p_employee_id || ' does not exist'
        );
        RAISE_APPLICATION_ERROR(-20002, 'Employee ' || p_employee_id || ' does not exist');
    WHEN OTHERS THEN
        log_utils.log_error(p_proc_name => 'change_attribute_employee', p_sqlerrm => SQLERRM);
        ROLLBACK;
        RAISE;
END change_attribute_employee;









