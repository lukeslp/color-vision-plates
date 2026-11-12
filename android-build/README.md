# Android release

This directory retains the Bubblewrap Trusted Web Activity (TWA) manifest for
Color Vision Plates. Generated Android projects, release artifacts, and signing
material are deliberately ignored. `twa-manifest.json` is the source of truth.

## Release contract

- Package ID: `one.whatcoloristhis.plates.twa`
- Version: `1.0.3` (`versionCode` `5`), target API 36
- Canonical scope: `https://whatcoloristhis.one/test/`
- Digital Asset Links source:
  `../.well-known/assetlinks.json`

`npm run verify` checks the package ID, version, PWA scope, and certificate
fingerprint agreement across the TWA manifest and Digital Asset Links source.
It does not prove the public endpoint is deployed.

## What the wrapper tells the page

- The start URL is `/test/?android_package=one.whatcoloristhis.plates.twa`.
  The page reads that value (and the `android-app://` referrer every launch
  carries) and hides its install banner and store buttons inside the app.
  Google Play does not allow links to installs outside Play, so do not remove
  the marker. `tests/android-app.test.cjs` checks both sides.
- `additionalTrustedOrigins` is empty on purpose. Bubblewrap wants bare host
  names there; the four entries used before 1.0.3 carried a scheme, so Android
  reported them as invalid app-link hosts. Written correctly they would make
  this app offer to open every link on those sites, which it should not.
- `orientation` stays `portrait`, which suits a phone: in landscape the number
  keyboard covers the plate. A Trusted Web Activity has one orientation
  setting for every device, so tablets in landscape used to get a portrait
  column with black bars. Since 1.0.3 `patch-generated-project.mjs` changes
  the generated launcher so screens at least 600dp on their short side are
  free to rotate. Phones keep the lock.

## Reproducible unsigned build

Use the pinned Bubblewrap CLI from the lockfile:

```bash
cd android-build
export JAVA_HOME="$(/usr/libexec/java_home -v 17)" # macOS; use a JDK 17 home elsewhere
npm exec bubblewrap -- updateConfig --jdkPath "$JAVA_HOME"
npm ci
npm run verify
npm exec bubblewrap -- update --skipVersionUpgrade --manifest=./twa-manifest.json
node patch-generated-project.mjs
npm run build:unsigned
```

The unsigned command intentionally skips online PWA validation because it is a
pre-deployment build. Do not use that flag for a signed production candidate.
Bubblewrap regenerates its Android project from `twa-manifest.json`; do not
hand-edit generated files (the patch script is the one place that changes them). The `updateConfig` command persists the JDK path in
Bubblewrap's user-level configuration; it may also request an Android SDK path
if one has not already been configured.

Stage only built APK/AAB artifacts, never a keystore or credentials:

```bash
node stage-release.mjs /absolute/path/to/artifact.apk /absolute/path/to/artifact.aab
shasum -a 256 -c release/SHA256SUMS.txt
```

The ignored `release/` directory contains the renamed artifacts and
`SHA256SUMS.txt`.

## Signed release

Since 1.0.1 the app is signed with its own release key, certificate SHA-256
`F3:3B:8E:5D:F9:51:1E:D7:0A:FE:44:97:4D:A0:3E:2F:35:07:48:51:D4:23:C3:A9:9D:FD:18:C5:BF:95:35:51`.
The keystore named in earlier revisions (`plates-keystore.jks`, certificate
`03:C2:31…`) could not be found in November 2026, so 1.0.1 starts a new signing
lineage. The 1.0.0 test APKs that were handed out were signed with the Android
debug key; anyone who has one must uninstall it once before installing 1.0.1 or
later.

The key and its password are not in this repository. The key lives in the
release toolkit's store and the password in the login Keychain, so the signed
build runs through the toolkit:

```bash
~/workspace/android-release-toolkit/scripts/android-release \
  with-signing --profile color-vision-plates -- android-build/build-signed.sh
```

`build-signed.sh` runs `npm run verify`, regenerates the Android project from
`twa-manifest.json`, runs `patch-generated-project.mjs` (it sets
`targetSdkVersion 36` in the generated `app/build.gradle`, because Bubblewrap
1.24.1 writes 35 and has no manifest field for it, and frees large screens
from the portrait lock; it stops the build if the generated files are not
what it expects), builds the unsigned aligned APK and app bundle with Bubblewrap, signs the
APK with `apksigner` and the bundle with `jarsigner`, and stages
`release/color-vision-plates-<version>.apk` and
`release/color-vision-plates-<version>-<code>.aab` with `SHA256SUMS.txt`. It refuses a debuggable APK, one that does not target API 36, and an APK or
bundle whose certificate is not
the fingerprint in `twa-manifest.json`. The `signingKey` entry in the manifest
is a placeholder; Bubblewrap does not sign this build.

The app opens full screen only when the canonical host's
`/.well-known/assetlinks.json` lists the release certificate for
`one.whatcoloristhis.plates.twa`. Until that file is deployed with the new
fingerprint, Android shows the page in a browser tab with an address bar. The
source file in this repository keeps the earlier fingerprint beside the new one.

The 1.0.1 build used `--skipPwaValidation`, because
`https://whatcoloristhis.one/test/pwa.webmanifest` was not being served on the
day it was built. Serve the PWA manifest and drop that flag before treating a
build as a store candidate.
