--1.
create or replace PROCEDURE savesigners
( pV_FIO IN SCD_SIGNERS.V_FIO%TYPE , pID_MANAGER in ci_users.id_user%TYPE, pACTION IN NUMBER ) 
is 
begin 
    for i in (select ci_users.id_user from ci_users) 
    loop
        if i.id_user = pID_MANAGER then
            if pACTION = 1 then
                DECLARE
                    temp_var ci_users.id_user%TYPE;
                    BEGIN
                    SELECT ID_MANAGER into temp_var from scd_signers;
                        if temp_var != pID_MANAGER THEN
                            INSERT INTO SCD_SIGNERS ("V_FIO", "ID_MANAGER") VALUES (pV_FIO, pID_MANAGER);
                        END IF;
                    END;
                    elsif pACTION = 2 then 
                     UPDATE SCD_SIGNERS SET V_FIO = pV_FIO WHERE ID_MANAGER = pID_MANAGER;
                    
                   elsif pACTION = 3 then
                   DELETE FROM SCD_SIGNERS WHERE ID_MANAGER = pID_MANAGER;                       
            end if;  
        end if;
    end loop; 
EXCEPTION
    WHEN no_data_found THEN 
    raise_application_error (-20020,'Пользователь не найден');
end savesigners;

--2.
CREATE OR REPLACE FUNCTION getDecoder
(val in varchar2)
return varchar2 

IS
sel_val varchar2(777) := 0;
sel_val2 varchar2(777) := 0;

CURSOR c1 IS
SELECT SKIT.id_equip_kits_inst 
FROM scd_equip_kits SKIT
JOIN SCD_CONTRACTS SCON
ON SKIT.ID_CONTRACT_INST = SCON.ID_CONTRACT_INST
WHERE SKIT.id_equip_kits_inst = val 
    AND SKIT.ID_CONTRACT_INST IS NOT NULL
    AND SCON.B_AGENCY = 1
    AND ROWNUM <2; 
    
CURSOR c2 IS
SELECT SKIT.v_ext_ident 
FROM scd_equip_kits SKIT
JOIN SCD_CONTRACTS SCON
ON SKIT.ID_CONTRACT_INST = SCON.ID_CONTRACT_INST
WHERE SKIT.id_equip_kits_inst = val 
    AND SKIT.ID_CONTRACT_INST IS NOT NULL
    AND SCON.B_AGENCY = 1
    AND ROWNUM <2;

BEGIN
open c1;
open c2;
fetch c1 into sel_val;
fetch c2 into sel_val2;

if sel_val = 0 AND sel_val2 = 0 THEN
    return 'Оборудование не найдено';
elsif sel_val != 0 THEN
    return sel_val;
elsif sel_val2 != 0 THEN
    return sel_val;
END IF;

end getDecoder;

--3. не понял что значит "все данные"
CREATE OR REPLACE PROCEDURE getEquip (pID_EQUIP_KITS_INST IN varchar2 default null, 
                                                            p_emp_refcur IN OUT SYS_REFCURSOR)
IS


BEGIN
    OPEN p_emp_refcur FOR 
    SELECT 
    FWC.V_LONG_TITLE, CU.V_USERNAME, CONT.ID_CONTRACT_INST, E_TYPE.V_NAME,
    CASE pID_EQUIP_KITS_INST WHEN NULL THEN getDecoder(SKIT.ID_EQUIP_KITS_INST) ELSE NULL END 
    FROM scd_equip_kits SKIT
    JOIN SCD_EQUIPMENT_KITS_TYPE E_TYPE
        ON SKIT.ID_EQUIP_KITS_TYPE = E_TYPE.ID_EQUIP_KITS_TYPE
    JOIN FW_CONTRACTS CONT 
        ON SKIT.ID_CONTRACT_INST = CONT.ID_CONTRACT_INST
    JOIN CI_USERS CU 
        ON CONT.ID_CLIENT_INST = CU.ID_CLIENT_INST
    JOIN FW_CLIENTS FWC
        ON CU.ID_CLIENT_INST = FWC.ID_CLIENT_INST
    WHERE
        CONT.DT_STOP >= current_timestamp;

END getEquip;


--4.
CREATE OR REPLACE PROCEDURE checkstatus IS

CURSOR CUR_STATUS IS
SELECT 
    SKIT.ID_EQUIP_KITS_INST ID_KIT,
    E_STAT.ID_EQUIPMENT_STATUS ID_STATUS,
    E_STAT.V_NAME NAME_STATUS,
    FC.V_LONG_TITLE DILER, 
    CONT.V_EXT_IDENT CONTRACT, 
    S_CONT.B_AGENCY AGENCY  
FROM scd_equip_kits SKIT
JOIN SCD_EQUIPMENT_STATUS E_STAT 
    ON E_STAT.ID_EQUIPMENT_STATUS = SKIT.ID_STATUS
JOIN FW_CONTRACTS CONT
    ON SKIT.ID_CONTRACT_INST = CONT.ID_CONTRACT_INST
JOIN SCD_CONTRACTS S_CONT
    ON CONT.ID_CONTRACT_INST = S_CONT.ID_CONTRACT_INST
JOIN FW_CLIENTS FC
    ON CONT.ID_CLIENT_INST = FC.ID_CLIENT_INST
WHERE SKIT.ID_DEALER_CLIENT IS NOT NULL
    AND E_STAT.V_NAME != 'Продано'
FOR UPDATE;

c_ID_KIT scd_equip_kits.ID_EQUIP_KITS_INST%TYPE;
c_ID_STATUS SCD_EQUIPMENT_STATUS.ID_EQUIPMENT_STATUS%TYPE;
c_NAME_STATUS SCD_EQUIPMENT_STATUS.V_NAME%TYPE;
c_DILER FW_CLIENTS.V_LONG_TITLE%TYPE; 
c_CONTRACT FW_CONTRACTS.V_EXT_IDENT%TYPE; 
c_AGENCY SCD_CONTRACTS.B_AGENCY%TYPE;  

BEGIN
    OPEN CUR_STATUS;
        LOOP
            FETCH CUR_STATUS INTO c_ID_KIT, c_ID_STATUS, c_NAME_STATUS, c_DILER, c_CONTRACT, c_AGENCY;
            EXIT WHEN CUR_STATUS%NOTFOUND;
            UPDATE SCD_EQUIPMENT_STATUS SET V_NAME = 'Продано' WHERE CURRENT OF CUR_STATUS;
            dbms_output.put_line('Для оборудования ' || c_ID_KIT || ' дилера ' || c_DILER || ' с контрактом ' || c_CONTRACT ||  
            CASE c_AGENCY WHEN 1 THEN ', являющегося ' ELSE  ', не являющегося ' END ||
            'агентской сетью был проставлен статус Продано.');
        END LOOP;
    CLOSE CUR_STATUS;

END checkstatus;





