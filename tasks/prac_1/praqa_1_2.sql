--1.
SELECT 
    D.CONTRACT, 
    D.SUMM 
FROM
(SELECT 
    fc.ID_CONTRACT_INST CONTRACT, 
    SUM(fsc.N_COST_PERIOD) SUMM
FROM fw_contracts fc
JOIN FW_SERVICES_COST fsc
    ON fsc.ID_CONTRACT_INST  = fc.ID_CONTRACT_INST
    AND fsc.DT_START <= CURRENT_TIMESTAMP
    AND fsc.DT_STOP > CURRENT_TIMESTAMP
WHERE 
    fc.DT_START <= CURRENT_TIMESTAMP
    AND fc.DT_STOP > CURRENT_TIMESTAMP
GROUP BY fc.id_contract_inst) D
JOIN
(SELECT 
    fc.ID_CONTRACT_INST CONTR, 
    AVG(fsc.N_COST_PERIOD) avgg
FROM 
fw_contracts fc
JOIN FW_SERVICES_COST fsc
    ON fsc.ID_CONTRACT_INST  = fc.ID_CONTRACT_INST
    AND fsc.DT_START <= CURRENT_TIMESTAMP
    AND fsc.DT_STOP > CURRENT_TIMESTAMP
WHERE 
    fc.DT_START <= CURRENT_TIMESTAMP
    AND fc.DT_STOP > CURRENT_TIMESTAMP
GROUP BY fc.id_contract_inst)
    ON CONTR = CONTRACT
    AND SUMM > avgg;

--2.
SELECT 
    ser_dep_sum.SER_NAME, 
    ser_dep_sum.ID_DEPARTMENT, 
    SUM(ser_dep_sum.summ) TOTAL_SUM 
FROM
(SELECT 
    SER.V_NAME SER_NAME, 
    FWC.ID_DEPARTMENT, 
    cds.summ 
FROM
(SELECT
    d.contract,
    d.summ
FROM
    (
        SELECT
            fc.id_contract_inst contract,
            SUM(fsc.n_cost_period) summ
        FROM
            fw_contracts fc
            JOIN fw_services_cost fsc ON fsc.id_contract_inst = fc.id_contract_inst
                                         AND fsc.dt_start <= current_timestamp
                                         AND fsc.dt_stop > current_timestamp
        WHERE
            fc.dt_start <= current_timestamp
            AND fc.dt_stop > current_timestamp
        GROUP BY
            fc.id_contract_inst
    ) d
    JOIN (
        SELECT
            fc.id_contract_inst contr,
            AVG(fsc.n_cost_period) avgg
        FROM
            fw_contracts fc
            JOIN fw_services_cost fsc ON fsc.id_contract_inst = fc.id_contract_inst
                                         AND fsc.dt_start <= current_timestamp
                                         AND fsc.dt_stop > current_timestamp
        WHERE
            fc.dt_start <= current_timestamp
            AND fc.dt_stop > current_timestamp
        GROUP BY
            fc.id_contract_inst
    ) ON contr = contract
         AND summ > avgg) CDS
JOIN FW_CONTRACTS FWC
    ON CDS.contract = FWC.ID_CONTRACT_INST
JOIN FW_SERVICES SERs
    ON CDS.CONTRACT = SERs.ID_CONTRACT_INST
    AND SERs.B_DELETED = 0
JOIN FW_SERVICE SER
    ON SERs.ID_SERVICE = SER.ID_SERVICE
    AND SER.B_DELETED = 0) ser_dep_sum
GROUP BY 
    ser_dep_sum.SER_NAME, 
    ser_dep_sum.ID_DEPARTMENT;

--3.1 contract, salary

SELECT 
    cnt_change.ID_CON, 
    cnt_change.N_COST 
FROM 
(SELECT 
    FWS.ID_CONTRACT_INST ID_CON,
    FWS.ID_SERVICE_INST serv,
    FWS.N_COST_PERIOD N_COST,
    COUNT(FWS.N_DISCOUNT_PERIOD) CNT
FROM FW_SERVICES_COST FWS
WHERE 
    FWS.DT_START >= to_date('01-11-2017', 'DD-MM-YYYY')
    AND FWS.DT_START < to_date('01-12-2017', 'DD-MM-YYYY')
GROUP BY FWS.ID_CONTRACT_INST, FWS.ID_SERVICE_INST, FWS.N_COST_PERIOD) cnt_change
WHERE CNT >= 2;

