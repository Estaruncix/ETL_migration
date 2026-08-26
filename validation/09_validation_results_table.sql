-- Validation results
CREATE TABLE NORTHWIND_MIGRATION.CURATED.validation_results (
    check_id        NUMBER(10,0) AUTOINCREMENT,
    table_name      VARCHAR(50),
    check_name      VARCHAR(200),
    check_category  VARCHAR(50),
    rows_affected   NUMBER(10,0),
    check_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (check_id)
);

 INSERT INTO NORTHWIND_MIGRATION.CURATED.validation_results
    (table_name, check_name, check_category, rows_affected)
SELECT
    'customers',
    'Duplicate customer_id',
    'Duplicates',
    COUNT(*)
FROM ()