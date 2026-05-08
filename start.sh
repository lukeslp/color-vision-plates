#!/usr/bin/env bash
# start.sh — production entrypoint for the What Color beta-signup / Ishihara test service.
# Replaces the Flask dev server (api.py:__main__) with gunicorn for stability + worker recycling.
set -euo pipefail
cd "$(dirname "$0")"

export RESEND_API_KEY='RESEND_API_KEY_REDACTED'
export BETA_ADMIN_KEY='whatcolor-beta-2026'

exec gunicorn \
  --workers 2 \
  --threads 2 \
  --bind 0.0.0.0:5012 \
  --access-logfile - \
  --error-logfile - \
  --timeout 30 \
  --graceful-timeout 30 \
  api:app
