CREATE OR REPLACE PACKAGE util AS

    FUNCTION get_job_title(
        p_job_id VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_dep_name(
        p_employee_id NUMBER
    ) RETURN VARCHAR2;

    PROCEDURE del_jobs(
        p_job_id IN VARCHAR2,
        po_result OUT VARCHAR2
    );

END util;
/

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

    PROCEDURE del_jobs(
        p_job_id IN VARCHAR2,
        po_result OUT VARCHAR2
    )
    IS
        v_is_exist NUMBER;
    BEGIN

        SELECT COUNT(*)
        INTO v_is_exist
        FROM jobs
        WHERE job_id = p_job_id;

        IF v_is_exist = 0 THEN

            po_result := 'Position ' || p_job_id || ' does not exist';

        ELSE

            DELETE FROM jobs
            WHERE job_id = p_job_id;

            po_result := 'Position ' || p_job_id || ' was removed';

        END IF;

    END del_jobs;

END util;
/


DROP FUNCTION get_dep_name;

DROP PROCEDURE del_jobs;
/