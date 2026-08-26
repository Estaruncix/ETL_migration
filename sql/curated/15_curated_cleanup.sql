/* =====================================================================
   STEP 14 — Curated layer cleanup
   =====================================================================
   Assumes:
     - RAW/STAGING schema has the 6 tables loaded as-is from CSV.
     - CURATED schema already exists with the same 6 tables, type-cast
       correctly, but otherwise untouched (this is the layer the
       validation queries were run against).
   This script takes that typed CURATED layer and applies the actual
   cleanup logic: reject/quarantine tables, flag columns, dedup, a
   surrogate key on order_details, and blank-string normalization.

   Adjust database/schema names below to match your environment.
   ===================================================================== */

USE DATABASE NORTHWIND_DATABASE;
USE SCHEMA CURATED;


/* =====================================================================
   1. CUSTOMERS
   - Dedup (keep-first by customer_id)
   - Normalize blank-string company_name -> NULL
   - Add needs_enrichment flag for missing company_name
   ===================================================================== */

CREATE OR REPLACE TABLE customers_clean AS
SELECT
    customer_id,
    company_name AS company_name_raw,   -- keep raw value for audit, drop later if not needed
    NULLIF(TRIM(company_name), '')  AS company_name,   -- '' -> NULL
    contact_name,
    contact_title,
    address,
    city,
    region,
    postal_code,
    country,
    phone,
    fax
FROM CUSTOMERS
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY customer_id
    ORDER BY customer_id   -- keep-first: swap for a load_timestamp column if you have one
) = 1;

-- add the enrichment flag now that blanks are normalized to NULL
ALTER TABLE customers_clean ADD COLUMN needs_enrichment BOOLEAN DEFAULT FALSE;

UPDATE customers_clean
SET needs_enrichment = TRUE
WHERE company_name IS NULL;

-- drop the raw audit column once you've confirmed the normalization looks right
ALTER TABLE customers_clean DROP COLUMN company_name_raw;

-- swap into place
ALTER TABLE customers RENAME TO customers_typed_backup;
ALTER TABLE customers_clean RENAME TO customers;


/* =====================================================================
   2. PRODUCTS
   - Correct the negative unit_price
   ===================================================================== */

UPDATE products
SET unit_price = ABS(unit_price)
WHERE unit_price < 0;

-- (only 1 row expected here per validation results — sanity check:)
-- SELECT * FROM products WHERE unit_price < 0;   -- should return 0 rows after the fix


/* =====================================================================
   3. ORDERS
   - Quarantine rows with orphaned customer_id (e.g. 'BASHL')
   - Flag rows with future order_date (also explains shipped_before_order)
   ===================================================================== */

CREATE OR REPLACE TABLE orders_reject AS
SELECT *
FROM orders
WHERE customer_id NOT IN (SELECT customer_id FROM customers);

CREATE OR REPLACE TABLE orders_clean AS
SELECT *
FROM orders
WHERE customer_id IN (SELECT customer_id FROM customers);

ALTER TABLE orders_clean ADD COLUMN is_flagged BOOLEAN DEFAULT FALSE;

UPDATE orders_clean
SET is_flagged = TRUE
WHERE order_date > CURRENT_DATE();

ALTER TABLE orders RENAME TO orders_typed_backup;
ALTER TABLE orders_clean RENAME TO orders;


/* =====================================================================
   4. ORDER_DETAILS
   - Quarantine rows with orphaned product_id and/or negative quantity
   - Add surrogate key order_detail_id
   ===================================================================== */

CREATE OR REPLACE TABLE order_details_reject AS
SELECT *
FROM order_details
WHERE product_id NOT IN (SELECT product_id FROM products)
   OR quantity < 0;

-- build the clean table with a surrogate key
CREATE OR REPLACE TABLE order_details_clean (
    order_detail_id INT AUTOINCREMENT START 1 INCREMENT 1,
    order_id        INT,
    product_id      INT,
    unit_price      NUMBER(10,2),
    quantity        INT,
    discount        NUMBER(4,2)
);

INSERT INTO order_details_clean (order_id, product_id, unit_price, quantity, discount)
SELECT order_id, product_id, unit_price, quantity, discount
FROM order_details
WHERE product_id IN (SELECT product_id FROM products)
  AND quantity >= 0;

ALTER TABLE order_details RENAME TO order_details_typed_backup;
ALTER TABLE order_details_clean RENAME TO order_details;


/* =====================================================================
   5. SUPPLIERS — no cleanup needed
   No duplicates, no orphaned FKs found. missing_region (20 rows) is
   natural/optional data, left as-is with no flag.
   ===================================================================== */

-- (no changes — suppliers passes through as-is from the typed curated layer)


/* =====================================================================
   6. CATEGORIES — no cleanup needed
   No duplicates, no missing description. Fully clean.
   ===================================================================== */

-- (no changes — categories passes through as-is from the typed curated layer)


/* =====================================================================
   Sanity checks — re-run after the above to confirm expected counts
   ===================================================================== */

SELECT COUNT(*) AS orders_reject_count FROM orders_reject;              -- expect 1
SELECT COUNT(*) AS order_details_reject_count FROM order_details_reject; -- expect 1 or 2
SELECT COUNT(*) AS customers_flagged_count FROM customers WHERE needs_enrichment = TRUE; -- expect 2 or 3
SELECT COUNT(*) AS orders_flagged_count FROM orders WHERE is_flagged = TRUE;             -- expect 2
SELECT COUNT(*) AS products_negative_price FROM products WHERE unit_price < 0;           -- expect 0
SELECT customer_id, COUNT(*) FROM customers GROUP BY customer_id HAVING COUNT(*) > 1;    -- expect 0 rows
