#!/bin/bash
# Creates two independent databases in the same Postgres instance and loads
# the schema + data dumps produced in SQL task 1 (LMS). Drop your existing
# pagila-schema.sql / pagila-data.sql / sakila-schema.sql / sakila-data.sql
# into ./sql-dumps before starting the stack — they are gitignored on purpose
# (large binary-ish dumps don't belong in version control).
set -euo pipefail

DUMP_DIR="/docker-entrypoint-initdb.d/sql-dumps"

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "CREATE DATABASE pagila;"
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "CREATE DATABASE sakila;"

for pair in "pagila:pagila-schema.sql:pagila-data.sql" "sakila:sakila-schema.sql:sakila-data.sql"; do
  db="${pair%%:*}"
  rest="${pair#*:}"
  schema_file="${rest%%:*}"
  data_file="${rest#*:}"

  if [[ -f "${DUMP_DIR}/${schema_file}" ]]; then
    echo "Loading ${schema_file} into ${db}..."
    psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$db" -f "${DUMP_DIR}/${schema_file}"
  else
    echo "WARNING: ${DUMP_DIR}/${schema_file} not found, skipping schema load for ${db}"
  fi

  if [[ -f "${DUMP_DIR}/${data_file}" ]]; then
    echo "Loading ${data_file} into ${db}..."
    psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$db" -f "${DUMP_DIR}/${data_file}"
  else
    echo "WARNING: ${DUMP_DIR}/${data_file} not found, skipping data load for ${db}"
  fi
done
