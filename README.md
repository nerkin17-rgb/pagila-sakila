# Pagila & Sakila ELT Platform (Airflow, Airbyte, Snowflake, dbt)

An end-to-end, enterprise-style ELT data platform automating database setup, cross-cloud replication, and analytical modeling across Pagila and Sakila schemas.

---

## 🏗️ Platform Architecture & Pipeline

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Database Provisioning & Automation                       │
│   [Apache Airflow] ──► Restores Pagila & Sakila (PostgreSQL)│
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Data Ingestion & Replication                             │
│   [ Airbyte ] ──► Replicates Postgres tables into           │
│                   Snowflake (`PAGILA_RAW` & `SAKILA_RAW`)   │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Data Transformation (dbt Medallion Layers)               │
│   [ dbt-snowflake ]                                         │
│     ├─ Staging: Type casting, renaming, cleaning            │
│     ├─ Intermediate: Enriched entities & business logic     │
│     ├─ Marts: Dimensional models (`dim_`, `fact_`)          │
│     └─ Analytics: Final reporting & metric views           │
└─────────────────────────────────────────────────────────────┘
```

---

## ⚙️ Key Technical Implementations

* **Airflow Automation:** Automated setup and initialization of Pagila/Sakila PostgreSQL databases.
* **Airbyte Replication:** Automated CDC/Batch replication targeting Snowflake with custom non-admin roles (`AIRFLOW_DEV_ROLE`).
* **Snowflake Security:** Least-privilege role-based access control (RBAC) ensuring Airflow and dbt operate without `ACCOUNTADMIN` rights.
* **dbt Data Transformations (`pagila_analytics`):**
  * **Staging Layer (`models/staging/`):** Standardizes raw sources defined in `sources.yml`.
  * **Intermediate Layer (`models/intermediate/`):** Joins, entity enrichment, and bridge tables.
  * **Mart Layer (`models/marts/`):** Star schema dimensions (`dim_film`, `dim_customer`) and fact tables (`fact_rental`, `fact_revenue`).
  * **Analytics Layer (`models/analytics/`):** Recreates analytical business queries (rental hours, category distributions, customer metrics).

---

## 🚀 Getting Started

1. **dbt Setup & Connection:**
   ```bash
   cd dbt/pagila_analytics
   dbt debug
   dbt deps
   dbt run
   dbt test
   ```
2. **Replication & Airflow:** Ensure Airflow connections use the dedicated non-admin Snowflake role for ingestion tasks.
