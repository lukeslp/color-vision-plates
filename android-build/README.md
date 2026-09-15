# Android release

This directory retains the Bubblewrap Trusted Web Activity (TWA) manifest for
Color Vision Plates. Generated Android projects, release artifacts, and signing
material are deliberately ignored. `twa-manifest.json` is the source of truth.

## Release contract

- Package ID: `one.whatcoloristhis.plates.twa`
- Version: `1.0.0` (`versionCode` `1`)
- Canonical scope: `https://whatcoloristhis.one/test/`
- Digital Asset Links source:
  `../.well-known/assetlinks.json`

`npm run verify` checks the package ID, version, PWA scope, and certificate
fingerprint agreement across the TWA manifest and Digital Asset Links source.
It does not prove the public endpoint is deployed.

Before any signed release, the canonical host must serve both endpoints with
successful HTTPS responses and without redirects:

```bash
curl --fail --location https://whatcoloristhis.one/test/pwa.webmanifest
curl --fail --location https://whatcoloristhis.one/.well-known/assetlinks.json
```

The PWA manifest is served by this Flask application at `/test/pwa.webmanifest`.
Digital Asset Links is a required origin-root path, so the production proxy or
canonical web host must route `/.well-known/assetlinks.json` to this file. It
cannot be satisfied by a file only at `/test/.well-known/assetlinks.json`.

## Reproducible unsigned build

Use the pinned Bubblewrap CLI from the lockfile:

```bash
cd android-build
export JAVA_HOME="$(/usr/libexec/java_home -v 17)" # macOS; use a JDK 17 home elsewhere
npm exec bubblewrap -- updateConfig --jdkPath "$JAVA_HOME"
npm ci
npm run verify
npm run build:unsigned
```

The unsigned command intentionally skips online PWA validation because it is a
pre-deployment build. Do not use that flag for a signed production candidate.
Bubblewrap regenerates its Android project from `twa-manifest.json`; do not
hand-edit generated files. The `updateConfig` command persists the JDK path in
Bubblewrap's user-level configuration; it may also request an Android SDK path
if one has not already been configured.

Stage only built APK/AAB artifacts, never a keystore or credentials:

```bash
node stage-release.mjs /absolute/path/to/artifact.apk /absolute/path/to/artifact.aab
shasum -a 256 -c release/SHA256SUMS.txt
```

The ignored `release/` directory contains the renamed artifacts and
`SHA256SUMS.txt`.

## Signed-release blocker

The retained manifest intentionally refers to `./plates-keystore.jks` with
alias `plates`, but no keystore is present in this checkout or the documented
local backup location. A signed release cannot be created or verified until
the existing release keystore is restored at that path and can be opened using
the existing alias. Never add the keystore or passwords to this repository,
scripts, environment files, logs, or release staging.

Once the keystore is available and the public PWA manifest plus Digital Asset
Links endpoint have been deployed and verified, run Bubblewrap without
`--skipSigning` or `--skipPwaValidation`; allow it to obtain credentials
interactively from the established local secret store.
