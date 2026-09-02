CREATE OR REPLACE FUNCTION get_sum_price_sales(
    p_table IN VARCHAR2
) RETURN NUMBER
IS
    v_sum NUMBER;
    v_table_name VARCHAR2(20);
    v_message VARCHAR2(500);
BEGIN
    IF p_table NOT IN ('products', 'products_old') THEN
        v_message := 'Table ' || p_table || '. Unexpected '|| p_table ;
        RAISE_APPLICATION_ERROR(-2000, 'Unexpected ' || p_table );
    END IF;
    
    v_table_name := p_table;

    EXECUTE IMMEDIATE 'SELECT SUM(price_sales) FROM ' || v_table_name
        INTO v_sum;
    
    v_message := 'Sum retrieved from ' || v_table_name || ': ' || v_sum;
    dbms_output.put_line(v_message);
    RETURN v_sum;
    
EXCEPTION
    WHEN OTHERS THEN
        to_log(p_appl_proc => 'get_sum_price_sales', p_message => NVL(v_message, SQLERRM));
        RAISE;
END get_sum_price_sales;
/
BEGIN
    dbms_output.put_line('Sum of price_sales: ' || get_sum_price_sales(p_table => 'products'));
END;
/

---procedure is added to packages and it works