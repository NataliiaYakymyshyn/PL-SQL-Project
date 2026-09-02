DECLARE
    V_DATE DATE := TO_DATE('28-06-2026','DD-MM-YYYY');
    V_DAY NUMBER;
    
BEGIN
    V_DAY := TO_NUMBER(TO_CHAR(V_DATE,'DD'));
    IF LAST_DAY(TRUNC(SYSDATE))=V_DATE THEN
        DBMS_OUTPUT.PUT_LINE('Payday'); 
    ELSIF V_DAY=15 THEN 
        DBMS_OUTPUT.PUT_LINE('Prepayment'); 
    ELSIF V_DAY<15 THEN 
        DBMS_OUTPUT.PUT_LINE('Waiting for the advance'); 
    ELSE 
        DBMS_OUTPUT.PUT_LINE('Waiting for payday'); 
    END IF;

END;
/   