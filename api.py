#!/usr/bin/env python3
"""Beta Signup API for What Color Is This? — collects tester emails with colorblind test results"""
import csv
import io
import json
import os
import re
import sqlite3
import time
from datetime import datetime
from flask import Flask, jsonify, request, send_from_directory
from flask_cors import CORS
import requests

app = Flask(__name__, static_folder='.')
CORS(app, origins=[
    'https://whatcoloristhis.one',
    'https://whatcoloristhat.one',
    'https://whatcolouristhat.com',
    'https://dr.eamer.dev',
    'https://lukesteuber.com',
    'http://localhost:5012',
])

DB_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'beta.db')
RESEND_API_KEY = os.environ.get('RESEND_API_KEY', '')
NOTIFY_EMAIL = 'luke@lukesteuber.com'
ADMIN_KEY = os.environ.get('BETA_ADMIN_KEY', '')

EMAIL_RE = re.compile(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')


def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    conn = get_db()
    conn.execute('''
        CREATE TABLE IF NOT EXISTS beta_signups (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT NOT NULL UNIQUE,
            vision_type TEXT,
            test_results TEXT,
            ip_address TEXT,
            user_agent TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    conn.commit()
    conn.close()


init_db()


@app.route('/')
def index():
    return send_from_directory('.', 'index.html')


@app.route('/og-beta.png')
@app.route('/og-beta-v2.png')
def og_image():
    return send_from_directory('.', 'og-beta-v2.png', mimetype='image/png')


@app.route('/health')
def health():
    return jsonify({'status': 'healthy', 'service': 'beta-signup', 'timestamp': time.time()})


@app.route('/api/signup', methods=['POST'])
def signup():
    data = request.get_json()
    if not data or not data.get('email'):
        return jsonify({'error': 'Email is required'}), 400

    email = data['email'].strip().lower()
    if not EMAIL_RE.match(email):
        return jsonify({'error': 'Invalid email address'}), 400

    vision_type = data.get('vision_type', 'skipped')
    test_results = json.dumps(data.get('test_results', []))
    ip_address = request.headers.get('X-Forwarded-For', request.remote_addr)
    user_agent = request.headers.get('User-Agent', '')

    conn = get_db()
    try:
        conn.execute(
            'INSERT INTO beta_signups (email, vision_type, test_results, ip_address, user_agent) VALUES (?, ?, ?, ?, ?)',
            (email, vision_type, test_results, ip_address, user_agent)
        )
        conn.commit()
    except sqlite3.IntegrityError:
        conn.close()
        return jsonify({'error': 'already_signed_up', 'message': "You're already signed up!"}), 409
    conn.close()

    # Send notification email
    notify_signup(email, vision_type)

    return jsonify({'success': True, 'message': "You're in! We'll email you when the beta is ready."})


@app.route('/api/signup/count')
def signup_count():
    conn = get_db()
    count = conn.execute('SELECT COUNT(*) FROM beta_signups').fetchone()[0]
    conn.close()
    return jsonify({'count': count})


@app.route('/api/admin/signups')
def admin_signups():
    key = request.args.get('key', '')
    if key != ADMIN_KEY:
        return jsonify({'error': 'Unauthorized'}), 401

    conn = get_db()
    rows = conn.execute('SELECT * FROM beta_signups ORDER BY created_at DESC').fetchall()
    conn.close()

    signups = [dict(row) for row in rows]

    if request.args.get('format') == 'csv':
        output = io.StringIO()
        if signups:
            writer = csv.DictWriter(output, fieldnames=signups[0].keys())
            writer.writeheader()
            writer.writerows(signups)
        return output.getvalue(), 200, {'Content-Type': 'text/csv', 'Content-Disposition': 'attachment; filename=beta-signups.csv'}

    return jsonify({'signups': signups, 'count': len(signups)})


def notify_signup(email, vision_type):
    try:
        requests.post(
            'https://api.resend.com/emails',
            headers={'Authorization': f'Bearer {RESEND_API_KEY}'},
            json={
                'from': 'Beta Signups <api@dr.eamer.dev>',
                'to': [NOTIFY_EMAIL],
                'subject': f'Beta Signup: {email} ({vision_type})',
                'text': f'New beta tester signup!\n\nEmail: {email}\nVision type: {vision_type}\nTime: {datetime.now().isoformat()}',
            },
            timeout=10
        )
    except Exception:
        pass  # Don't fail the signup if notification fails


if __name__ == '__main__':
    print('Beta Signup API starting on port 5012...')
    app.run(host='0.0.0.0', port=5012, debug=False)
