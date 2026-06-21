#!/usr/bin/env python3
"""Static server for the colorblindness screening test.

The test is fully client-side; this Flask app only serves the page and
its assets behind Caddy. The former beta-signup API (email collection,
admin export, Resend notifications) was removed 2026-06-09 once the
iOS app shipped — the results page now links straight to the App Store,
web app, and Android APK. Historical signups remain in beta.db
(gitignored, no longer read or written by this code).
"""
import time
from flask import Flask, jsonify, send_from_directory
from flask_cors import CORS

app = Flask(__name__, static_folder='.')
CORS(app, origins=[
    'https://whatcoloristhis.one',
    'https://whatcoloristhat.one',
    'https://whatcolouristhat.com',
    'https://dr.eamer.dev',
    'https://lukesteuber.com',
    'http://localhost:5012',
])


@app.route('/')
def index():
    return send_from_directory('.', 'index.html')


@app.route('/og-beta.png')
@app.route('/og-beta-v2.png')
def og_image():
    # og-beta-v2.png was removed (commit 103c0ac); both routes serve
    # the canonical card so old shares keep resolving.
    return send_from_directory('.', 'og-beta.png', mimetype='image/png')


@app.route('/privacy.html')
@app.route('/privacy')
def privacy():
    # App Store privacy-policy URL for the iOS app
    # (https://whatcoloristhis.one/test/privacy.html via Caddy).
    return send_from_directory('.', 'privacy.html')


@app.route('/color-math.js')
def color_math_js():
    return send_from_directory('.', 'color-math.js', mimetype='application/javascript')


@app.route('/health')
def health():
    return jsonify({'status': 'healthy', 'service': 'colorblindness-test', 'timestamp': time.time()})


if __name__ == '__main__':
    print('Colorblindness test server starting on port 5012...')
    app.run(host='127.0.0.1', port=5012, debug=False)
