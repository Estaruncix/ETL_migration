# Multi-Source ETL Migration & Validation; Northwind Edition

A hands-on ETL migration project simulating a legacy-to-modern-warehouse
migration: real Northwind CSV extracts are loaded into Snowflake, deliberately
seeded with common real-world data-quality problems, and then caught, resolved,
and documented end-to-end the same style of migration/validation work run on
commercial BI projects (orders, customers, products, referential integrity,
row-count reconciliation).

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Methodology](#methodology)
3. [Schema & Key Mapping](#schema--key-mapping)
4. [The Deliberate-Error Approach](#the-deliberate-error-approach)
5. [Data-Quality Findings & Resolutions](#data-quality-findings--resolutions)
6. [Repository Structure](#repository-structure)
7. [Results Summary](#results-summary)

---

## Project Overview

This project migrates six Northwind tables; `customers`, `orders`,
`order_details`, `products`, `suppliers`, `categories` from flat CSV
extracts into a Snowflake warehouse, through a staging → curated layer
pattern. Along the way, targeted, known data-quality issues were introduced
into a copy of the real data, then caught by a validation suite and resolved
using an auditable, no-silent-deletion approach (correct / quarantine / flag).

**Project Goals:** to demonstrate a realistic ETL/data-quality
workflow end-to-end schema mapping, staging, transformation, validation,
issue triage, and stakeholder reporting using a dataset structured enough
to have meaningful relational integrity (Northwind), rather than a fully synthethic flat file.

---

## Methodology

| Step | What |
|---|---|
| 1 | Schema mapping & data audit: entities, PKs/FKs, catalog of planned issues |
| 2 | Source data preparation: real Northwind CSVs + targeted error injection |
| 3 | Snowflake environment setup: staging layer, all 6 tables loaded as-is |
| 4 | SQL migration/transformation: typed curated layer, then cleanup logic (flags, reject tables, dedup, surrogate key) |
| 5 | Data quality validation queries: referential integrity, business rules, duplicates, completeness |
| 6 | Issue/discrepancy log: root cause + resolution per finding |
| 7 | Excel reconciliation summary: stakeholder-facing pass/fail by table |
| 8 | Documentation & packaging: this README, screenshots, GitHub push |

A deliberate design choice: **validation ran first, against a type-cast but
otherwise unmodified curated layer**, and the results of that validation
directly drove what the final cleanup SQL needed to do.

---

## Schema & Key Mapping

| Table | Primary Key | Foreign Keys | Notes |
|---|---|---|---|
| `customers` | `customer_id` | | Referenced by `orders.customer_id` |
| `orders` | `order_id` | `customer_id` → `customers` |  |
| `order_details` | *(composite: `order_id` + `product_id`)* | `order_id` → `orders`, `product_id` → `products` | No natural single-column PK surrogate key added in curated layer |
| `products` | `product_id` | `supplier_id` → `suppliers`, `category_id` → `categories` | |
| `suppliers` | `supplier_id` | — | Referenced by `products.supplier_id` |
| `categories` | `category_id` | — | Referenced by `products.category_id` |

---

## The Deliberate-Error Approach

Rather than generating fully synthetic test data, this project starts from
**real Northwind CSVs** and manually introduces a small, deliberate set of
errors into a copy of that data (`data/migrated/`), while keeping the
original untouched in `data/raw/`. This is closer to "known-good real data
with known-bad rows added for testing" than fully synthetic noise, and it
has a useful side effect: because the underlying data is real, the
validation suite also surfaces genuine, pre-existing data-quality quirks in
the source (see [Results Summary](#results-summary)) — which is exactly the
kind of signal a validation suite needs to prove it works on, not just the
planted cases.

Each injected error targets a specific validation category, so that passing
validation actually proves something:

| Error Injected | Table | Validation Category Tested |
|---|---|---|
| 2 `order_date` values set to a future year (2027) | `orders` | Business-rule validity |
| `product_id` changed from `11` to `1111` | `order_details` | Referential integrity (orphaned FK) |
| 1 `quantity` value set negative | `order_details` | Business-rule validity |
| 1 `unit_price` value set negative | `products` | Business-rule validity |
| Customer rows duplicated | `customers` | Duplicate detection |
| `company_name` deleted (NULL) on some rows | `customers` | Completeness / null checks |
| `customer_id` changed to a non-existent value (`BASHL`) | `orders` | Referential integrity (orphaned FK) |

---

## Data-Quality Findings & Resolutions

Full detail lives in [`docs/ISSUE_LOG.md`](docs/ISSUE_LOG.md) and the
stakeholder-facing version in
[`reconciliation_summary.xlsx`](reconciliation_summary.xlsx). Short version:

- **7/7 injected issues** were caught by the validation suite with exact
  row-count matches, and resolved using one of three approaches:
  **Correct** (fixed in place such as the negative price), **Quarantine**
  (moved to a `*_reject` table, excluded from curated but fully
  recoverable such as both orphaned-FK cases and the negative quantity),
  or **Flag for manual review** (kept in curated, marked with a boolean
  column such as the future-dated orders and missing company names).
- No row was ever silently deleted. Every excluded row has a corresponding
  entry in a reject table.
- The validation suite also caught **naturally-occurring gaps in the real
  data** (missing `region`/`fax`/`shipped_date`) that were reviewed and
  confirmed to be normal, pre-existing sparsity not migration defects.

---

## Repository Structure

```
├── data/
│   ├── raw/                        # original, unmodified Northwind CSVs
│   └── migrated/                   # error-injected versions used for staging
├── sql/
│   ├── staging/                    # staging table DDL / load scripts
│   └── curated/
│       └── step4_curated_cleanup.sql
├── validation/
│   └── validation_queries.sql      # the full validation query suite
│
├── schema_reference.md
├── ISSUE_LOG.md
├── reconciliation_summary.xlsx
└── README.md
```

## Results Summary

| Table | Source Records | Set Aside | Flagged | Final Curated Count | Status |
|---|---|---|---|---|---|
| Customers | 93 | 0 | 2 | 91 | Pass – Review Recommended |
| Orders | 830 | 1 | 2 | 829 | Pass – Review Recommended |
| Order Details | 2,155 | 2 | 0 | 2,153 | Pass |
| Products | 77 | 0 | 0 | 77 | Pass |
| Suppliers | 29 | 0 | 0 | 29 | Pass |
| Categories | 8 | 0 | 0 | 8 | Pass |
| **Total** | **3,192** | **3** | **4** | **3,187** | |

---
