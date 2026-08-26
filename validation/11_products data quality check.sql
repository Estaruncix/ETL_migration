-- 10 products data quality check

-- 1. Row-count baseline
SELECT COUNT(*) AS total_rows
FROM NORTHWIND_MIGRATION.CURATED.products;

-- 2. Completeness check across all columns
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) - COUNT(product_id)         AS missing_product_id,
    COUNT(*) - COUNT(product_name)       AS missing_product_name,
    COUNT(*) - COUNT(supplier_id)        AS missing_supplier_id,
    COUNT(*) - COUNT(category_id)        AS missing_category_id,
    COUNT(*) - COUNT(quantity_per_unit)  AS missing_quantity_per_unit,
    COUNT(*) - COUNT(unit_price)         AS missing_unit_price,
    COUNT(*) - COUNT(units_in_stock)     AS missing_units_in_stock,
    COUNT(*) - COUNT(units_on_order)     AS missing_units_on_order,
    COUNT(*) - COUNT(reorder_level)      AS missing_reorder_level,
    COUNT(*) - COUNT(discontinued)       AS missing_discontinued
FROM NORTHWIND_MIGRATION.CURATED.products;

-- 3. Duplicate product_id check
SELECT
    product_id,
    COUNT(*) AS occurrence_count
FROM NORTHWIND_MIGRATION.CURATED.products
GROUP BY product_id
HAVING COUNT(*) > 1;

-- 4. Referential integrity: orphaned supplier_id
SELECT
    p.product_id,
    p.supplier_id
FROM NORTHWIND_MIGRATION.CURATED.products p
LEFT JOIN NORTHWIND_MIGRATION.CURATED.suppliers s
    ON p.supplier_id = s.supplier_id
WHERE s.supplier_id IS NULL;

-- 5. Referential integrity: orphaned category_id
SELECT
    p.product_id,
    p.category_id
FROM NORTHWIND_MIGRATION.CURATED.products p
LEFT JOIN NORTHWIND_MIGRATION.CURATED.category cat
    ON p.category_id = cat.category_id
WHERE cat.category_id IS NULL;

-- 6. Business rule: negative unit_price
SELECT
    product_id,
    unit_price
FROM NORTHWIND_MIGRATION.CURATED.products
WHERE unit_price < 0;

-- 7. Business rule: negative stock/order/reorder quantities (bonus — you didn't plant these, but worth checking)
SELECT
    product_id,
    units_in_stock,
    units_on_order,
    reorder_level
FROM NORTHWIND_MIGRATION.CURATED.products
WHERE units_in_stock < 0
   OR units_on_order < 0
   OR reorder_level < 0;