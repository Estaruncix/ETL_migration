-- Customers data quality validation

-- 1. Check for duplicate customer IDs
SELECT
    customer_id,
    COUNT(*) AS occurrence_count
FROM NORTHWIND_MIGRATION.MIGRATED.customers
GROUP BY customer_id
HAVING COUNT(*) > 1;


-- 2. Check for NULL customer IDs
SELECT
    COUNT(*) AS null_customer_ids
FROM NORTHWIND_MIGRATION.MIGRATED.customers
WHERE customer_id IS NULL;


-- 3. Check for NULL company names
SELECT
    COUNT(*) AS null_company_names
FROM NORTHWIND_MIGRATION.MIGRATED.customers
WHERE company_name IS NULL;


-- 4. Check for blank customer IDs
SELECT
    COUNT(*) AS blank_customer_ids
FROM NORTHWIND_MIGRATION.MIGRATED.customers
WHERE TRIM(customer_id) = '';


-- 5. Check for blank company names
SELECT
    COUNT(*) AS blank_company_names
FROM NORTHWIND_MIGRATION.MIGRATED.customers
WHERE TRIM(company_name) = '';


