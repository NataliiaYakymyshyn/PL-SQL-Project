TYPE rec_value_list IS RECORD (value_list VARCHAR2(100));
TYPE tab_value_list IS TABLE OF rec_value_list;


CREATE OR REPLACE FUNCTION table_from_list(p_list_val  IN VARCHAR2,
                                           p_separator IN VARCHAR2 DEFAULT ',') RETURN tab_value_list PIPELINED IS
  out_rec tab_value_list := tab_value_list();
  l_cur   SYS_REFCURSOR;
BEGIN
  OPEN l_cur FOR
    SELECT rec_value_list(TRIM(REGEXP_SUBSTR(p_list_val, '[^'||p_separator||']+', 1, LEVEL))) AS cur_value
      FROM dual
     CONNECT BY LEVEL <= REGEXP_COUNT(p_list_val, p_separator) + 1;
  BEGIN
    LOOP
      EXIT WHEN l_cur%NOTFOUND;
      FETCH l_cur BULK COLLECT
       INTO out_rec;
      FOR i IN 1 .. out_rec.count LOOP
        PIPE ROW(out_rec(i));
      END LOOP;
    END LOOP;
    CLOSE l_cur;
  EXCEPTION
    WHEN OTHERS THEN
      IF (l_cur%ISOPEN) THEN
        CLOSE l_cur;
        RAISE;
      ELSE
        RAISE;
      END IF;
  END;
END table_from_list;
/

SELECT *
  FROM TABLE(table_from_list(p_list_val => 'USD,EUR,KZT,AMD,GBP,ILS'));