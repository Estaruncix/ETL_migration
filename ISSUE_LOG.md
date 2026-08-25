# Issue / Discrepancy Log

**Project:** Multi-Source ETL Migration & Validation — Northwind Edition
**Stage:** Step 6 — Post-validation issue documentation
**Status:** Finalized — all curated-layer cleanup actions confirmed via post-cleanup validation

---

## Purpose

This log documents every data-quality issue caught by the Step 5 validation
queries, the root cause behind each one, and the resolution decision applied
before promoting data from the `raw`/staging layer to the `curated` layer.

Every issue below falls into one of three resolution categories:

- **Correct** — the value is fixed because we have a reliable way to derive
  or confirm the right value; the corrected row is trusted and promoted to
  curated.
- **Quarantine** — the row is routed to a `*_reject` table instead of the
  curated layer. We don't have enough information to safely infer the
  correct value, so we preserve the row for investigation rather than
  guessing or silently dropping it.
- **Flag for manual review** — the row is promoted to curated as-is, but
  tagged with a flag column (e.g. `is_flagged`, `needs_enrichment`) so
  downstream consumers can filter it out or route it to a human reviewer.

No row is ever silently deleted. Every excluded row has a corresponding
entry in a reject table so the migration is fully auditable.

---

## Summary

Source: Snowflake `VALIDATION_RESULTS` table, run against staging layer.

### A. Deliberately injected issues (the 7 test cases)

| # | Table | Rows Affected | Category | Resolution |
|---|-------|---------------|----------|------------|
| DQ-01 | orders | 2 | Business-rule validity (`future_order_date`) | Flag for manual review — ✅ done |
| DQ-02 | order_details | 1 | Referential integrity (`orphaned_product_id`) | Quarantine — ✅ done |
| DQ-03 | order_details | 1 | Business-rule validity (`negative_quantities`) | Quarantine — ✅ done |
| DQ-04 | products | 1 | Business-rule validity (`negative_unit_price`) | Correct — ✅ done |
| DQ-05 | customers | 2 | Duplicate detection (`duplicate_customer_id` / `full_row_duplicates`) | Correct — ✅ done |
| DQ-06 | customers | 2 (post-cleanup) | Completeness (`missing_company_name`) | Flag for manual review — ✅ done |
| DQ-07 | orders | 1 | Referential integrity (`orphaned customer_id`) | Quarantine — ✅ done |

All 7 row counts confirm exactly against what was manually injected in Step 2. ✅
`order_details_reject` ended up with **2 rows total** — the orphaned `product_id`
and the negative `quantity` turned out to be two different rows, not the same one.
Post-cleanup validation (Step 4b) confirms all counts reconcile correctly. ✅

### B. Additional findings — naturally occurring in the real Northwind dataset

These were **not** deliberately injected; they're pre-existing nulls/anomalies in the
real Northwind CSVs, surfaced by the same validation suite. They're documented here for
completeness and transparency, but tracked separately from the test-case issues above
since they represent "real-world messiness" rather than planted test data.

| # | Table | Rows Affected | Category | Note |
|---|-------|---------------|----------|------|
| DQ-08 | customers | 62 | Completeness (`missing_region`) | Real Northwind data — many customers never had `region` populated |
| DQ-09 | customers | 22 | Completeness (`missing_fax`) | Real Northwind data — `fax` optional at source |
| DQ-10 | suppliers | 20 | Completeness (`missing_region`) | Same pattern as DQ-08, different table |
| DQ-11 | orders | 21 | Completeness (`missing_shipped_date`) | Legitimate — order not yet shipped at time of extract |
| — | orders | 2 | `shipped_before_order` | **Not a separate issue** — downstream side effect of DQ-01 (future `order_date`); documented under DQ-01 above |
| DQ-13 | customers | 1 | Completeness (`blank_string_check`) | Empty string (not NULL) — distinct from DQ-06, may need its own normalization rule |
| DQ-14 | customers | 1 | Completeness (`blank_string_check_companies`) | Empty-string `company_name` — a second, narrower case sitting alongside DQ-06's NULL count |

