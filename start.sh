#!/usr/bin/env bash
# Serve the public screening routes with Gunicorn on loopback.
# No API keys are required. Optional local environment settings may be loaded below.
set -euo pipefail
cd "$(dirname "$0")"

# Load .env if present (local dev); production gets envs from systemd.
if [ -f .env ]; then
  set -o allexport
  # shellcheck disable=SC1091
  source .env
  set +o allexport
fi

exec gunicorn \
  --workers 2 \
  --threads 2 \
  --bind 127.0.0.1:5012 \
  --access-logfile - \
  --error-logfile - \
  --timeout 30 \
  --graceful-timeout 30 \
  api:app
