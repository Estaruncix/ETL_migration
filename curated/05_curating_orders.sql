-- Curating Northwind raw orders
CREATE TABLE NORTHWIND_MIGRATION.CURATED.orders (
    order_id          VARCHAR(10),
    customer_id       VARCHAR(10),
    employee_id       VARCHAR(10),
    order_date        DATE,
    required_date     DATE,
    shipped_date      DATE,
    ship_via          VARCHAR(10),
    freight           NUMBER(10,2),
    ship_name         VARCHAR(100),
    ship_address      VARCHAR(200),
    ship_city         VARCHAR(100),
    ship_region       VARCHAR(100),
    ship_postal_code  VARCHAR(20),
    ship_country      VARCHAR(100)
);

INSERT INTO NORTHWIND_MIGRATION.CURATED.orders
SELECT
    order_id,
    customer_id,
    employee_id,
    TRY_TO_DATE(order_date, 'DD/MM/YYYY')      AS order_date,
    TRY_TO_DATE(required_date, 'DD/MM/YYYY')   AS required_date,
    TRY_TO_DATE(shipped_date, 'DD/MM/YYYY')    AS shipped_date,
    ship_via,
    TRY_TO_NUMBER(freight, 10, 2) AS freight,
    ship_name,
    ship_address,
    ship_city,
    ship_region,
    ship_postal_code,
    ship_country
FROM NORTHWIND_MIGRATION.RAW.orders;