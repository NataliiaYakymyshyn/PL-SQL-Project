
CREATE OR REPLACE VIEW rep_project_dep_v AS
SELECT ext_fl.project_id, ext_fl.project_name, ext_fl.department_id
FROM EXTERNAL ( ( project_id NUMBER,
                   project_name VARCHAR2(100),
                   department_id NUMBER )
    TYPE oracle_loader DEFAULT DIRECTORY FILES_FROM_SERVER 
    ACCESS PARAMETERS ( records delimited BY newline
                        nologfile
                        nobadfile  
                        fields terminated BY ','
                        missing field VALUES are NULL )
    LOCATION('PROJECTS.csv') 
REJECT LIMIT UNLIMITED  ) ext_fl;
/


CREATE OR REPLACE PROCEDURE export_project_report IS
  file_handle UTL_FILE.FILE_TYPE;
  file_location VARCHAR2(200) := 'FILES_FROM_SERVER';
  file_name VARCHAR2(200) := 'TOTAL_PROJ_INDEX_Nataliia_Yakymyshyn.csv';
  file_content VARCHAR2(10000) := '';
BEGIN

  file_content := 'project_id,project_name,department_name,count_employees,count_managers,sum_salary' || CHR(10);

  FOR cc IN (SELECT pj.project_id, pj.project_name, dp.department_name, 
                    COUNT(em.employee_id) as count_employees, 
                    COUNT(DISTINCT em.manager_id) as count_managers, 
                    SUM(em.salary) as sum_salary
             FROM rep_project_dep_v pj 
             LEFT JOIN employees em ON em.department_id = pj.department_id
             LEFT JOIN departments dp ON dp.department_id = pj.department_id
             GROUP BY pj.project_id, pj.project_name, dp.department_name) LOOP
    
    file_content := file_content || cc.project_id || ',' || 
                                     cc.project_name || ',' || 
                                     cc.department_name || ',' || 
                                     cc.count_employees || ',' || 
                                     cc.count_managers || ',' || 
                                     cc.sum_salary || CHR(10);
  END LOOP;

  file_handle := UTL_FILE.FOPEN(file_location, file_name, 'W');

  UTL_FILE.PUT_RAW(file_handle, UTL_RAW.CAST_TO_RAW(file_content));

  UTL_FILE.FCLOSE(file_handle);
  
  DBMS_OUTPUT.PUT_LINE('Report exported successfully to ' || file_name);

EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END export_project_report;
/

EXEC export_project_report;