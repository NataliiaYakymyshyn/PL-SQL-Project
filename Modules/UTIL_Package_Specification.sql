CREATE OR REPLACE PACKAGE util AS

    FUNCTION get_job_title(
          p_job_id VARCHAR2
      ) RETURN VARCHAR2;

    FUNCTION get_dep_name(
              p_employee_id NUMBER
          ) RETURN VARCHAR2;

    PROCEDURE check_work_time;

    PROCEDURE del_jobs(
              p_job_id  IN VARCHAR2,
              po_result OUT VARCHAR2
          );

    FUNCTION get_sum_price_sales(
              p_table IN VARCHAR2
          ) RETURN NUMBER;

    PROCEDURE export_project_report;

    PROCEDURE download_ibank_index_ua;

END util;
/
