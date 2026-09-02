create or replace TRIGGER hire_date_update
    BEFORE UPDATE ON employees
    FOR EACH ROW
DECLARE 
    PRAGMA autonomous_transaction;
BEGIN

    IF :OLD.job_id != :NEW.job_id THEN

        :NEW.hire_date := TRUNC(SYSDATE);

    END IF;

    COMMIT;

END hire_date_update;

/
update employees em
set em.job_id='IT_PROG'
where employee_id = 150;
commit;
/