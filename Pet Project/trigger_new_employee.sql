CREATE OR REPLACE TRIGGER trg_employee_id_auto
BEFORE INSERT ON employees
FOR EACH ROW
DECLARE
  v_max_id NUMBER;
BEGIN
  IF :NEW.employee_id IS NULL THEN
    SELECT NVL(MAX(employee_id), 0) + 1
    INTO v_max_id
    FROM employees;
    :NEW.employee_id := v_max_id;
  END IF;
END;
/