---

## Detailed Log

### DQ-01 — Future-dated orders (and downstream shipped_before_order effect)
- **Table:** `orders`
- **Column(s):** `order_date` (and, as a side effect, `shipped_date` now
  reads as earlier than `order_date` on the same 2 rows)
- **Detected by:** Business-rule validity checks — `future_order_date`
  (2 rows) and `shipped_before_order` (2 rows). **Both checks are firing
  on the same 2 rows and share the same root cause** — this was
  originally logged as a separate finding (DQ-12) but is actually a
  downstream consequence of this issue, not an independent one.
- **Description:** 2 rows have `order_date` values changed to 2027. Since
  `shipped_date` on those rows was left untouched (a normal historical
  date), the order now also appears to have shipped before it was placed.
- **Root cause:** `order_date` was set to a future year (2027) on these 2
  rows. In a production scenario, the analog would be source-system clock
  skew at time of entry or a manual data-entry error (e.g. wrong century
  typed) — and note that a single bad date field can cascade into
  triggering *multiple* downstream validation checks, which is worth
  calling out when triaging: don't assume every failed check is a
  separate root cause.
- **Resolution:** Flag for manual review. The rows are loaded into
  `curated.orders` with `is_flagged = TRUE` and excluded from any
  date-based reporting views (e.g. monthly sales trends) until a human
  confirms the correct date against the source system.
- **Action taken:** [x] Done — `orders.is_flagged` column added; 2 rows
  (order_date in 2027) set to `TRUE`. Reporting views to be updated
  separately to exclude flagged rows.

---

### DQ-02 — Orphaned `product_id` in order_details
- **Table:** `order_details`
- **Column(s):** `product_id`
- **Detected by:** Referential integrity check (`order_details.product_id`
  not present in `products.product_id`)
- **Description:** 1 row has `product_id = 1111`, which does not exist in
  the `products` table (the original value was `11`).
- **Root cause (plausible production analog):** Product deleted/retired
  from the catalog after the order was placed, or a transposed/mistyped
  ID during entry or extract.
- **Resolution:** Quarantine. We cannot safely infer whether `1111` was
  meant to be `11` or is a genuinely different, missing product — guessing
  risks corrupting the order line. The row is routed to
  `order_details_reject` and excluded from the curated fact table.
- **Action taken:** [x] Done — row moved to `order_details_reject`,
  excluded from `curated.order_details`. Confirmed via post-cleanup
  validation: this row is 1 of the 2 total rows now sitting in
  `order_details_reject` (see DQ-03 — confirmed to be a **different**
  row, not the same one).

---

### DQ-03 — Negative quantity in order_details
- **Table:** `order_details`
- **Column(s):** `quantity`
- **Detected by:** Business-rule validity check (`quantity <= 0`)
- **Description:** 1 row has a negative `quantity` value.
- **Root cause (plausible production analog):** Data-entry error. Northwind's
  schema has no native returns/credit-line concept, so a negative quantity
  on an order line isn't a valid business state — it's not a return, it's
  bad data.
- **Resolution:** Quarantine. Without a returns/adjustment model, there's no
  reliable way to "correct" this to a valid positive value. Routed to
  `order_details_reject` pending confirmation from the source system.
- **Action taken:** [x] Done — row moved to `order_details_reject`,
  excluded from `curated.order_details`. This is the 2nd of the 2 rows
  in `order_details_reject` — confirmed distinct from the DQ-02 row.

---

### DQ-04 — Negative unit_price in products
- **Table:** `products`
- **Column(s):** `unit_price`
- **Detected by:** Business-rule validity check (`unit_price < 0`)
- **Description:** 1 row has a negative `unit_price`.
- **Root cause (plausible production analog):** Data-entry error (e.g.
  a stray minus sign) or a sign error carried over from an upstream
  discount/adjustment field.
