-- Creating raw tables

--Suppliers
CREATE TABLE NORTHWIND_MIGRATION.RAW.suppliers (
    supplier_id     VARCHAR(10),
    company_name    VARCHAR(100),
    contact_name    VARCHAR(100),
    contact_title   VARCHAR(100),
    address         VARCHAR(200),
    city            VARCHAR(100),
    region          VARCHAR(100),
    postal_code     VARCHAR(20),
    country         VARCHAR(100),
    phone           VARCHAR(50),
    fax             VARCHAR(50),
    homepage        VARCHAR(500)
);
--categories
CREATE TABLE NORTHWIND_MIGRATION.RAW.category (
    category_id     VARCHAR(10),
    category_name   VARCHAR(100),
    description      VARCHAR(1000),
    picture          VARCHAR(1000)
);
--orders
CREATE TABLE NORTHWIND_MIGRATION.RAW.orders (
    order_id          VARCHAR(10),
    customer_id       VARCHAR(10),
    employee_id       VARCHAR(10),
    order_date        VARCHAR(20),
    required_date     VARCHAR(20),
    shipped_date      VARCHAR(20),
    ship_via          VARCHAR(10),
    freight           VARCHAR(20),
    ship_name         VARCHAR(100),
    ship_address      VARCHAR(200),
    ship_city         VARCHAR(100),
    ship_region       VARCHAR(100),
    ship_postal_code  VARCHAR(20),
    ship_country      VARCHAR(100)
);
--products
CREATE TABLE NORTHWIND_MIGRATION.RAW.products (
    product_id        VARCHAR(10),
    product_name      VARCHAR(100),
    supplier_id       VARCHAR(10),
    category_id       VARCHAR(10),
    quantity_per_unit VARCHAR(100),
    unit_price        VARCHAR(20),
    units_in_stock    VARCHAR(20),
    units_on_order    VARCHAR(20),
    reorder_level     VARCHAR(20),
    discontinued      VARCHAR(10)
);
--order_details
CREATE TABLE NORTHWIND_MIGRATION.RAW.order_details (
    order_id     VARCHAR(10),
    product_id   VARCHAR(10),
    unit_price   VARCHAR(20),
    quantity     VARCHAR(20),
    discount     VARCHAR(20)
);
--customers
CREATE TABLE NORTHWIND_MIGRATION.RAW.customers (
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