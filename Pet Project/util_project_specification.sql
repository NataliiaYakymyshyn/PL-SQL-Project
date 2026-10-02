create or replace PACKAGE util_project AS
    
    PROCEDURE work_life_balance;
                       
                      
    
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
    );



    PROCEDURE fire_an_employee (
       p_employee_id IN NUMBER,
       p_fire_date   IN DATE DEFAULT sysdate,
       p_status      IN VARCHAR2 DEFAULT 'Terminated'
    );

END util_project;