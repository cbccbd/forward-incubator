--1.1
create or replace PROCEDURE saveCOMMUTATOR 
    (
    p_IP_ADDRESS IN INCB_COMMUTATOR.IP_ADDRESS%TYPE,
    p_ID_COMMUTATOR_TYPE IN INCB_COMMUTATOR.ID_COMMUTATOR_TYPE%TYPE,
    p_V_DESCRIPTION IN INCB_COMMUTATOR.V_DESCRIPTION%TYPE DEFAULT NULL,
    p_B_DELETED IN INCB_COMMUTATOR.B_DELETED%TYPE DEFAULT 0,
    p_V_MAC_ADDRESS IN INCB_COMMUTATOR.V_MAC_ADDRESS%TYPE,
    p_V_COMMUNITY_READ IN INCB_COMMUTATOR.V_COMMUNITY_READ%TYPE,
    p_V_COMMUNITY_WRITE IN INCB_COMMUTATOR.V_COMMUNITY_WRITE%TYPE,
    p_REMOTE_ID IN INCB_COMMUTATOR.REMOTE_ID%TYPE,
    p_B_NEED_CONVERT_HEX IN INCB_COMMUTATOR.B_NEED_CONVERT_HEX%TYPE DEFAULT 0,
    p_ACTION IN VARCHAR2
    )
    
IS

invalid_ip EXCEPTION;
not_unique_ip EXCEPTION;
not_unique_mac EXCEPTION;

ip_ne_ip NUMBER;
CURSOR validate_ip IS
SELECT 1
    FROM INCB_COMMUTATOR
    WHERE IP_ADDRESS = p_IP_ADDRESS;
    
mac_ne_mac NUMBER;
CURSOR validate_mac IS
SELECT 1
    FROM INCB_COMMUTATOR
    WHERE V_MAC_ADDRESS = p_V_MAC_ADDRESS;

edit_var INCB_COMMUTATOR%ROWTYPE;   
CURSOR edit_or_del IS
    SELECT * FROM INCB_COMMUTATOR
        WHERE IP_ADDRESS = p_IP_ADDRESS
        AND V_MAC_ADDRESS = p_V_MAC_ADDRESS
        AND V_COMMUNITY_READ = p_V_COMMUNITY_READ
        AND V_COMMUNITY_WRITE = p_V_COMMUNITY_WRITE
    FOR UPDATE;


BEGIN

--посчитал, что регулярка на один строковый объект много не съест. иначе писать огромную простыню
IF regexp_instr(p_IP_ADDRESS,'^([01]?\d\d?|2[0-4]\d|25[0-5])\.([01]?\d\d?|2[0-4]\d|25[0-5])\.([01]?\d\d?|
2[0-4]\d|25[0-5])\.([01]?\d\d?|2[0-4]\d|25[0-5])$') = 0
    THEN RAISE invalid_ip;
END IF;


