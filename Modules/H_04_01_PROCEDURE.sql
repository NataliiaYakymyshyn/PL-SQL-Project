CREATE OR REPLACE PROCEDURE check_work_time IS
    v_day VARCHAR2(10);
    v_day_num NUMBER;
    v_is_workday VARCHAR2(3);
BEGIN
    v_day := TO_CHAR(SYSDATE-3, 'day');
    v_day_num := TO_CHAR(SYSDATE-3, 'd');

    IF v_day_num BETWEEN 1 AND 5 THEN
        v_is_workday := 'YES';
    ELSE
        dbms_output.put_line('You cannot insert data today. Please do so on working days. '||'. '||SQLERRM||'. '||SQLCODE);
    END IF;
                  
    DBMS_OUTPUT.PUT_LINE('Current day: ' || v_day);
    DBMS_OUTPUT.PUT_LINE('Is work day: ' || v_is_workday);
    
END check_work_time;
/
drop PROCEDURE check_work_time;

---procedure is added to packages and it works