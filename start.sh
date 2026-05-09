#!/usr/bin/env bash
# start.sh - production entrypoint for the colorblindness test / beta-signup service.
# Replaces the Flask dev server (api.py:__main__) with gunicorn.
#
# Environment variables (RESEND_API_KEY, BETA_ADMIN_KEY) are expected to be set
# by the caller. In production they're baked into the systemd unit at
# /etc/systemd/system/whatcolor-beta.service via Environment= directives. For
# local development, copy .env.example to .env and source it before running.
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
  --bind 0.0.0.0:5012 \
  --access-logfile - \
  --error-logfile - \
  --timeout 30 \
  --graceful-timeout 30 \
  api:app