CASE p_ACTION 
    WHEN 'CREATE' THEN
        OPEN validate_ip;
            FETCH validate_ip INTO ip_ne_ip;
                IF validate_ip%NOTFOUND 
                    THEN ip_ne_ip := 0;
                END IF;
        CLOSE validate_ip;

        IF ip_ne_ip != 0 
            THEN RAISE not_unique_ip;
        END IF;

        OPEN validate_mac;
            FETCH validate_mac INTO mac_ne_mac;
                IF validate_mac%NOTFOUND 
                    THEN mac_ne_mac := 0;
                END IF;
        CLOSE validate_mac;

        IF mac_ne_mac != 0 
            THEN RAISE not_unique_mac;
        END IF;
        
        IF 
            p_B_NEED_CONVERT_HEX = 1
            THEN 
                INSERT INTO INCB_COMMUTATOR ("ID_COMMUTATOR", "IP_ADDRESS", "ID_COMMUTATOR_TYPE", "B_DELETED", "V_MAC_ADDRESS", "V_COMMUNITY_READ", "V_COMMUNITY_WRITE", "REMOTE_ID_HEX")
                VALUES (s_incb_commutator.NEXTVAL, p_IP_ADDRESS, p_ID_COMMUTATOR_TYPE, p_B_DELETED, p_V_MAC_ADDRESS, p_V_COMMUNITY_READ, p_V_COMMUNITY_WRITE, p_REMOTE_ID);
            ELSE 
                INSERT INTO INCB_COMMUTATOR ("ID_COMMUTATOR", "IP_ADDRESS", "ID_COMMUTATOR_TYPE", "B_DELETED", "V_MAC_ADDRESS", "V_COMMUNITY_READ", "V_COMMUNITY_WRITE", "REMOTE_ID")
                VALUES (s_incb_commutator.NEXTVAL, p_IP_ADDRESS, p_ID_COMMUTATOR_TYPE, p_B_DELETED, p_V_MAC_ADDRESS, p_V_COMMUNITY_READ, p_V_COMMUNITY_WRITE, p_REMOTE_ID);
        END IF;
    WHEN 'EDIT' THEN
        CASE p_B_NEED_CONVERT_HEX
            WHEN 0 THEN
                OPEN edit_or_del;
                    LOOP
                        FETCH edit_or_del INTO edit_var;
                        EXIT WHEN edit_or_del%notfound;
                        UPDATE INCB_COMMUTATOR
                            SET 
                                IP_ADDRESS = p_IP_ADDRESS,                 
                                ID_COMMUTATOR_TYPE = p_ID_COMMUTATOR_TYPE,
                                V_DESCRIPTION = p_V_DESCRIPTION,
                                B_DELETED = p_B_DELETED,
                                V_MAC_ADDRESS = p_V_MAC_ADDRESS,
                                V_COMMUNITY_READ = p_V_COMMUNITY_READ,
                                V_COMMUNITY_WRITE = p_V_COMMUNITY_WRITE,
                                REMOTE_ID = p_REMOTE_ID,         
                                REMOTE_ID_HEX = NULL,
                                B_NEED_CONVERT_HEX = p_B_NEED_CONVERT_HEX
                            WHERE CURRENT OF edit_or_del;
                    END LOOP;
                CLOSE edit_or_del;
            WHEN 1 THEN
                OPEN edit_or_del;
                    LOOP
                        FETCH edit_or_del INTO edit_var;
                        EXIT WHEN edit_or_del%notfound;
                        UPDATE INCB_COMMUTATOR
                            SET 
                                IP_ADDRESS = p_IP_ADDRESS,                 
                                ID_COMMUTATOR_TYPE = p_ID_COMMUTATOR_TYPE,
                                V_DESCRIPTION = p_V_DESCRIPTION,
                                B_DELETED = p_B_DELETED,
                                V_MAC_ADDRESS = p_V_MAC_ADDRESS,
                                V_COMMUNITY_READ = p_V_COMMUNITY_READ,
                                V_COMMUNITY_WRITE = p_V_COMMUNITY_WRITE,
                                REMOTE_ID = NULL,          
                                REMOTE_ID_HEX = p_REMOTE_ID,
                                B_NEED_CONVERT_HEX = p_B_NEED_CONVERT_HEX
                            WHERE CURRENT OF edit_or_del;
                    END LOOP;
                CLOSE edit_or_del;
            END CASE;
    WHEN 'DELETE' THEN
        OPEN edit_or_del;
            LOOP
                FETCH edit_or_del INTO edit_var;
                EXIT WHEN edit_or_del%notfound;
                DELETE FROM INCB_COMMUTATOR WHERE CURRENT OF edit_or_del;
            END LOOP;
        CLOSE edit_or_del;
END CASE;

EXCEPTION
    WHEN invalid_ip THEN
    raise_application_error(-20200,'Invalid IP address format');
    WHEN not_unique_ip THEN
    raise_application_error(-20201,'IP address already exists');
   WHEN not_unique_mac THEN
    raise_application_error(-20202,'MAC address already exists');

END saveCOMMUTATOR;


