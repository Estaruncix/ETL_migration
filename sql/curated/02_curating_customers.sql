--Curating Northwind raw Customers

CREATE TABLE NORTHWIND_MIGRATION.CURATED.customers (
    customer_id     VARCHAR(10),
    company_name    VARCHAR(100),
    contact_name    VARCHAR(100),
    contact_title   VARCHAR(100),
    address         VARCHAR(200),
    city            VARCHAR(100),
    region          VARCHAR(100),
    postal_code     VARCHAR(20),
    country         VARCHAR(100),
    phone           VARCHAR(50),
    fax             VARCHAR(50)
);

INSERT INTO NORTHWIND_MIGRATION.CURATED.customers
SELECT * FROM NORTHWIND_MIGRATION.RAW.customers;



