/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'SILVER' schema tables from the 'BRONZE' schema.
	Actions Performed:
		- Truncates Silver tables.
		- Inserts transformed and cleansed data from Bronze into Silver tables.
		
Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC SILVER.LOAD_SILVER;
===============================================================================
*/
CREATE OR ALTER PROCEDURE SILVER.LOAD_SILVER AS
BEGIN
    DECLARE @START_TIME DATETIME, @END_TIME DATETIME, @BATCH_START_TIME DATETIME, @BATCH_END_TIME DATETIME; 
    BEGIN TRY
        SET @BATCH_START_TIME = GETDATE();
        PRINT '================================================';
        PRINT 'LOADING SILVER LAYER';
        PRINT '================================================';

        PRINT '------------------------------------------------';
        PRINT 'LOADING CRM TABLES';
        PRINT '------------------------------------------------';

        -- LOADING SILVER.CRM_CUST_INFO
        SET @START_TIME = GETDATE();
        PRINT '>> TRUNCATING TABLE: SILVER.CRM_CUST_INFO';
        TRUNCATE TABLE SILVER.CRM_CUST_INFO;
        PRINT '>> INSERTING DATA INTO: SILVER.CRM_CUST_INFO';
        INSERT INTO SILVER.CRM_CUST_INFO (
            CST_ID, 
            CST_KEY, 
            CST_FIRSTNAME, 
            CST_LASTNAME, 
            CST_MARITAL_STATUS, 
            CST_GNDR,
            CST_CREATE_DATE
        )
        SELECT
            CST_ID,
            CST_KEY,
            TRIM(CST_FIRSTNAME) AS CST_FIRSTNAME,
            TRIM(CST_LASTNAME) AS CST_LASTNAME,
            CASE 
                WHEN UPPER(TRIM(CST_MARITAL_STATUS)) = 'S' THEN 'SINGLE'
                WHEN UPPER(TRIM(CST_MARITAL_STATUS)) = 'M' THEN 'MARRIED'
                ELSE 'N/A'
            END AS CST_MARITAL_STATUS,
            CASE 
                WHEN UPPER(TRIM(CST_GNDR)) = 'F' THEN 'FEMALE'
                WHEN UPPER(TRIM(CST_GNDR)) = 'M' THEN 'MALE'
                ELSE 'N/A'
            END AS CST_GNDR,
            CST_CREATE_DATE
        FROM (
            SELECT
                *,
                ROW_NUMBER() OVER (PARTITION BY CST_ID ORDER BY CST_CREATE_DATE DESC) AS FLAG_LAST
            FROM BRONZE.CRM_CUST_INFO
            WHERE CST_ID IS NOT NULL
        ) T
        WHERE FLAG_LAST = 1;
        SET @END_TIME = GETDATE();
        PRINT '>> LOAD DURATION: ' + CAST(DATEDIFF(SECOND, @START_TIME, @END_TIME) AS NVARCHAR) + ' SECONDS';
        PRINT '>> -------------';

        -- LOADING SILVER.CRM_PRD_INFO
        SET @START_TIME = GETDATE();
        PRINT '>> TRUNCATING TABLE: SILVER.CRM_PRD_INFO';
        TRUNCATE TABLE SILVER.CRM_PRD_INFO;
        PRINT '>> INSERTING DATA INTO: SILVER.CRM_PRD_INFO';
        INSERT INTO SILVER.CRM_PRD_INFO (
            PRD_ID,
            CAT_ID,
            PRD_KEY,
            PRD_NM,
            PRD_COST,
            PRD_LINE,
            PRD_START_DT,
            PRD_END_DT
        )
        SELECT
            PRD_ID,
            REPLACE(SUBSTRING(PRD_KEY, 1, 5), '-', '_') AS CAT_ID,
            SUBSTRING(PRD_KEY, 7, LEN(PRD_KEY)) AS PRD_KEY,
            PRD_NM,
            ISNULL(PRD_COST, 0) AS PRD_COST,
            CASE 
                WHEN UPPER(TRIM(PRD_LINE)) = 'M' THEN 'MOUNTAIN'
                WHEN UPPER(TRIM(PRD_LINE)) = 'R' THEN 'ROAD'
                WHEN UPPER(TRIM(PRD_LINE)) = 'S' THEN 'OTHER SALES'
                WHEN UPPER(TRIM(PRD_LINE)) = 'T' THEN 'TOURING'
                ELSE 'N/A'
            END AS PRD_LINE,
            CAST(PRD_START_DT AS DATE) AS PRD_START_DT,
            CAST(
                LEAD(PRD_START_DT) OVER (PARTITION BY PRD_KEY ORDER BY PRD_START_DT) - 1 
                AS DATE
            ) AS PRD_END_DT
        FROM BRONZE.CRM_PRD_INFO;
        SET @END_TIME = GETDATE();
        PRINT '>> LOAD DURATION: ' + CAST(DATEDIFF(SECOND, @START_TIME, @END_TIME) AS NVARCHAR) + ' SECONDS';
        PRINT '>> -------------';

        -- LOADING CRM_SALES_DETAILS
        SET @START_TIME = GETDATE();
        PRINT '>> TRUNCATING TABLE: SILVER.CRM_SALES_DETAILS';
        TRUNCATE TABLE SILVER.CRM_SALES_DETAILS;
        PRINT '>> INSERTING DATA INTO: SILVER.CRM_SALES_DETAILS';
        INSERT INTO SILVER.CRM_SALES_DETAILS (
            SLS_ORD_NUM,
            SLS_PRD_KEY,
            SLS_CUST_ID,
            SLS_ORDER_DT,
            SLS_SHIP_DT,
            SLS_DUE_DT,
            SLS_SALES,
            SLS_QUANTITY,
            SLS_PRICE
        )
        SELECT 
            SLS_ORD_NUM,
            SLS_PRD_KEY,
            SLS_CUST_ID,
            CASE 
                WHEN SLS_ORDER_DT = 0 OR LEN(SLS_ORDER_DT) != 8 THEN NULL
                ELSE CAST(CAST(SLS_ORDER_DT AS VARCHAR) AS DATE)
            END AS SLS_ORDER_DT,
            CASE 
                WHEN SLS_SHIP_DT = 0 OR LEN(SLS_SHIP_DT) != 8 THEN NULL
                ELSE CAST(CAST(SLS_SHIP_DT AS VARCHAR) AS DATE)
            END AS SLS_SHIP_DT,
            CASE 
                WHEN SLS_DUE_DT = 0 OR LEN(SLS_DUE_DT) != 8 THEN NULL
                ELSE CAST(CAST(SLS_DUE_DT AS VARCHAR) AS DATE)
            END AS SLS_DUE_DT,
            CASE 
                WHEN SLS_SALES IS NULL OR SLS_SALES <= 0 OR SLS_SALES != SLS_QUANTITY * ABS(SLS_PRICE) 
                    THEN SLS_QUANTITY * ABS(SLS_PRICE)
                ELSE SLS_SALES
            END AS SLS_SALES,
            SLS_QUANTITY,
            CASE 
                WHEN SLS_PRICE IS NULL OR SLS_PRICE <= 0 
                    THEN SLS_SALES / NULLIF(SLS_QUANTITY, 0)
                ELSE SLS_PRICE
            END AS SLS_PRICE
        FROM BRONZE.CRM_SALES_DETAILS;
        SET @END_TIME = GETDATE();
        PRINT '>> LOAD DURATION: ' + CAST(DATEDIFF(SECOND, @START_TIME, @END_TIME) AS NVARCHAR) + ' SECONDS';
        PRINT '>> -------------';

        -- LOADING ERP_CUST_AZ12
        SET @START_TIME = GETDATE();
        PRINT '>> TRUNCATING TABLE: SILVER.ERP_CUST_AZ12';
        TRUNCATE TABLE SILVER.ERP_CUST_AZ12;
        PRINT '>> INSERTING DATA INTO: SILVER.ERP_CUST_AZ12';
        INSERT INTO SILVER.ERP_CUST_AZ12 (
            CID,
            BDATE,
            GEN
        )
        SELECT
            CASE
                WHEN CID LIKE 'NAS%' THEN SUBSTRING(CID, 4, LEN(CID))
                ELSE CID
            END AS CID, 
            CASE
                WHEN BDATE > GETDATE() THEN NULL
                ELSE BDATE
            END AS BDATE,
            CASE
                WHEN UPPER(TRIM(GEN)) IN ('F', 'FEMALE') THEN 'FEMALE'
                WHEN UPPER(TRIM(GEN)) IN ('M', 'MALE') THEN 'MALE'
                ELSE 'N/A'
            END AS GEN
        FROM BRONZE.ERP_CUST_AZ12;
        SET @END_TIME = GETDATE();
        PRINT '>> LOAD DURATION: ' + CAST(DATEDIFF(SECOND, @START_TIME, @END_TIME) AS NVARCHAR) + ' SECONDS';
        PRINT '>> -------------';

        PRINT '------------------------------------------------';
        PRINT 'LOADING ERP TABLES';
        PRINT '------------------------------------------------';

        -- LOADING ERP_LOC_A101
        SET @START_TIME = GETDATE();
        PRINT '>> TRUNCATING TABLE: SILVER.ERP_LOC_A101';
        TRUNCATE TABLE SILVER.ERP_LOC_A101;
        PRINT '>> INSERTING DATA INTO: SILVER.ERP_LOC_A101';
        INSERT INTO SILVER.ERP_LOC_A101 (
            CID,
            CNTRY
        )
        SELECT
            REPLACE(CID, '-', '') AS CID, 
            CASE
                WHEN TRIM(CNTRY) = 'DE' THEN 'GERMANY'
                WHEN TRIM(CNTRY) IN ('US', 'USA') THEN 'UNITED STATES'
                WHEN TRIM(CNTRY) = '' OR CNTRY IS NULL THEN 'N/A'
				WHEN UPPER(TRIM(CNTRY)) = 'Australia' THEN 'AUSTRALIA'
				WHEN UPPER(TRIM(CNTRY)) = 'Canada' THEN 'CANADA'
				WHEN UPPER(TRIM(CNTRY)) = 'france' THEN 'FRANCE'
				WHEN UPPER(TRIM(CNTRY)) = 'united Kingdom' THEN 'UNITED KINGDOM'
                ELSE TRIM(CNTRY)
            END AS CNTRY
        FROM BRONZE.ERP_LOC_A101;
        SET @END_TIME = GETDATE();
        PRINT '>> LOAD DURATION: ' + CAST(DATEDIFF(SECOND, @START_TIME, @END_TIME) AS NVARCHAR) + ' SECONDS';
        PRINT '>> -------------';
        
        -- LOADING ERP_PX_CAT_G1V2
        SET @START_TIME = GETDATE();
        PRINT '>> TRUNCATING TABLE: SILVER.ERP_PX_CAT_G1V2';
        TRUNCATE TABLE SILVER.ERP_PX_CAT_G1V2;
        PRINT '>> INSERTING DATA INTO: SILVER.ERP_PX_CAT_G1V2';
        INSERT INTO SILVER.ERP_PX_CAT_G1V2 (
            ID,
            CAT,
            SUBCAT,
            MAINTENANCE
        )
        SELECT
            ID,
            CAT,
            SUBCAT,
            MAINTENANCE
        FROM BRONZE.ERP_PX_CAT_G1V2;
        SET @END_TIME = GETDATE();
        PRINT '>> LOAD DURATION: ' + CAST(DATEDIFF(SECOND, @START_TIME, @END_TIME) AS NVARCHAR) + ' SECONDS';
        PRINT '>> -------------';

        SET @BATCH_END_TIME = GETDATE();
        PRINT '==========================================';
        PRINT 'LOADING SILVER LAYER IS COMPLETED';
        PRINT '   - TOTAL LOAD DURATION: ' + CAST(DATEDIFF(SECOND, @BATCH_START_TIME, @BATCH_END_TIME) AS NVARCHAR) + ' SECONDS';
        PRINT '==========================================';
        
    END TRY
    BEGIN CATCH
        PRINT '==========================================';
        PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER';
        PRINT 'ERROR MESSAGE' + ERROR_MESSAGE();
        PRINT 'ERROR NUMBER' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'ERROR STATE' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '==========================================';
    END CATCH
END;