--1.2
create or replace PROCEDURE getCOMMUTATOR
    (
    p_IP_ADDRESS IN INCB_COMMUTATOR.IP_ADDRESS%TYPE,
    /*т.к. уникальность IP и MAC обеспечена в методе saveCOMMUTATOR,
    можно подавать на вход только IP*/
    out_COMMUTATOR OUT INCB_COMMUTATOR%ROWTYPE
    )

IS
    invalid_ip EXCEPTION;
    no_such_ip EXCEPTION;
    com_out INCB_COMMUTATOR%ROWTYPE;

    CURSOR get_commutator IS
        SELECT * FROM INCB_COMMUTATOR
        WHERE 
            p_IP_ADDRESS = IP_ADDRESS;

BEGIN
    IF regexp_instr(p_IP_ADDRESS,'^([01]?\d\d?|2[0-4]\d|25[0-5])\.([01]?\d\d?|2[0-4]\d|25[0-5])\.([01]?\d\d?|
    2[0-4]\d|25[0-5])\.([01]?\d\d?|2[0-4]\d|25[0-5])$') = 0
        THEN RAISE invalid_ip;
    END IF;

    OPEN get_commutator;
        FETCH get_commutator INTO com_out;
            IF get_commutator%NOTFOUND
                THEN RAISE no_such_ip;
            END IF;
    CLOSE get_commutator;

out_COMMUTATOR := com_out;

EXCEPTION
    WHEN invalid_ip THEN
    raise_application_error(-20200,'Invalid IP address format');
    WHEN no_such_ip THEN
    raise_application_error(-20203,'No such IP in DB');


END getCOMMUTATOR;

DECLARE 
out_COMMUTATOR INCB_COMMUTATOR%ROWTYPE;
BEGIN 
GETCOMMUTATOR('192.168.5.0', out_COMMUTATOR);
END;


--2.
create or replace FUNCTION check_access_comm 
    (
    f_IP_ADDRESS IN INCB_COMMUTATOR.IP_ADDRESS%TYPE,
    V_COMMUNITY IN INCB_COMMUTATOR.V_COMMUNITY_READ%TYPE, -- доступ на чтение ИЛИ запись
    B_MODE_WRITE IN NUMBER -- 0 - чтение, 1 - запись
    )
    RETURN NUMBER
IS

invalid_ip EXCEPTION;
no_such_ip EXCEPTION;
ip_ne_ip NUMBER;
acc_ne_acc NUMBER;
CURSOR validate_ip IS
    SELECT 1
        FROM INCB_COMMUTATOR
        WHERE IP_ADDRESS = f_IP_ADDRESS;

CURSOR check_read IS    
    SELECT 1 FROM INCB_COMMUTATOR
        WHERE IP_ADDRESS = f_IP_ADDRESS
        AND V_COMMUNITY_READ = V_COMMUNITY;

CURSOR check_write IS    
    SELECT 1 FROM INCB_COMMUTATOR
        WHERE IP_ADDRESS = f_IP_ADDRESS
        AND V_COMMUNITY_WRITE = V_COMMUNITY;


BEGIN

IF regexp_instr(f_IP_ADDRESS,'^([01]?\d\d?|2[0-4]\d|25[0-5])\.([01]?\d\d?|2[0-4]\d|25[0-5])\.([01]?\d\d?|
2[0-4]\d|25[0-5])\.([01]?\d\d?|2[0-4]\d|25[0-5])$') = 0
    THEN RAISE invalid_ip;
END IF;

OPEN validate_ip;
    FETCH validate_ip INTO ip_ne_ip;
        IF validate_ip%NOTFOUND 
            THEN ip_ne_ip := 0;

--3.
CREATE OR REPLACE FUNCTION get_remote_id
    (
    f_ID_COMMUTATOR IN INCB_COMMUTATOR.ID_COMMUTATOR%TYPE
    )
    RETURN INCB_COMMUTATOR.REMOTE_ID%TYPE
    
IS

no_such_commutator EXCEPTION;

is_hex INCB_COMMUTATOR.B_NEED_CONVERT_HEX%TYPE;
n_remote INCB_COMMUTATOR.REMOTE_ID%TYPE;

CURSOR check_comm IS
    SELECT B_NEED_CONVERT_HEX FROM INCB_COMMUTATOR
        WHERE ID_COMMUTATOR = f_ID_COMMUTATOR;

