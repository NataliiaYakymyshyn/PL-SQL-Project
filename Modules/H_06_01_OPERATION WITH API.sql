--SET DEFINE OFF;
CREATE TABLE interbank_index_ua_history
(
  dt       VARCHAR2(100),
  id_api   VARCHAR2(100),
  value    NUMBER,
  special  VARCHAR2(10)
);

CREATE VIEW interbank_index_ua AS 
SELECT 
    tt.dt,
    tt.id_api,
    tt.value,
    tt.special 
FROM (
    SELECT sys.get_nbu(
        p_url => 'https://bank.gov.ua/NBU_uonia?id_api=UONIA_UnsecLoansDepo&json'
    ) AS json_value 
    FROM dual
)
CROSS JOIN JSON_TABLE(
    json_value, '$[*]'
    COLUMNS(
        dt      VARCHAR2(100) PATH '$.dt',
        id_api  VARCHAR2(100) PATH '$.id_api',
        value   NUMBER        PATH '$.value',
        special VARCHAR2(10)  PATH '$.special'
    )
) tt;


CREATE OR REPLACE PROCEDURE download_ibank_index_ua IS
BEGIN

  INSERT INTO interbank_index_ua_history (dt, id_api, value, special)
  SELECT * FROM interbank_index_ua;

  COMMIT;

END download_ibank_index_ua;
/
BEGIN
    sys.dbms_scheduler.create_job(
        job_name        => 'download_ibank_index_ua_history',
        job_type        => 'PLSQL_BLOCK',
        job_action      => 'BEGIN download_ibank_index_ua(); END;',
        start_date      => SYSDATE,
        repeat_interval => 'FREQ=DAILY; BYHOUR=9; BYMINUTE=0; BYSECOND=0',
        end_date        => TO_DATE(NULL),
        job_class       => 'DEFAULT_JOB_CLASS',
        enabled         => TRUE,
        auto_drop       => FALSE,
        comments        => 'Upload data into interbank_index_ua_history'
    );
END;
/