--3.2 contract, num of changes

SELECT 
    cnt_change.ID_CON, 
    cnt_change.CNT 
FROM 
(SELECT 
    FWS.ID_CONTRACT_INST ID_CON,
    FWS.ID_SERVICE_INST serv,
    FWS.N_COST_PERIOD N_COST,
    COUNT(FWS.N_DISCOUNT_PERIOD) CNT
FROM FW_SERVICES_COST FWS
WHERE 
    FWS.DT_START >= to_date('01-11-2017', 'DD-MM-YYYY')
    AND FWS.DT_START < to_date('01-12-2017', 'DD-MM-YYYY')
GROUP BY FWS.ID_CONTRACT_INST, FWS.ID_SERVICE_INST, FWS.N_COST_PERIOD) cnt_change
WHERE CNT >= 2;

--4(*). -

SELECT 
FWSC.ID_CONTRACT_INST, FWSC.ID_SERVICE_INST, FWSC.N_COST_PERIOD, FWSC.DT_START, FWSC.DT_STOP
FROM FW_SERVICES_COST FWSC
WHERE FWSC.DT_START >= add_months(trunc(current_timestamp,'mm'),-6);

--5.
SELECT 
    sums.ID_DEPARTMENT, 
    SER.V_NAME, 
    sums.dep_sum 
FROM    
(SELECT 
    SERS.ID_CONTRACT_INST, 
    CONS.ID_DEPARTMENT, 
    SERS.ID_SERVICE,
    SUM(F_COST.N_COST_PERIOD) dep_sum
FROM FW_CONTRACTS CONS
JOIN FW_SERVICES SERS
    ON CONS.ID_CONTRACT_INST = SERS.ID_CONTRACT_INST
JOIN FW_SERVICES_COST F_COST
    ON SERS.ID_SERVICE_INST = F_COST.ID_SERVICE_INST
JOIN FW_TARIFF_PLAN T_PLAN
    ON SERS.ID_TARIFF_PLAN = T_PLAN.ID_TARIFF_PLAN
WHERE 
    CONS.DT_STOP >= current_timestamp
    AND T_PLAN.DT_STOP >= current_timestamp
    AND SERS.DT_STOP >= current_timestamp
    AND F_COST.DT_STOP >= current_timestamp
    AND CONS.V_STATUS = 'A'
    AND SERS.V_STATUS = 'A'
    AND T_PLAN.B_ACTIVE = 1
GROUP BY SERS.ID_CONTRACT_INST, CONS.ID_DEPARTMENT, SERS.ID_SERVICE
ORDER BY dep_sum desc) sums
JOIN FW_SERVICE SER
    ON SER.ID_SERVICE = sums.ID_SERVICE
WHERE ROWNUM <6;

--7(*). не вышло. лучшая попытка:
SELECT * FROM
(SELECT 
    gummy_bear.DEP DEPP, 
    MAX(gummy_bear.CNT) MAXX
FROM
(SELECT 
    DEPS.V_NAME DEP,
    SERS.ID_SERVICE SER,
    COUNT(*) CNT
    FROM FW_CONTRACTS CONS
JOIN FW_SERVICES SERS
    ON CONS.ID_CONTRACT_INST = SERS.ID_CONTRACT_INST
JOIN FW_DEPARTMENTS DEPS
    ON CONS.ID_DEPARTMENT = DEPS.ID_DEPARTMENT
GROUP BY DEPS.V_NAME, SERS.ID_SERVICE) gummy_bear
GROUP BY gummy_bear.DEP) fluffy_bear
JOIN 
(SELECT 
    DEPS.V_NAME DEP,
    SERS.ID_SERVICE SER,
    COUNT(*) CNT
    FROM FW_CONTRACTS CONS
JOIN FW_SERVICES SERS
    ON CONS.ID_CONTRACT_INST = SERS.ID_CONTRACT_INST
JOIN FW_DEPARTMENTS DEPS
    ON CONS.ID_DEPARTMENT = DEPS.ID_DEPARTMENT
GROUP BY DEPS.V_NAME, SERS.ID_SERVICE) gum
ON gum.CNT = fluffy_bear.MAXX;

