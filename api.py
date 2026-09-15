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

# Serve only the explicit public routes below, never arbitrary repository files.
app = Flask(__name__, static_folder=None)
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
    # Keep old shared URLs working with the current app icon.
    return send_from_directory('.', 'icon-512.png', mimetype='image/png')


@app.route('/privacy.html')
@app.route('/privacy')
def privacy():
    # App Store privacy-policy URL for the iOS app
    # (https://whatcoloristhis.one/test/privacy.html via Caddy).
    return send_from_directory('.', 'privacy.html')


@app.route('/color-math.js')
def color_math_js():
    return send_from_directory('.', 'color-math.js', mimetype='application/javascript')


@app.route('/icon-512.png', defaults={'filename': 'icon-512.png'})
@app.route('/icon-512-maskable.png', defaults={'filename': 'icon-512-maskable.png'})
def app_icon(filename):
    return send_from_directory('.', filename, mimetype='image/png')


@app.route('/pwa.webmanifest')
def pwa_manifest():
    return send_from_directory('.', 'pwa.webmanifest', mimetype='application/manifest+json')


@app.route('/.well-known/assetlinks.json')
def digital_asset_links():
    return send_from_directory('.well-known', 'assetlinks.json', mimetype='application/json')


@app.route('/health')
def health():
    return jsonify({'status': 'healthy', 'service': 'colorblindness-test', 'timestamp': time.time()})


if __name__ == '__main__':
    print('Colorblindness test server starting on port 5012...')
    app.run(host='127.0.0.1', port=5012, debug=False)
