create or replace FUNCTION get_dep_name(
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
