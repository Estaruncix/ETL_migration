-- order details validation check

-- 1. Row-count baseline
SELECT COUNT(*) AS total_rows
FROM NORTHWIND_MIGRATION.CURATED.order_details;

-- 2. Completeness check across all columns
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) - COUNT(order_id)    AS missing_order_id,
    COUNT(*) - COUNT(product_id)  AS missing_product_id,
    COUNT(*) - COUNT(unit_price)  AS missing_unit_price,
    COUNT(*) - COUNT(quantity)    AS missing_quantity,
    COUNT(*) - COUNT(discount)    AS missing_discount
FROM NORTHWIND_MIGRATION.CURATED.order_details;

-- 3. Duplicate check on the COMPOSITE key (order_id + product_id together)
SELECT
    order_id,
    product_id,
    COUNT(*) AS occurrence_count
FROM NORTHWIND_MIGRATION.CURATED.order_details
GROUP BY order_id, product_id
HAVING COUNT(*) > 1;

-- 4. Referential integrity: orphaned order_id (order_details -> orders)
SELECT
    od.order_id,
    od.product_id
FROM NORTHWIND_MIGRATION.CURATED.order_details od
LEFT JOIN NORTHWIND_MIGRATION.CURATED.orders o
    ON od.order_id = o.order_id
WHERE o.order_id IS NULL;

-- 5. Referential integrity: orphaned product_id (order_details -> products)
-- (this is the one we already wrote together, catching your 1111)
SELECT
    od.order_id,
    od.product_id
FROM NORTHWIND_MIGRATION.CURATED.order_details od
LEFT JOIN NORTHWIND_MIGRATION.CURATED.products p
    ON od.product_id = p.product_id
WHERE p.product_id IS NULL;

-- 6. Business rule: negative quantity
SELECT
    order_id,
    product_id,
    quantity
FROM NORTHWIND_MIGRATION.CURATED.order_details
WHERE quantity < 0;

-- 7. Business rule: negative unit_price or invalid discount 
SELECT
    order_id,
    product_id,
    unit_price,
    discount
FROM NORTHWIND_MIGRATION.CURATED.order_details
WHERE unit_price < 0
   OR discount < 0
   OR discount > 1;

