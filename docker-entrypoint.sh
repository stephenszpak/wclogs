#!/bin/bash
set -e

# Wait for database to be ready
echo "Waiting for database to be ready..."
while ! pg_isready -h "${DATABASE_HOST:-db}" -p "${DATABASE_PORT:-5432}" -U "${DATABASE_USER:-postgres}" -q; do
  echo "Database is not ready yet. Waiting..."
  sleep 2
done

echo "Database is ready!"

# Run migrations
echo "Running database migrations..."
bin/wc_logs eval "WcLogs.Release.migrate()"

echo "Starting application..."
exec "$@"