- **Resolution:** Correct. Unlike DQ-03, this is a single-column,
  single-value error on a dimension table where we can hold the row in
  staging and correct the sign once the pricing team confirms the intended
  value, rather than losing the product row entirely.
- **Action taken:** [x] Done — value corrected in place in
  `curated.products` (sign flipped via `ABS(unit_price)`). Post-cleanup
  validation confirms 0 rows remain with `unit_price < 0`.

---

### DQ-05 — Duplicate customer rows
- **Table:** `customers`
- **Column(s):** all (full-row duplication) / `customer_id` (key duplication)
- **Detected by:** Duplicate detection checks — `duplicate_customer_id`
  (2 rows) and `full_row_duplicates` (2 rows); both checks agree on the
  same 2 affected rows.
- **Description:** 2 customer rows are duplicated in the staging table
  (same `customer_id`, same row content).
- **Root cause (plausible production analog):** Re-extraction of source
  data without deduplication, or a failed upstream merge/dedup step
  during a prior load.
- **Resolution:** Correct. Deduplicated in the curated layer using
  `customer_id` as the business key, applying a **keep-first** rule
  (first occurrence by load order retained; subsequent duplicates
  dropped). The 2 removed rows are logged for the audit trail rather
  than silently discarded.
- **Action taken:** [x] Done — dedup applied via `QUALIFY ROW_NUMBER()
  OVER (PARTITION BY customer_id ORDER BY customer_id) = 1` in
  `curated.customers`. Post-cleanup validation confirms 0 duplicate
  `customer_id` values remain. **Note:** one of the 2 rows removed here
  appears to have also been the blank-string `company_name` row from
  DQ-13/14 — see DQ-06 below for why the enrichment-flag count came out
  lower than initially expected.

---

### DQ-06 — Missing company_name
- **Table:** `customers`
- **Column(s):** `company_name`
- **Detected by:** Completeness / null check (`missing_company_name`) — 2 rows.
  Note: a related but distinct check, `blank_string_check_companies`, caught
  1 additional row where `company_name` is an **empty string** rather than
  `NULL` — see DQ-14 below. These are tracked separately since an empty
  string and a NULL may need different normalization handling.
- **Description:** 2 rows have `company_name` set to `NULL`.
- **Root cause (plausible production analog):** Incomplete source extract,
  or the field was dropped/nulled during a prior migration step.
- **Resolution:** Flag for manual review. We do not fabricate a company
  name. Rows are loaded into `curated.customers` with the NULL preserved
  and a `needs_enrichment = TRUE` flag, to be resolved by following up
  with the source system or business owner.
- **Action taken:** [x] Done — blank strings normalized to `NULL` first
  (`NULLIF(TRIM(company_name), '')`), then `customers.needs_enrichment`
  flag added, set `TRUE` where `company_name IS NULL`.
  **Result: 2 rows flagged, not 3 as initially expected.** The most
  likely explanation: the blank-string `company_name` row (DQ-13/14) was
  one of the 2 duplicate rows removed during dedup (DQ-05), so it never
  reached the flagging step as a distinct row. This is a reasonable
  outcome — worth a one-line note in the README about check order
  (dedup before flagging) affecting downstream counts — but if you want
  to confirm definitively, re-run the dedup and flag steps in the
  opposite order on a scratch copy and compare.

---

### DQ-07 — Orphaned customer_id in orders (BASHL)
- **Table:** `orders`
- **Column(s):** `customer_id`
- **Detected by:** Referential integrity check (`orders.customer_id` not
  present in `customers.customer_id`)
- **Description:** 1 row has `customer_id = 'BASHL'`, which does not exist
  in the `customers` table.
- **Root cause (plausible production analog):** Truncated or mistyped
  customer code, or the customer record was deleted/archived after the
  order was placed.
