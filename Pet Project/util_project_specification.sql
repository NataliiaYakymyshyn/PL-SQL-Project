CREATE OR REPLACE PACKAGE util_project AS

    procedure work_life_balance;

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
    );


    PROCEDURE fire_an_employee (
       p_employee_id IN NUMBER,
       p_fire_date   IN DATE DEFAULT sysdate,
       p_status      IN VARCHAR2 DEFAULT 'Terminated'
    );

    FUNCTION table_from_list(p_list_val  IN VARCHAR2,
                                           p_separator IN VARCHAR2 DEFAULT ',') RETURN tab_value_list PIPELINED;


    PROCEDURE copy_table(
        p_source_scheme IN  VARCHAR2,
        p_target_scheme IN  VARCHAR2 DEFAULT USER,
        p_list_table    IN  VARCHAR2,
        p_copy_data     IN  BOOLEAN  DEFAULT FALSE,
        po_result       OUT VARCHAR2
    );


    FUNCTION get_needed_curr(p_valcode IN VARCHAR2 DEFAULT 'USD',
                                           p_date    IN DATE DEFAULT SYSDATE) RETURN VARCHAR2;


    PROCEDURE api_nbu_sync;


END util_project;
/
