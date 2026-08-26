-- Curating Northwind raw categories

CREATE TABLE NORTHWIND_MIGRATION.CURATED.CATEGORY (
    category_id     VARCHAR(10),
    category_name   VARCHAR(100),
    description      VARCHAR(1000),
    picture          VARCHAR(1000)
);

INSERT INTO NORTHWIND_MIGRATION.CURATED.CATEGORY
SELECT * FROM NORTHWIND_MIGRATION.RAW.CATEGORY;