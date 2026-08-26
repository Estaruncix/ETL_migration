-- 09 Orders data quality check 

-- 1. Row-count baseline
SELECT COUNT(*) AS total_rows
FROM NORTHWIND_MIGRATION.CURATED.orders;

-- 2. Completeness check across all columns
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) - COUNT(order_id)          AS missing_order_id,
    COUNT(*) - COUNT(customer_id)       AS missing_customer_id,
    COUNT(*) - COUNT(employee_id)       AS missing_employee_id,
    COUNT(*) - COUNT(order_date)        AS missing_order_date,
    COUNT(*) - COUNT(required_date)     AS missing_required_date,
    COUNT(*) - COUNT(shipped_date)      AS missing_shipped_date,
    COUNT(*) - COUNT(freight)           AS missing_freight
FROM NORTHWIND_MIGRATION.CURATED.orders;

-- 3. Duplicate order_id check
SELECT
    order_id,
    COUNT(*) AS occurrence_count
FROM NORTHWIND_MIGRATION.CURATED.orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- 4. Referential integrity: orphaned customer_id (orders -> customers)
SELECT
    o.order_id,
    o.customer_id
FROM NORTHWIND_MIGRATION.CURATED.orders o
LEFT JOIN NORTHWIND_MIGRATION.CURATED.customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- 5. Business rule: future order_date
SELECT
    order_id,
    order_date
FROM NORTHWIND_MIGRATION.CURATED.orders
WHERE order_date > CURRENT_DATE();

-- 6. Business rule: shipped_date before order_date )
SELECT
    order_id,
    order_date,
    shipped_date
FROM NORTHWIND_MIGRATION.CURATED.orders
WHERE shipped_date < order_date;