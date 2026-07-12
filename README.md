# pagila-sakila data platform

Postgres (Pagila + Sakila) → Airbyte → Snowflake (RAW) → dbt (ANALYTICS), orchestrated by Airflow.

```
postgres_sources (docker)          Airbyte (abctl, separate)         Snowflake
┌─────────────┐                    ┌──────────────────┐        ┌───────────────────┐
│ pagila db   │ ───► source ─────► │  LOADER_ROLE      │ ────►  │ RAW.PAGILA_RAW     │
│ sakila db   │ ───► source ─────► │  (AIRBYTE_SVC)    │ ────►  │ RAW.SAKILA_RAW     │
└─────────────┘                    └──────────────────┘        └─────────┬──────────┘
                                                                          │ read (SELECT only)
                                    Airflow (docker) ──────────────────► TRANSFORM_ROLE (AIRFLOW_SVC)
                                    triggers Airbyte syncs                     │ dbt run/test
                                    then runs dbt                             ▼
                                                                    ANALYTICS.{staging,intermediate,
                                                                              marts,analytics}
```

Two Snowflake service roles, two purposes, neither is ADMIN — see `snowflake/setup.sql`:

| Role             | Used by | Access                                              |
|------------------|---------|------------------------------------------------------|
| `LOADER_ROLE`    | Airbyte | full control inside `RAW` db only                     |
| `TRANSFORM_ROLE` | Airflow/dbt | `SELECT` on `RAW`, full control inside `ANALYTICS` db |

## Repo layout

```
.
├── docker-compose.yml            # postgres_sources + airflow, one file, one network
├── .env.example                  # every secret the stack needs, single source of truth
├── sources-db/init-scripts/      # DB bootstrap; drop your existing pagila/sakila dumps into sql-dumps/
├── snowflake/setup.sql           # roles, warehouses, databases, grants (run once, manually)
├── airbyte/                      # configure_airbyte.py — sources, destination, connections as code
├── airflow/                      # Dockerfile + single DAG (trigger Airbyte syncs, then dbt)
└── pagila_analytics/             # dbt project — models/*.sql already written, not touched here
```

## Setup order

1. **Source DB** — put your existing dump files from SQL task 1 into
   `sources-db/init-scripts/sql-dumps/` (`pagila-schema.sql`, `pagila-data.sql`,
   `sakila-schema.sql`, `sakila-data.sql`), copy `.env.example` to `.env` and fill
   in `SRC_DB_*`.

2. **Snowflake** — generate two RSA key pairs (Airbyte, Airflow), run
   `snowflake/setup.sql` as ACCOUNTADMIN, pasting the public keys in. Keep the
   private keys out of git: Airflow's goes in `airflow/secrets/` (gitignored,
   mounted read-only into the containers), Airbyte's goes into
   `airbyte/terraform.tfvars` (also gitignored).

3. **Airflow + source DB**:
   ```bash
   docker compose up -d --build
   ```
   Webserver on `localhost:8080`. On first boot it also registers a
   `snowflake_default` Airflow connection using `TRANSFORM_ROLE`.

4. **Airbyte** — Docker Compose deployments of Airbyte are deprecated
   upstream, so it's installed separately, not as a service in
   `docker-compose.yml`:
   ```bash
   curl -LsfS https://get.airbyte.com | bash
   abctl local install
   ```
   Create an API application in the Airbyte UI (Settings → Applications) for
   `AIRBYTE_CLIENT_ID`/`AIRBYTE_CLIENT_SECRET`, put the Airbyte loader's
   private key at `AIRBYTE_SF_LOADER_PRIVATE_KEY_PATH`, fill in the rest of
   the `AIRBYTE_*` variables in `.env`, then run the config script — it
   creates the two Postgres sources, the shared Snowflake destination, and
   the two connections (Pagila → `RAW.PAGILA_RAW`, Sakila → `RAW.SAKILA_RAW`)
   via Airbyte's REST API, and is safe to re-run (matches by name instead of
   creating duplicates):
   ```bash
   cd airbyte
   pip install -r requirements.txt
   python configure_airbyte.py
   ```
   Copy the two connection IDs it prints into `.env`
   (`AIRBYTE_PAGILA_CONNECTION_ID` / `AIRBYTE_SAKILA_CONNECTION_ID`), then
   `docker compose up -d` again to pick up the new values.

5. **dbt** — your existing `models/staging/*.sql`, `models/intermediate/*.sql`,
   `models/marts/*.sql`, `models/analytics/*.sql` go into the matching folders
   under `pagila_analytics/models/` (only `sources.yml` was added here, since
   it wasn't part of the layer SQL). Locally:
   ```bash
   cd pagila_analytics
   cp profiles.yml.example profiles.yml   # or rely on env vars from docker-compose
   dbt debug
   dbt run
   dbt test
   ```
   In production this all runs inside the `airflow_scheduler`/`airflow_webserver`
   containers, triggered by the `pagila_sakila_pipeline` DAG
   (`airflow/dags/dbt_run_dag.py`): sync Pagila + sync Sakila via the Airbyte
   API → `dbt deps` → `dbt run` → `dbt test`.

## Why it's structured this way

- **One `docker-compose.yml`, not two.** Source DB and Airflow share one
  compose file and one auto-created network — no manual
  `docker network create` step, no cross-file network wiring.
- **Airbyte is not in Docker Compose.** It's deployed once via `abctl`
  (the only currently supported self-managed path). Its sources,
  destination, and connections are configured by a single idempotent script
  against Airbyte's REST API (`airbyte/configure_airbyte.py`) instead of
  clicking through the UI — reviewable in git, no extra tool/dependency
  beyond `requests`, safe to re-run.
- **Two Snowflake roles, not one shared "dev" role.** Airbyte only ever
  needs to write to `RAW`; Airflow/dbt only ever needs to read `RAW` and
  write `ANALYTICS`. Splitting them means a leaked Airbyte key can't touch
  transformed data, and a leaked Airflow key can't touch raw ingestion.
- **Key-pair auth for both service accounts**, not passwords — standard
  practice for non-interactive Snowflake service users.
- **Freshness checks reuse Airbyte's own `_airbyte_extracted_at` column**
  (`models/staging/sources.yml`) instead of inventing a second loaded-at
  mechanism.
