CREATE OR REPLACE FUNCTION get_needed_curr(p_valcode IN VARCHAR2 DEFAULT 'USD',
                                           p_date    IN DATE DEFAULT SYSDATE) RETURN VARCHAR2 IS
  v_json VARCHAR2(1000);
  v_date VARCHAR2(15) := TO_CHAR(p_date,'YYYYMMDD');
BEGIN
  SELECT sys.get_nbu(p_url => 'https://bank.gov.ua/NBUStatService/v1/statdirectory/exchange?valcode='||p_valcode||'&date='||v_date||'&json') AS res
    INTO v_json
    FROM dual;
  RETURN v_json;
END get_needed_curr;
/
