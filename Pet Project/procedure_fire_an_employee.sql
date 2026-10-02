create or replace PROCEDURE fire_an_employee (
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
   work_life_balance();
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