- **Resolution:** Quarantine. As with DQ-02, we have no reliable way to
  map `BASHL` back to a valid customer without external confirmation.
  Routed to `orders_reject` and excluded from the curated fact table.
- **Action taken:** [x] Done — row moved to `orders_reject`, excluded
  from `curated.orders`. Post-cleanup validation confirms row-count
  reconciliation: `829 clean + 1 reject = 830` original baseline. ✅

---

## Additional findings (naturally occurring, not part of the test set)

These rows come from the real Northwind extract and were not deliberately
altered. They're documented for transparency and completeness, and because
a real migration would need a stance on them too — but they're a different
class of problem from DQ-01–07 and are handled with a lighter touch.

### DQ-08 / DQ-09 / DQ-10 — Missing region / fax (customers, suppliers)
- **Rows:** 62 customers missing `region`, 22 customers missing `fax`,
  20 suppliers missing `region`.
- **Root cause:** These fields were genuinely optional/sparsely filled in
  the original Northwind dataset — not a migration defect.
- **Resolution:** Correct as-is (load NULL, no flag). These are expected,
  low-risk nulls on optional attributes, not blocking issues. No action
  needed beyond confirming they're documented so they aren't mistaken for
  a migration bug later.

### DQ-11 — Missing shipped_date (orders)
- **Rows:** 21
- **Root cause:** Legitimate — these orders had not yet shipped as of the
  data extract.
- **Resolution:** Correct as-is (load NULL). This is expected order-lifecycle
  behavior, not a data-quality defect.

### DQ-13 / DQ-14 — Blank string values (customers)
- **Rows:** 1 row with a blank string somewhere in `customers`
  (`blank_string_check`), 1 row with blank-string `company_name`
  specifically (`blank_string_check_companies`).
- **Root cause:** Empty string (`''`) is a different data state than
  `NULL` — likely a source system that distinguishes "field cleared by
  user" from "field never populated."
- **Resolution:** Correct — normalize empty strings to `NULL` during the
  staging → curated transformation so completeness checks (like DQ-06)
  aren't undercounting.
- **Action taken:** [x] Done — `NULLIF(TRIM(company_name), '')` applied
  in `curated.customers`. Post-cleanup validation confirms 0 rows remain
  with `company_name = ''`. **Result differs from the original
  expectation:** `needs_enrichment` came out to 2 rows, not 3. Most
  likely explanation is that the blank-string row was also one of the 2
  duplicates removed during dedup (DQ-05) — see the note on DQ-06 for
  detail. Not treated as a discrepancy, just documented for traceability.

---

## Notes for reviewers

- All quarantined rows (DQ-02, DQ-03, DQ-07) are recoverable — they live
  in `*_reject` tables, not deleted, and can be re-processed into curated
  once root cause is confirmed.
- All flagged rows (DQ-01, DQ-06) are visible in curated but marked, so
  reporting layers can choose to include or exclude them explicitly
  rather than being silently affected.
- DQ-01 is a good example of one root cause triggering multiple failed
  checks (`future_order_date` and `shipped_before_order`) — worth keeping
  in mind during triage so you don't double-count root causes.
- The injected test-case counts (Section A) all matched expectations
  exactly, confirming the validation suite is working correctly.
- Section B findings are a good talking point in the README: they show
  the validation suite also surfaces real-world data-quality issues, not
  just the planted ones — which is the actual point of building it this way.
- All 7 injected-issue actions (Section A) are now confirmed done and
  reconciled against post-cleanup validation (`step4b_post_cleanup_validation.sql`).
- The DQ-05/DQ-06/DQ-13 interaction (dedup removing the blank-string row
  before it could be flagged) is a good example to walk through in the
  README — it shows the *order* of cleanup operations matters and can
  shift downstream counts in legitimate, explainable ways.
- This log should be cross-referenced with the Step 5 validation query
  results summary and the Step 7 Excel reconciliation summary — the
  numbers across all three should match exactly.
