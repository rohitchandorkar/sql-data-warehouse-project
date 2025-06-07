/*
===============================================================================
QUALITY CHECKS
===============================================================================
Script Purpose:
    This script performs quality checks to validate the integrity, consistency, 
    and accuracy of the Gold Layer. These checks ensure:
    - Uniqueness of surrogate keys in dimension tables.
    - Referential integrity between fact and dimension tables.
    - Validation of relationships in the data model for analytical purposes.

USAGE NOTES:
    - Investigate and resolve any discrepancies found during the checks.
===============================================================================
*/
-- ====================================================================
-- CHECKING 'GOLD.DIM_CUSTOMERS'
-- ====================================================================
-- CHECK FOR UNIQUENESS OF CUSTOMER_KEY IN GOLD.DIM_CUSTOMERS
-- EXPECTATION: NO RESULTS 
SELECT 
    CUSTOMER_KEY,
    COUNT(*) AS DUPLICATE_COUNT
FROM GOLD.DIM_CUSTOMERS
GROUP BY CUSTOMER_KEY
HAVING COUNT(*) > 1;

-- ====================================================================
-- CHECKING 'GOLD.DIM_PRODUCTS'
-- ====================================================================
-- CHECK FOR UNIQUENESS OF PRODUCT_KEY IN GOLD.DIM_PRODUCTS
-- EXPECTATION: NO RESULTS 
SELECT 
    PRODUCT_KEY,
    COUNT(*) AS DUPLICATE_COUNT
FROM GOLD.DIM_PRODUCTS
GROUP BY PRODUCT_KEY
HAVING COUNT(*) > 1;

-- ====================================================================
-- CHECKING 'GOLD.FACT_SALES'
-- ====================================================================
-- CHECK THE DATA MODEL CONNECTIVITY BETWEEN FACT AND DIMENSIONS
SELECT * 
FROM GOLD.FACT_SALES F
LEFT JOIN GOLD.DIM_CUSTOMERS C
    ON C.CUSTOMER_KEY = F.CUSTOMER_KEY
LEFT JOIN GOLD.DIM_PRODUCTS P
    ON P.PRODUCT_KEY = F.PRODUCT_KEY
WHERE P.PRODUCT_KEY IS NULL 
   OR C.CUSTOMER_KEY IS NULL;
