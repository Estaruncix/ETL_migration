-- Category: baseline + completeness + duplicates
SELECT COUNT(*) AS total_rows FROM NORTHWIND_MIGRATION.CURATED.category;

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) - COUNT(category_id)    AS missing_category_id,
    COUNT(*) - COUNT(category_name)  AS missing_category_name
FROM NORTHWIND_MIGRATION.CURATED.category;

SELECT category_id, COUNT(*) AS occurrence_count
FROM NORTHWIND_MIGRATION.CURATED.category
GROUP BY category_id
HAVING COUNT(*) > 1;