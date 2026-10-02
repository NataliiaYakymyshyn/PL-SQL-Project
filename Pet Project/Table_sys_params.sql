CREATE TABLE sys_params (
    param_name   VARCHAR2(150),
    value_date   DATE,
    value_text   VARCHAR2(2000),
    value_number NUMBER,
    param_descr  VARCHAR2(200)
);
/
BEGIN
    DBMS_SCHEDULER.CREATE_JOB(
        job_name        => 'JOB_API_NBU_SYNC',
        job_type        => 'PLSQL_BLOCK',
        job_action      => 'BEGIN util_project.api_nbu_sync; END;',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=DAILY; BYHOUR=6; BYMINUTE=0; BYSECOND=0',
        enabled         => TRUE,
        comments        => 'Sunc up with API NBU');
END;
/