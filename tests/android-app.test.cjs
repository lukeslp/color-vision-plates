'use strict';
// The page must never show install banners or store buttons inside the
// Android apps. These tests run the page's own detection function and check
// the markup and wrapper settings it depends on.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const { test } = require('node:test');

const root = path.join(__dirname, '..');
const html = fs.readFileSync(path.join(root, 'index.html'), 'utf8');
const twa = JSON.parse(fs.readFileSync(path.join(root, 'android-build/twa-manifest.json'), 'utf8'));

const packagesSource = html.match(/^        var ANDROID_APP_PACKAGES = \[[^\]]*\];/m);
const detectSource = html.match(/^        function detectAndroidApp\([^]*?^        }/m);
assert.ok(packagesSource && detectSource, 'Missing the Android app detection in index.html');
const context = vm.createContext({ URLSearchParams });
vm.runInContext(packagesSource[0] + '\n' + detectSource[0], context);

const PLATES = 'one.whatcoloristhis.plates.twa';
const WHATCOLOR = 'one.whatcoloristhis.twa';

function store(initial = {}) {
  const data = { ...initial };
  return {
    data,
    getItem: key => (key in data ? data[key] : null),
    setItem: (key, value) => { data[key] = String(value); },
  };
}
function blockedStore() {
  return {
    getItem() { throw new Error('storage blocked'); },
    setItem() { throw new Error('storage blocked'); },
  };
}
function detect({ search = '', referrer = '', session = store(), local = store(), standalone = false } = {}) {
  return context.detectAndroidApp(search, referrer, session, local, standalone);
}

test('an ordinary web visit is not treated as the app', () => {
  assert.equal(detect(), false);
  assert.equal(detect({ referrer: 'https://www.google.com/' }), false);
  assert.equal(detect({ search: '?utm_source=share' }), false);
  assert.equal(detect({ standalone: true }), false, 'an installed web app alone is not the Android app');
});

test('the launch marker alone hides the install links, for either app', () => {
  for (const id of [PLATES, WHATCOLOR]) {
    assert.equal(detect({ search: '?android_package=' + id }), true, id);
    assert.equal(detect({ search: '?x=1&android_package=' + id + '&y=2' }), true, id);
  }
});

test('the app referrer alone hides the install links, for either app', () => {
  for (const id of [PLATES, WHATCOLOR]) {
    assert.equal(detect({ referrer: 'android-app://' + id }), true, id);
    assert.equal(detect({ referrer: 'android-app://' + id + '/' }), true, id);
  }
});

test('other packages and look-alike values do not count', () => {
  assert.equal(detect({ search: '?android_package=com.example.other' }), false);
  assert.equal(detect({ search: '?android_package=' }), false);
  assert.equal(detect({ referrer: 'android-app://com.google.android.gm/' }), false);
  assert.equal(detect({ referrer: 'android-app://' + WHATCOLOR + '.evil/' }), false);
  assert.equal(detect({ referrer: 'https://example.com/android-app://' + PLATES }), false);
});

test('a detected launch is remembered for the session', () => {
  const session = store(), local = store();
  assert.equal(detect({ referrer: 'android-app://' + PLATES + '/', session, local }), true);
  // Reload or in-page navigation: no marker, ordinary referrer.
  assert.equal(detect({ referrer: 'https://whatcoloristhis.one/test/', session, local }), true);
  // A different browser session on the same phone is the web again.
  assert.equal(detect({ session: store(), local }), false);
});

test('a new tab opened from inside the What Color app counts when it has no browser chrome', () => {
  const local = store({ 'wc-native-shell': 'android' });
  assert.equal(detect({ referrer: 'https://whatcoloristhis.one/', local, standalone: true }), true);
  assert.equal(detect({ referrer: 'https://whatcoloristhis.one/', local, standalone: false }), false);
});

test('blocked or missing storage never breaks detection', () => {
  const blocked = blockedStore();
  assert.equal(detect({ search: '?android_package=' + PLATES, session: blocked, local: blocked }), true);
  assert.equal(detect({ session: blocked, local: blocked, standalone: true }), false);
  assert.equal(detect({ referrer: 'android-app://' + PLATES, session: null, local: null }), true);
  assert.equal(detect({ session: null, local: null }), false);
});

test('the marker is set in <head>, before anything can paint', () => {
  const head = html.slice(0, html.indexOf('</head>'));
  assert.ok(head.includes('function detectAndroidApp('));
  assert.ok(head.includes("root.setAttribute('data-android-app', '')"));
  assert.match(html, /html\[data-android-app\] \.app-banner,\s*html\[data-android-app\] \.store-link \{ display: none !important; \}/);
});

test('every store or download link on the page is hidden inside the app', () => {
  const stores = /apps\.apple\.com|play\.google\.com|dr\.eamer\.dev\/downloads|testflight\.apple\.com|\.apk\b/;
  const anchors = html.match(/<a\b[^>]*>/g).filter(tag => stores.test(tag));
  assert.ok(anchors.length >= 3, 'expected the banner link and the two store buttons');
  for (const tag of anchors) {
    const inBanner = /class="app-banner__cta"/.test(tag);
    assert.ok(inBanner || /class="[^"]*\bstore-link\b/.test(tag), 'Not hidden in the app: ' + tag);
  }
  // The banner script also refuses to show the banner in the app.
  const bannerScript = html.slice(html.indexOf("var banner = document.getElementById('app-banner')"));
  assert.ok(bannerScript.indexOf("hasAttribute('data-android-app')") < bannerScript.indexOf("classList.add('is-visible')"));
});

test('the Android wrapper launches with the marker and stays in the page scope', () => {
  const launch = new URL(twa.startUrl, 'https://' + twa.host);
  assert.equal(launch.pathname, '/test/');
  assert.equal(launch.searchParams.get('android_package'), twa.packageId);
  assert.equal(twa.packageId, PLATES);
  assert.equal(detect({ search: launch.search }), true);
});

test('the wrapper claims links only on its own host', () => {
  assert.deepEqual(twa.additionalTrustedOrigins, []);
});

test('display-setting names have an Android wording next to the Apple one', () => {
  const apple = html.match(/<span class="os-other">[^<]*<\/span>/g) || [];
  const android = html.match(/<span class="os-android">[^<]*<\/span>/g) || [];
  assert.equal(apple.length, 2);
  assert.equal(android.length, 2);
  for (const span of android) assert.doesNotMatch(span, /Night Shift|True Tone/);
  const visible = html.replace(/<script[^]*?<\/script>|<style[^]*?<\/style>|<!--[^]*?-->/g, '')
    .replace(/<span class="os-other">[^<]*<\/span>/g, '');
  assert.doesNotMatch(visible, /Night Shift|True Tone/, 'Apple setting names outside the Apple-only spans');
});
