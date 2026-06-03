#!/bin/bash
set -e

echo "Creating metabase database..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE DATABASE metabase;
    GRANT CONNECT ON DATABASE metabase TO warehouse;
    GRANT USAGE ON SCHEMA public TO warehouse;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO warehouse;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO warehouse;
EOSQL

echo "✓ Metabase database created successfully"