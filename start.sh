#!/bin/bash
cd /home/coolhand/html/beta
export RESEND_API_KEY='RESEND_API_KEY_REDACTED'
export BETA_ADMIN_KEY='whatcolor-beta-2026'
exec python3 api.py
