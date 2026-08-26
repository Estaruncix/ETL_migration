-- Suppliers: baseline + completeness + duplicates
SELECT COUNT(*) AS total_rows FROM NORTHWIND_MIGRATION.CURATED.suppliers;

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) - COUNT(supplier_id)   AS missing_supplier_id,
    COUNT(*) - COUNT(company_name)  AS missing_company_name,
    COUNT(*) - COUNT(contact_name)  AS missing_contact_name,
    COUNT(*) - COUNT(phone)         AS missing_phone
FROM NORTHWIND_MIGRATION.CURATED.suppliers;

SELECT supplier_id, COUNT(*) AS occurrence_count
FROM NORTHWIND_MIGRATION.CURATED.suppliers
GROUP BY supplier_id
HAVING COUNT(*) > 1;

