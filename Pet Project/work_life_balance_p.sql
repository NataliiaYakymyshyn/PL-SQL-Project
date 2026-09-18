create or replace procedure work_life_balance is
        v_is_exist NUMBER;
        v_time VARCHAR2(10);
        v_day_num NUMBER;
        v_is_not_working_hours EXCEPTION;

begin
    log_utils.log_start(p_proc_name => 'work_balance');
    
    v_time := TO_CHAR(SYSDATE, 'HH24:MI');
    v_day_num := TO_NUMBER(TO_CHAR(SYSDATE, 'd'));
    
    IF v_day_num BETWEEN 1 AND 5 
        AND v_time BETWEEN '08:00' AND '18:00' THEN
        NULL;
    ELSE
        RAISE v_is_not_working_hours;
    END IF;
        EXCEPTION
        WHEN v_is_not_working_hours THEN
            log_utils.log_error(p_proc_name => 'work_life_balance', 
                               p_sqlerrm => 'You cannot implement changes now. Lets keep this to working hours to maintain proper work-life balance. Thank you.');
            RAISE_APPLICATION_ERROR(-20001, 'You cannot implement changes now. Lets keep this to working hours to maintain proper work-life balance. Thank you.');           
        WHEN OTHERS THEN
            log_utils.log_error(p_proc_name => 'work_life_balance', p_sqlerrm => SQLERRM);
            RAISE;
        
    
end work_life_balance;