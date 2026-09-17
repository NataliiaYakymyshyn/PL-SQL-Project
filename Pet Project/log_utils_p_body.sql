CREATE OR REPLACE PACKAGE BODY log_utils AS


  PROCEDURE log_start(p_proc_name IN VARCHAR2,
                      p_text IN VARCHAR2 DEFAULT NULL) IS
  v_text VARCHAR2(2000);

  BEGIN
    IF p_text IS NULL THEN
        v_text := 'Start of procedure: ' || p_proc_name;
        ELSE
        v_text := p_text;    
    END IF;
    to_log(p_appl_proc => p_proc_name, p_message => v_text);

  END log_start; 




  PROCEDURE log_finish(p_proc_name IN VARCHAR2,
                      p_text IN VARCHAR2 DEFAULT NULL) IS
  v_text VARCHAR2(2000);

  BEGIN
    IF p_text IS NULL THEN
        v_text := 'Finish of procedure: ' || p_proc_name;
        ELSE
        v_text := p_text;    
    END IF;
    to_log(p_appl_proc => p_proc_name, p_message => v_text);

  END log_finish; 

    

  PROCEDURE log_error(p_proc_name IN VARCHAR2,
                      p_sqlerrm IN VARCHAR2,
                      p_text IN VARCHAR2 DEFAULT NULL) IS
  v_text VARCHAR2(2000);

  BEGIN 
    p_sqlerrm := REPLACE(p_sqlerrm, CHR(10), SQLERRM);
    IF p_text IS NULL THEN
        v_text := 'Error in procedure: ' || p_proc_name || ' - Error: ' || p_sqlerrm;
        ELSE
        v_text := p_text;    
    END IF;
    to_log(p_appl_proc => p_proc_name, p_message => v_text);

  END log_error;



END log_utils;