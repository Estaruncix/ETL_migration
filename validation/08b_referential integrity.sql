-- referential integrity

SELECT
    od.order_id,
    od.product_id
FROM NORTHWIND_MIGRATION.CURATED.order_details od
LEFT JOIN NORTHWIND_MIGRATION.CURATED.products p
    ON od.product_id = p.product_id
WHERE p.product_id IS NULL;

SELECT
    o.order_id,
    o.customer_id
FROM NORTHWIND_MIGRATION.CURATED.orders o
LEFT JOIN NORTHWIND_MIGRATION.CURATED.customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;