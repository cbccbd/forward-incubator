--1.1 ��� ����������

SELECT DISTINCT F_SUM, DT_EVENT 
FROM 
TRANS_EXTERNAL TE, 
FW_CONTRACTS FWC, 
(SELECT MAX(TE.DT_EVENT) MX
FROM FW_CONTRACTS FWC
JOIN TRANS_EXTERNAL TE
ON FWC.ID_CONTRACT_INST = TE.ID_CONTRACT
WHERE V_EXT_IDENT = '0102100000088207_MG1') MAXX
WHERE TE.DT_EVENT = MAXX.MX
AND FWC.V_EXT_IDENT = '0102100000088207_MG1';



--2. ������ ID_PARENT ������, ��� null ��������� ������ � ��� (���� ��� �� ������ �� ����?)
SELECT 
FWC.V_EXT_IDENT AS V_E_ID,
FWC.DT_REG_EVENT AS DT_REG,
DEP.V_NAME AS DEPARTMENT
FROM FW_CONTRACTS FWC
LEFT JOIN FW_DEPARTMENTS DEP
ON FWC.ID_DEPARTMENT = DEP.ID_PARENT
WHERE V_STATUS = 'A'
GROUP BY FWC.V_EXT_IDENT, FWC.DT_REG_EVENT, DEP.V_NAME;

--3.
SELECT V_NAME FROM 
(SELECT DEP.V_NAME, COUNT(*) AS CNT 
FROM FW_DEPARTMENTS DEP
JOIN FW_CONTRACTS FWC
ON DEP.ID_DEPARTMENT = FWC.ID_DEPARTMENT
GROUP BY DEP.V_NAME)
WHERE CNT > 2;

--4.
SELECT 
DEP.V_NAME AS DEPARTAMENT,
SUM(TE.F_SUM) AS TOTAL_SUM, 
COUNT(TE.F_SUM) AS PAYMENTS, 
COUNT(FWC.ID_CONTRACT_INST) AS CONTRACTS
FROM TRANS_EXTERNAL TE
INNER JOIN FW_CONTRACTS FWC
ON TE.ID_CONTRACT = FWC.ID_CONTRACT_INST
JOIN FW_DEPARTMENTS DEP
ON FWC.ID_DEPARTMENT = DEP.ID_DEPARTMENT
WHERE TE.DT_EVENT > TO_DATE('2018-03-01', 'YYYY-MM-DD')
AND TE.DT_EVENT < TO_DATE('2018-04-01', 'YYYY-MM-DD')
GROUP BY 
FWC.ID_CONTRACT_INST, 
TE.F_SUM, 
TE.DT_EVENT, 
DEP.V_NAME;

--5. WHERE ������ HAVING. 
/*�� ���������� ������� ��� �� ��������� 
(��� �� ������ � ���� �� ������ 5-�� �����. 
���� � ����������� �� �������)*/

SELECT * FROM 
(SELECT 
FWC.V_EXT_IDENT CONTRACT, FWC.V_STATUS STAT, 
COUNT(TE.ID_TRANS) TRANS  
FROM FW_CONTRACTS FWC
JOIN TRANS_EXTERNAL TE
ON FWC.ID_CONTRACT_INST = TE.ID_CONTRACT
WHERE 
TE.DT_EVENT BETWEEN TO_DATE('2017-01-01', 'YYYY-MM-DD') AND TO_DATE('2017-12-31', 'YYYY-MM-DD')
GROUP BY FWC.V_EXT_IDENT, FWC.V_STATUS)
WHERE TRANS > 3;

--6. ��� �� ������ ID_PARENT ������, ��� null ��������� ������ � ��� (���� ��� �� ������ �� ����?)
SELECT CONTRACT, STATUS, DEPARTAMENT FROM
(SELECT FWC.V_EXT_IDENT AS CONTRACT, 
COUNT(TE.ID_TRANS) AS TRANS,
FWC.V_STATUS AS STATUS,
DEP.V_NAME AS DEPARTAMENT
FROM FW_CONTRACTS FWC
JOIN TRANS_EXTERNAL TE
ON FWC.ID_CONTRACT_INST = TE.ID_CONTRACT
--LEFT JOIN FW_DEPARTMENTS
--ON FW_CONTRACTS.ID_DEPARTMENT = FW_DEPARTMENTS.ID_DEPARTMENT
LEFT JOIN FW_DEPARTMENTS DEP
ON FWC.ID_DEPARTMENT = DEP.ID_PARENT
WHERE TE.DT_EVENT > TO_DATE('2017-01-01', 'YYYY-MM-DD')
GROUP BY FWC.V_EXT_IDENT, FWC.V_STATUS, DEP.V_NAME);

--7.
SELECT DEP.V_NAME 
FROM FW_DEPARTMENTS DEP
LEFT JOIN FW_CONTRACTS FWC
ON FWC.ID_DEPARTMENT = DEP.ID_DEPARTMENT
WHERE FWC.ID_CONTRACT_INST IS NULL;

--8.
SELECT 
FWC.V_EXT_IDENT AS CONTRACT, 
MAX(TE.DT_EVENT) AS LAST_TRANS, 
TE.ID_MANAGER 
FROM FW_CONTRACTS FWC
JOIN TRANS_EXTERNAL TE
ON FWC.ID_CONTRACT_INST = TE.ID_CONTRACT
GROUP BY FWC.V_EXT_IDENT, TE.ID_MANAGER;

--9.
SELECT FWC.V_EXT_IDENT AS CONTRACT 
FROM TRANS_EXTERNAL TE
JOIN FW_CONTRACTS FWC
ON TE.ID_CONTRACT = FWC.ID_CONTRACT_INST
WHERE TE.ID_TRANS = '6397542'
AND FWC.DT_START < TO_DATE('02-01-2016', 'DD-MM-YYYY');

--10. ����� �� ������������ HAVING ������� �������� � WHERE (���� �� ������� �������)?
SELECT ID_CON, CONTRACT, STATUS, V_NAME
FROM
(SELECT DISTINCT 
FWC.ID_CONTRACT_INST AS ID_CON, 
FWC.V_EXT_IDENT AS CONTRACT,
FWC.V_STATUS AS STATUS,
COUNT(FWC.ID_CURRENCY) AS CNT,
CRR.V_NAME
FROM FW_CONTRACTS FWC
JOIN FW_CURRENCY CRR
ON FWC.ID_CURRENCY = CRR.ID_CURRENCY
GROUP BY FWC.V_EXT_IDENT, FWC.ID_CONTRACT_INST, FWC.V_STATUS, CRR.V_NAME
ORDER BY FWC.V_EXT_IDENT)
WHERE CNT > 1;

--11.1 WHERE
SELECT CONTRACT FROM
(SELECT FWC.V_EXT_IDENT AS CONTRACT,
COUNT(*) AS CNT
FROM FW_CONTRACTS FWC
WHERE FWC.V_STATUS = 'C'
GROUP BY FWC.V_EXT_IDENT)
WHERE CNT > 1;

--11.2 HAVING
SELECT FWC.V_EXT_IDENT AS CONTRACT
FROM FW_CONTRACTS FWC
WHERE FWC.V_STATUS = 'C'
GROUP BY FWC.V_EXT_IDENT
HAVING COUNT(*) > 1;