--8. 
SELECT
    sums.id_contract_inst,
    deps.v_name deprtament, 
    COUNT(sums.id_service) services
FROM
    (
        SELECT
            sers.id_contract_inst,
            cons.id_department,
            sers.id_service,
            SUM(s_cost.n_cost_period) dep_sum
        FROM
            fw_contracts cons
            JOIN fw_services sers ON cons.id_contract_inst = sers.id_contract_inst
            JOIN fw_services_cost s_cost ON sers.id_service_inst = s_cost.id_service_inst
            JOIN fw_tariff_plan tff ON sers.id_tariff_plan = tff.id_tariff_plan
        WHERE
            cons.dt_stop >= current_timestamp
            AND tff.dt_stop >= current_timestamp
            AND sers.dt_stop >= current_timestamp
            AND s_cost.dt_stop >= current_timestamp
            AND cons.v_status = 'A'
            AND sers.v_status = 'A'
            AND tff.b_active = 1
        GROUP BY
            sers.id_contract_inst,
            cons.id_department,
            sers.id_service
        ORDER BY
            dep_sum DESC
    ) sums
    JOIN fw_departments deps ON deps.id_department = sums.id_department
WHERE
    sums.dep_sum >= (
        SELECT
            COUNT(dep_sum) * 0.3
        FROM
            (
                SELECT
                    sers.id_contract_inst,
                    cons.id_department,
                    sers.id_service,
                    SUM(fw_services_cost.n_cost_period) dep_sum
                FROM
                    fw_contracts cons
                    JOIN fw_services sers ON cons.id_contract_inst = sers.id_contract_inst
                    JOIN fw_services_cost ON sers.id_service_inst = fw_services_cost.id_service_inst
                    JOIN fw_tariff_plan tff ON sers.id_tariff_plan = tff.id_tariff_plan
                WHERE
                    cons.dt_stop >= current_timestamp
                    AND tff.dt_stop >= current_timestamp
                    AND sers.dt_stop >= current_timestamp
                    AND fw_services_cost.dt_stop >= current_timestamp
                    AND cons.v_status = 'A'
                    AND sers.v_status = 'A'
                    AND tff.b_active = 1
                GROUP BY
                    sers.id_contract_inst,
                    cons.id_department,
                    sers.id_service
                ORDER BY
                    dep_sum DESC
            )
    )
GROUP BY
    sums.id_contract_inst,
    deps.v_name;

--9. SELECT 
    BUM.ID_CON,
    BUM.V_NAME,
    COUNT(CASE SER_1.B_ADD_SERVICE WHEN 1 THEN 'Дополнительная услуга' ELSE NULL END) SER_GEN,
    COUNT(CASE SER_1.B_ADD_SERVICE WHEN 0 THEN 'Основная услуга' ELSE NULL END) SER_ADD

FROM
(SELECT 
    all_sum.id_contract_inst ID_CON, 
    DEPS.V_NAME, 
    all_sum.id_service 
from
(SELECT
    cons.id_contract_inst,
    cons.ID_DEPARTMENT,
    sers.id_service,
    sum(s_cost.n_cost_period) summ
FROM
    fw_contracts cons
    JOIN fw_services sers 
        ON sers.id_contract_inst = cons.id_contract_inst
        AND cons.V_STATUS = 'A'
        AND sers.V_STATUS = 'A'
    JOIN fw_service ser 
        ON sers.id_service = ser.id_service
        AND ser.b_add_service = 1
    JOIN fw_services_cost s_cost 
        ON s_cost.id_service_inst = sers.id_service_inst 
        and s_cost.DT_STOP >= current_timestamp
    
group by cons.id_contract_inst,
         cons.ID_DEPARTMENT,
         sers.id_service
order by sum(s_cost.n_cost_period) desc) all_sum
join FW_DEPARTMENTS DEPS on DEPS.ID_DEPARTMENT = all_sum.ID_DEPARTMENT
where rownum  <= 
(select count(all_sum.summ)*0.45 from (SELECT
    cons.id_contract_inst,
    cons.ID_DEPARTMENT,
    sum(s_cost.n_cost_period) summ
FROM
    fw_contracts cons
    JOIN fw_services sers ON sers.id_contract_inst = cons.id_contract_inst
    and cons.V_STATUS = 'A'
    and sers.V_STATUS = 'A'
    JOIN fw_service ser ON sers.id_service = ser.id_service
                           AND ser.b_add_service = 1
    JOIN fw_services_cost s_cost ON s_cost.id_service_inst = sers.id_service_inst 
    and s_cost.DT_STOP >= current_timestamp
    
group by cons.id_contract_inst,
         cons.ID_DEPARTMENT
order by sum(s_cost.n_cost_period) desc) all_sum)) BUM
JOIN FW_SERVICES SERS
    ON SERS.ID_CONTRACT_INST = BUM.ID_CON
