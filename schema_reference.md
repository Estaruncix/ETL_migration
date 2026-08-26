# Schema & Key Reference

**Project:** Multi-Source ETL Migration & Validation — Northwind Edition
**Stage:** Step 1; Schema mapping & data audit

---

## Purpose

This document catalogs the entities, primary keys, and foreign keys across
all 6 tables in scope for this migration, and maps each deliberately
introduced data-quality issue to the validation category it's designed to
test. This is the planning reference the rest of the project (staging load,
curated transformation, validation suite, issue log) is built against.

---

## Entities in Scope

Six tables from the Northwind dataset are in scope for this migration:

- `customers`
- `orders`
- `order_details`
- `products`
- `suppliers`
- `categories`

---

## Schema & Key Mapping

| Table | Primary Key | Foreign Keys | Notes |
|---|---|---|---|
| `customers` | `customer_id` | — | Referenced by `orders.customer_id` |
| `orders` | `order_id` | `customer_id` → `customers` |  |
| `order_details` | *(composite: `order_id` + `product_id`)* | `order_id` → `orders`, `product_id` → `products` | No natural single-column PK in the source; a surrogate key (`order_detail_id`) is generated in the curated layer |
| `products` | `product_id` | `supplier_id` → `suppliers`, `category_id` → `categories` | |
| `suppliers` | `supplier_id` | — | Referenced by `products.supplier_id` |
| `categories` | `category_id` | — | Referenced by `products.category_id` |

### Entity-relationship summary

```
customers ──< orders ──< order_details >── products >── suppliers
                                              └────────> categories
```

- One customer can place many orders.
- One order can contain many order_details (line items).
- One product can appear in many order_details, belongs to one supplier and one category.

---

## Deliberate Data-Quality Issues Catalog

Real Northwind CSVs (`data/raw/`) were copied and manually edited
(`data/migrated/`) to introduce the following targeted errors. Each one maps
to a specific validation category, so that a passing validation suite
actually proves something rather than just running clean by default.

| Error Injected | Table | Column(s) | Validation Category |
|---|---|---|---|
| 2 `order_date` values changed to a future year (2027) | `orders` | `order_date` | Business-rule validity |
| `product_id` changed from `11` to `1111` | `order_details` | `product_id` | Referential integrity (orphaned FK) |
| 1 `quantity` value set negative | `order_details` | `quantity` | Business-rule validity |
| 1 `unit_price` value set negative | `products` | `unit_price` | Business-rule validity |
| Customer rows duplicated | `customers` | *(full row)* | Duplicate detection |
| `company_name` deleted (set to NULL) on some rows | `customers` | `company_name` | Completeness / null checks |
| `customer_id` changed to a non-existent value (`BASHL`) | `orders` | `customer_id` | Referential integrity (orphaned FK) |

Full results of the validation suite run against these planted issues, plus
the naturally-occurring findings surfaced along the way (missing
region/fax/shipped_date inherent to the real dataset, not injected), are
documented in [`ISSUE_LOG.md`](ISSUE_LOG.md).

---

## Row Count Baselines (pre-migration)

| Table | Row Count |
|---|---|
| `customers` | 93 |
| `orders` | 830 |
| `order_details` | 2,155 |
| `products` | 77 |
| `suppliers` | 29 |
| `categories` | 8 |

These baselines are used in the post-cleanup reconciliation step to confirm
no rows were silently lost during transformation (`clean_count + reject_count
= baseline` for every table with quarantined rows).