CURSOR check_remote IS    
    SELECT REMOTE_ID FROM INCB_COMMUTATOR
        WHERE ID_COMMUTATOR = f_ID_COMMUTATOR;

CURSOR check_remote_hex IS    
    SELECT REMOTE_ID_HEX FROM INCB_COMMUTATOR
        WHERE ID_COMMUTATOR = f_ID_COMMUTATOR;
        
BEGIN
    OPEN check_comm;
        FETCH check_comm INTO is_hex;
    CLOSE check_comm;
    
    CASE is_hex 
        WHEN 1 THEN
            OPEN check_remote_hex;
                FETCH check_remote_hex INTO n_remote;
                    IF check_remote_hex%NOTFOUND 
                        THEN RAISE no_such_commutator;
                    END IF;
            CLOSE check_remote_hex;
        WHEN 0 THEN
            OPEN check_remote;
                FETCH check_remote INTO n_remote;
            CLOSE check_remote;
    END CASE;
    

EXCEPTION
    WHEN no_such_commutator 
        THEN raise_application_error(-20204,'No commutator in DB');

RETURN n_remote;

END get_remote_id;
        ELSE
            ip_ne_ip := 1;
        END IF;
CLOSE validate_ip;

IF ip_ne_ip = 0 
    THEN RAISE no_such_ip;
END IF;


CASE B_MODE_WRITE
    WHEN 0 THEN
        OPEN check_read;
            FETCH check_read INTO acc_ne_acc;
                IF check_read%NOTFOUND
                    THEN acc_ne_acc := 0;
                ELSE
                    acc_ne_acc := 1;
                END IF;
        CLOSE check_read;

    WHEN 1 THEN
    OPEN check_write;
            FETCH check_write INTO acc_ne_acc;
                IF check_write%NOTFOUND
                    THEN acc_ne_acc := 0;
                ELSE
                    acc_ne_acc := 1;
                END IF;
        CLOSE check_write;
END CASE;



EXCEPTION
    WHEN no_such_ip THEN 
    raise_application_error(-20203,'No such IP in DB');
    WHEN invalid_ip THEN
    raise_application_error(-20200,'Invalid IP address format');

RETURN acc_ne_acc;

END check_access_comm;

--4.
--Не понимаю в чём дело. При чём ошибки каждый раз разные...
SET SERVEROUTPUT ON;
CREATE OR REPLACE TYPE nested_table IS TABLE OF NUMBER;


CREATE OR REPLACE PROCEDURE check_and_del_data 
    (
    B_FORCE_DELETE IN NUMBER DEFAULT 0,
    wrong_comms OUT nested_table
    )
    
IS

clock NUMBER := 1;
store_cheker INCB_COMMUTATOR%ROWTYPE;
CURSOR CHECKER_VALID_IP666 IS
    SELECT * FROM INCB_COMMUTATOR;

BEGIN
/*    FOR i in 1..5
    LOOP
        wrong_comms.EXTEND;
        wrong_comms(i) := 2*i;
        DBMS_OUTPUT.put_line(to_char(wrong_comms(i)));
    END LOOP;
*/

OPEN CHECKER_VALID_IP666;
    LOOP
        FETCH CHECKER_VALID_IP666 INTO store_cheker;
        EXIT WHEN CHECKER_VALID_IP666%notfound;
        IF regexp_instr(CHECKER_VALID_IP666.IP_ADDRESS,'^([01]?\d\d?|2[0-4]\d|25[0-5])\.([01]?\d\d?|2[0-4]\d|25[0-5])\.([01]?\d\d?|
2[0-4]\d|25[0-5])\.([01]?\d\d?|2[0-4]\d|25[0-5])$') = 0 
            THEN 
                wrong_comms.EXTEND;
                wrong_comms(clock) := CHECKER_VALID_IP666.ID_COMMUTATOR;
                clock := clock + 1;
        END IF;
    END LOOP;
CLOSE CHECKER_VALID_IP666;
    
    
END check_and_del_data;

