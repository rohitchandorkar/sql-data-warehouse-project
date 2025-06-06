/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    This script performs various quality checks for data consistency, accuracy, 
    and standardization across the 'silver' layer. It includes checks for:
    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.

Usage Notes:
    - Run these checks after data loading Silver Layer.
    - Investigate and resolve any discrepancies found during the checks.
===============================================================================
*/

-- ====================================================================
-- Checking 'silver.crm_cust_info'
-- ====================================================================
-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results

SELECT 
    CST_ID,
    COUNT(*) 
FROM SILVER.CRM_CUST_INFO
GROUP BY CST_ID
HAVING COUNT(*) > 1 OR CST_ID IS NULL;

-- CHECK FOR UNWANTED SPACES
-- EXPECTATION: NO RESULTS
SELECT 
    CST_KEY 
FROM SILVER.CRM_CUST_INFO
WHERE CST_KEY != TRIM(CST_KEY);

-- DATA STANDARDIZATION & CONSISTENCY
SELECT DISTINCT 
    CST_MARITAL_STATUS 
FROM SILVER.CRM_CUST_INFO;

-- ====================================================================
-- CHECKING 'SILVER.CRM_PRD_INFO'
-- ====================================================================
-- CHECK FOR NULLS OR DUPLICATES IN PRIMARY KEY
-- EXPECTATION: NO RESULTS
SELECT 
    PRD_ID,
    COUNT(*) 
FROM SILVER.CRM_PRD_INFO
GROUP BY PRD_ID
HAVING COUNT(*) > 1 OR PRD_ID IS NULL;

-- CHECK FOR UNWANTED SPACES
-- EXPECTATION: NO RESULTS
SELECT 
    PRD_NM 
FROM SILVER.CRM_PRD_INFO
WHERE PRD_NM != TRIM(PRD_NM);

-- CHECK FOR NULLS OR NEGATIVE VALUES IN COST
-- EXPECTATION: NO RESULTS
SELECT 
    PRD_COST 
FROM SILVER.CRM_PRD_INFO
WHERE PRD_COST < 0 OR PRD_COST IS NULL;

-- DATA STANDARDIZATION & CONSISTENCY
SELECT DISTINCT 
    PRD_LINE 
FROM SILVER.CRM_PRD_INFO;

-- CHECK FOR INVALID DATE ORDERS (START DATE > END DATE)
-- EXPECTATION: NO RESULTS
SELECT 
    * 
FROM SILVER.CRM_PRD_INFO
WHERE PRD_END_DT < PRD_START_DT;

-- ====================================================================
-- CHECKING 'SILVER.CRM_SALES_DETAILS'
-- ====================================================================
-- CHECK FOR INVALID DATES
-- EXPECTATION: NO INVALID DATES
SELECT 
    NULLIF(SLS_DUE_DT, 0) AS SLS_DUE_DT 
FROM BRONZE.CRM_SALES_DETAILS
WHERE SLS_DUE_DT <= 0 
    OR LEN(SLS_DUE_DT) != 8 
    OR SLS_DUE_DT > 20500101 
    OR SLS_DUE_DT < 19000101;

-- CHECK FOR INVALID DATE ORDERS (ORDER DATE > SHIPPING/DUE DATES)
-- EXPECTATION: NO RESULTS
SELECT 
    * 
FROM SILVER.CRM_SALES_DETAILS
WHERE SLS_ORDER_DT > SLS_SHIP_DT 
   OR SLS_ORDER_DT > SLS_DUE_DT;

-- CHECK DATA CONSISTENCY: SALES = QUANTITY * PRICE
-- EXPECTATION: NO RESULTS
SELECT DISTINCT 
    SLS_SALES,
    SLS_QUANTITY,
    SLS_PRICE 
FROM SILVER.CRM_SALES_DETAILS
WHERE SLS_SALES != SLS_QUANTITY * SLS_PRICE
   OR SLS_SALES IS NULL 
   OR SLS_QUANTITY IS NULL 
   OR SLS_PRICE IS NULL
   OR SLS_SALES <= 0 
   OR SLS_QUANTITY <= 0 
   OR SLS_PRICE <= 0
ORDER BY SLS_SALES, SLS_QUANTITY, SLS_PRICE;

-- ====================================================================
-- CHECKING 'SILVER.ERP_CUST_AZ12'
-- ====================================================================
-- IDENTIFY OUT-OF-RANGE DATES
-- EXPECTATION: BIRTHDATES BETWEEN 1924-01-01 AND TODAY
SELECT DISTINCT 
    BDATE 
FROM SILVER.ERP_CUST_AZ12
WHERE BDATE < '1924-01-01' 
   OR BDATE > GETDATE();

-- DATA STANDARDIZATION & CONSISTENCY
SELECT DISTINCT 
    GEN 
FROM SILVER.ERP_CUST_AZ12;

-- ====================================================================
-- CHECKING 'SILVER.ERP_LOC_A101'
-- ====================================================================
-- DATA STANDARDIZATION & CONSISTENCY
SELECT DISTINCT 
    CNTRY 
FROM SILVER.ERP_LOC_A101
ORDER BY CNTRY;

-- ====================================================================
-- CHECKING 'SILVER.ERP_PX_CAT_G1V2'
-- ====================================================================
-- CHECK FOR UNWANTED SPACES
-- EXPECTATION: NO RESULTS
SELECT 
    * 
FROM SILVER.ERP_PX_CAT_G1V2
WHERE CAT != TRIM(CAT) 
   OR SUBCAT != TRIM(SUBCAT) 
   OR MAINTENANCE != TRIM(MAINTENANCE);

-- DATA STANDARDIZATION & CONSISTENCY
SELECT DISTINCT 
    MAINTENANCE 
FROM SILVER.ERP_PX_CAT_G1V2;