JOIN FW_SERVICE SER_1 
    ON SERS.ID_SERVICE = SER_1.ID_SERVICE
GROUP BY BUM.ID_CON, BUM.V_NAME;

--11.
SELECT 
    TRF.ID_TARIFF_PLAN,
    --TRF.ID_DEPARTMENT, --FW_TARIFF_PLAN.ID_DEPARTMENT все значения null
    SUM(S_COST.N_COST_PERIOD) SUMS
FROM FW_TARIFF_PLAN TRF
JOIN FW_SERVICES SERS
    ON TRF.ID_TARIFF_PLAN = SERS.ID_TARIFF_PLAN
JOIN FW_SERVICE SER
    ON SERS.ID_SERVICE = SER.ID_SERVICE
JOIN FW_SERVICES_COST S_COST
    ON SERS.ID_SERVICE_INST = S_COST.ID_SERVICE_INST
WHERE SER.B_ADD_SERVICE = 1
GROUP BY TRF.ID_TARIFF_PLAN
    --, TRF.ID_DEPARTMENT --FW_TARIFF_PLAN.ID_DEPARTMENT все значения null
ORDER BY SUMS DESC;

--12.
SELECT 
    CONT.ID_CONTRACT_INST, 
    min(S_COST.N_COST_PERIOD), max(S_COST.N_COST_PERIOD), 
    DEPS.V_NAME
 
FROM FW_CONTRACTS CONT
JOIN FW_SERVICES_COST S_COST
    ON CONT.ID_CONTRACT_INST = S_COST.ID_CONTRACT_INST
    AND S_COST.DT_STOP > current_timestamp
    AND S_COST.DT_STOP > current_timestamp
JOIN FW_DEPARTMENTS DEPS
    ON CONT.ID_DEPARTMENT = DEPS.ID_DEPARTMENT
GROUP BY CONT.ID_CONTRACT_INST, DEPS.V_NAME;

--13.
SELECT 
    sums.N_DEPS,
    CASE WHEN sums.ID_DEP = 2022 THEN MIN(sums.SUMS) ELSE MAX(sums.SUMS) END
FROM
(SELECT 
    TRF.ID_TARIFF_PLAN ID_T,
    TRF.V_NAME N_T,
    --DEPS.V_NAME N_DEPS,
    --TRF.ID_DEPARTMENT ID_DEP, --FW_TARIFF_PLAN.ID_DEPARTMENT все значения null
    SUM(S_COST.N_COST_PERIOD) SUMS
FROM FW_TARIFF_PLAN TRF
/*JOIN FW_DEPARTMENTS DEPS
    ON TRF.ID_DEPARTMENT = DEPS.ID_DEPARTMENT*/ --FW_TARIFF_PLAN.ID_DEPARTMENT все значения null
JOIN FW_SERVICES SERS
    ON TRF.ID_TARIFF_PLAN = SERS.ID_TARIFF_PLAN
JOIN FW_SERVICE SER
    ON SERS.ID_SERVICE = SER.ID_SERVICE
JOIN FW_SERVICES_COST S_COST
    ON SERS.ID_SERVICE_INST = S_COST.ID_SERVICE_INST

GROUP BY TRF.ID_TARIFF_PLAN, TRF.V_NAME
--, DEPS.V_NAME, TRF.ID_DEPARTMENT --FW_TARIFF_PLAN.ID_DEPARTMENT все значения null
    ) sums
GROUP BY sums.N_DEPS;

