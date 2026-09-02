CREATE OR REPLACE PROCEDURE del_jobs(
    p_job_id IN VARCHAR2,
    po_result OUT VARCHAR2
)
IS
    v_delete_no_data_found EXCEPTION;
BEGIN
    util.check_work_time;
    
    BEGIN
        DELETE FROM jobs
        WHERE job_id = p_job_id;
        
        IF SQL%ROWCOUNT = 0 THEN
            RAISE v_delete_no_data_found;
        END IF;
        
        po_result := 'Position ' || p_job_id || ' was removed';
    
    EXCEPTION
        WHEN v_delete_no_data_found THEN
            RAISE_APPLICATION_ERROR(-20001, 'Position ' || p_job_id || ' does not exist');
    END;
    
END del_jobs;
/