/*
===============================================================================
DDL Script: Create Silver Tables
===============================================================================
Script Purpose:
    This script creates tables in the 'silver' schema, dropping existing tables 
    if they already exist.
	  Run this script to re-define the DDL structure of 'bronze' Tables
===============================================================================
*/

IF OBJECT_ID('SILVER.CRM_CUST_INFO', 'U') IS NOT NULL
    DROP TABLE SILVER.CRM_CUST_INFO;
GO

CREATE TABLE SILVER.CRM_CUST_INFO (
    CST_ID             INT,
    CST_KEY            NVARCHAR(50),
    CST_FIRSTNAME      NVARCHAR(50),
    CST_LASTNAME       NVARCHAR(50),
    CST_MARITAL_STATUS NVARCHAR(50),
    CST_GNDR           NVARCHAR(50),
    CST_CREATE_DATE    DATE,
    DWH_CREATE_DATE    DATETIME2 DEFAULT GETDATE()
);
GO

IF OBJECT_ID('SILVER.CRM_PRD_INFO', 'U') IS NOT NULL
    DROP TABLE SILVER.CRM_PRD_INFO;
GO

CREATE TABLE SILVER.CRM_PRD_INFO (
    PRD_ID          INT,
    CAT_ID          NVARCHAR(50),
    PRD_KEY         NVARCHAR(50),
    PRD_NM          NVARCHAR(50),
    PRD_COST        INT,
    PRD_LINE        NVARCHAR(50),
    PRD_START_DT    DATE,
    PRD_END_DT      DATE,
    DWH_CREATE_DATE DATETIME2 DEFAULT GETDATE()
);
GO

IF OBJECT_ID('SILVER.CRM_SALES_DETAILS', 'U') IS NOT NULL
    DROP TABLE SILVER.CRM_SALES_DETAILS;
GO

CREATE TABLE SILVER.CRM_SALES_DETAILS (
    SLS_ORD_NUM     NVARCHAR(50),
    SLS_PRD_KEY     NVARCHAR(50),
    SLS_CUST_ID     INT,
    SLS_ORDER_DT    DATE,
    SLS_SHIP_DT     DATE,
    SLS_DUE_DT      DATE,
    SLS_SALES       INT,
    SLS_QUANTITY    INT,
    SLS_PRICE       INT,
    DWH_CREATE_DATE DATETIME2 DEFAULT GETDATE()
);
GO

IF OBJECT_ID('SILVER.ERP_LOC_A101', 'U') IS NOT NULL
    DROP TABLE SILVER.ERP_LOC_A101;
GO

CREATE TABLE SILVER.ERP_LOC_A101 (
    CID             NVARCHAR(50),
    CNTRY           NVARCHAR(50),
    DWH_CREATE_DATE DATETIME2 DEFAULT GETDATE()
);
GO

IF OBJECT_ID('SILVER.ERP_CUST_AZ12', 'U') IS NOT NULL
    DROP TABLE SILVER.ERP_CUST_AZ12;
GO

CREATE TABLE SILVER.ERP_CUST_AZ12 (
    CID             NVARCHAR(50),
    BDATE           DATE,
    GEN             NVARCHAR(50),
    DWH_CREATE_DATE DATETIME2 DEFAULT GETDATE()
);
GO

IF OBJECT_ID('SILVER.ERP_PX_CAT_G1V2', 'U') IS NOT NULL
    DROP TABLE SILVER.ERP_PX_CAT_G1V2;
GO

CREATE TABLE SILVER.ERP_PX_CAT_G1V2 (
    ID              NVARCHAR(50),
    CAT             NVARCHAR(50),
    SUBCAT          NVARCHAR(50),
    MAINTENANCE     NVARCHAR(50),
    DWH_CREATE_DATE DATETIME2 DEFAULT GETDATE()
);
GO
