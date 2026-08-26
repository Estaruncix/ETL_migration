-- Curating Nortwind raw products
CREATE TABLE NORTHWIND_MIGRATION.CURATED.order_details (
    order_id     VARCHAR(10),
    product_id   VARCHAR(10),
    unit_price   NUMBER(10,2),
    quantity     NUMBER(5,0),
    discount     NUMBER(10,2),
    PRIMARY KEY (order_id, product_id)
);

INSERT INTO NORTHWIND_MIGRATION.CURATED.order_details
SELECT
    order_id,
    product_id,
    TRY_TO_NUMBER(unit_price, 10, 2) AS unit_price,
    TRY_TO_NUMBER(quantity, 5, 0)    AS quantity,
    TRY_TO_NUMBER(discount, 10, 2) AS discount
FROM NORTHWIND_MIGRATION.RAW.order_details;