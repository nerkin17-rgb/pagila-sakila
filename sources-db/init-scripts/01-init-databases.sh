#!/bin/bash
set -e

psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "CREATE DATABASE pagila;"
psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "CREATE DATABASE sakila;"

psql -U "$POSTGRES_USER" -d pagila -f /docker-entrypoint-initdb.d/sql-dumps/pagila-schema.sql
psql -U "$POSTGRES_USER" -d pagila -f /docker-entrypoint-initdb.d/sql-dumps/pagila-data.sql

echo "Loading Sakila..."
psql -U "$POSTGRES_USER" -d sakila -f /docker-entrypoint-initdb.d/sql-dumps/sakila-schema.sql
psql -U "$POSTGRES_USER" -d sakila -f /docker-entrypoint-initdb.d/sql-dumps/sakila-data.sql

echo "=== DATABASE INITIALIZATION COMPLETE ==="