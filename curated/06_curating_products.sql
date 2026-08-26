-- Curating Nortwind raw products

CREATE TABLE NORTHWIND_MIGRATION.CURATED.products (
    product_id        VARCHAR(10),
    product_name      VARCHAR(100),
    supplier_id       VARCHAR(10),
    category_id       VARCHAR(10),
    quantity_per_unit VARCHAR(100),
    unit_price        NUMBER(10,2),
    units_in_stock    NUMBER(5,0),
    units_on_order    NUMBER(5,0),
    reorder_level     VARCHAR(20),
    discontinued      VARCHAR(10)
);

INSERT INTO NORTHWIND_MIGRATION.CURATED.products
SELECT
    product_id,
    product_name,
    supplier_id,
    category_id,
    quantity_per_unit,
    TRY_TO_NUMBER(unit_price, 10, 2)     AS unit_price,
    TRY_TO_NUMBER(units_in_stock, 5, 0)  AS units_in_stock,
    TRY_TO_NUMBER(units_on_order, 5, 0)  AS units_on_order,
    reorder_level,
    discontinued
FROM NORTHWIND_MIGRATION.RAW.products;