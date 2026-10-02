CREATE TABLE cur_exchange (
    r030         NUMBER,          
    txt          VARCHAR2(100),   
    rate         NUMBER(18,6),    
    cur          VARCHAR2(3),     
    exchangedate DATE,            
    load_date    DATE DEFAULT SYSDATE,
    CONSTRAINT cur_exchange_uk UNIQUE (cur, exchangedate)
);