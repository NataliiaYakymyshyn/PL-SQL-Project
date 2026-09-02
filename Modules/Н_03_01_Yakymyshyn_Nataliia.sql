create or replace PROCEDURE del_jobs(
    p_job_id  IN VARCHAR2,
    po_result OUT VARCHAR2
)
IS
    v_is_exist NUMBER;
BEGIN

    SELECT COUNT(*)
    INTO v_is_exist
    FROM nataliya_tpm.jobs
    WHERE job_id = p_job_id;

    IF v_is_exist = 0 THEN

        po_result := 'Job' || p_job_id || ' doesn''t exist';

    ELSE

        DELETE FROM nataliya_tpm.jobs
        WHERE job_id = p_job_id;

        po_result := 'Job ' || p_job_id || ' is removed';

    END IF;

END del_jobs;
