/**
 * File Purpose: Validates the Android TWA, PWA, and Digital Asset Links release contract.
 * Primary Functions: Read JSON metadata, compare package/version/fingerprint values, and fail on drift.
 * Inputs and Outputs: Reads tracked release JSON; writes a concise validation result to stdout.
 */

import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const ROOT = resolve(import.meta.dirname, '..');
const EXPECTED = Object.freeze({
  packageId: 'one.whatcoloristhis.plates.twa',
  versionName: '1.0.2',
  versionCode: 4,
  startUrl: '/test/',
  scope: '/test/',
  fingerprint: 'F3:3B:8E:5D:F9:51:1E:D7:0A:FE:44:97:4D:A0:3E:2F:35:07:48:51:D4:23:C3:A9:9D:FD:18:C5:BF:95:35:51',
});

function readJson(path) {
  return JSON.parse(readFileSync(path, 'utf8'));
}

function assertEqual(label, actual, expected) {
  if (actual !== expected) {
    throw new Error(`${label} must be ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  }
}

const twa = readJson(resolve(import.meta.dirname, 'twa-manifest.json'));
const pwa = readJson(resolve(ROOT, 'pwa.webmanifest'));
const assetLinks = readJson(resolve(ROOT, '.well-known', 'assetlinks.json'));

assertEqual('TWA package ID', twa.packageId, EXPECTED.packageId);
assertEqual('TWA version name', twa.appVersionName, EXPECTED.versionName);
assertEqual('TWA version code', twa.appVersionCode, EXPECTED.versionCode);
assertEqual('TWA start URL', twa.startUrl, EXPECTED.startUrl);
assertEqual('TWA full scope URL', twa.fullScopeUrl, 'https://whatcoloristhis.one/test/');
assertEqual('PWA ID', pwa.id, EXPECTED.startUrl);
assertEqual('PWA start URL', pwa.start_url, EXPECTED.startUrl);
assertEqual('PWA scope', pwa.scope, EXPECTED.scope);
assertEqual('PWA display mode', pwa.display, 'standalone');

const twaFingerprint = twa.fingerprints?.find(({ name }) => name === 'assetlinks')?.value;
assertEqual('TWA asset-links fingerprint', twaFingerprint, EXPECTED.fingerprint);

const assetLink = assetLinks.find(({ target }) => target?.package_name === EXPECTED.packageId);
if (!assetLink) {
  throw new Error(`Digital Asset Links entry missing for ${EXPECTED.packageId}`);
}
if (!assetLink.relation?.includes('delegate_permission/common.handle_all_urls')) {
  throw new Error('Digital Asset Links relation delegate_permission/common.handle_all_urls is missing');
}
if (!assetLink.target.sha256_cert_fingerprints?.includes(EXPECTED.fingerprint)) {
  throw new Error('Digital Asset Links fingerprint does not match the TWA manifest');
}

console.log(`Release metadata verified for ${EXPECTED.packageId} v${EXPECTED.versionName} (${EXPECTED.versionCode}).`);
