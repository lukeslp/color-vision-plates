#!/usr/bin/env bash
# Build the release-signed Color Vision Plates APK (direct download) and app
# bundle (Google Play).
#
# Bubblewrap builds the unsigned, aligned APK from twa-manifest.json; this
# script then signs it with apksigner. The signing values come from the
# environment, so run it through the release toolkit, which reads them from
# the login Keychain:
#
#   ~/workspace/android-release-toolkit/scripts/android-release \
#     with-signing --profile color-vision-plates -- android-build/build-signed.sh
#
# Needs `npm ci` and a Bubblewrap user config that names a JDK 17 and an
# Android SDK with build-tools 34.0.0 (see README.md).
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${here}"

for name in COLOR_VISION_PLATES_RELEASE_STORE_FILE COLOR_VISION_PLATES_RELEASE_STORE_PASSWORD \
            COLOR_VISION_PLATES_RELEASE_KEY_ALIAS COLOR_VISION_PLATES_RELEASE_KEY_PASSWORD; do
  if [[ -z "${!name:-}" ]]; then
    echo "Missing ${name}. Run this script through the toolkit's with-signing command." >&2
    exit 1
  fi
done

config="${HOME}/.bubblewrap/config.json"
sdk="$(node -e 'console.log(JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")).androidSdkPath)' "${config}")"
jdk="$(node -e 'console.log(JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")).jdkPath)' "${config}")"
build_tools="${sdk}/build-tools/34.0.0"
if [[ -d "${jdk}/Contents/Home" ]]; then jdk="${jdk}/Contents/Home"; fi
export JAVA_HOME="${jdk}" PATH="${jdk}/bin:${PATH}"

npm run -s verify
# Regenerate the Android project from the manifest, then build without signing.
npm exec bubblewrap -- update --skipVersionUpgrade --manifest=./twa-manifest.json </dev/null
# Two things Bubblewrap 1.24.1 has no manifest field for: target API 36
# (Google Play needs it) and letting tablets rotate while phones stay in
# portrait. The script stops the build if the generated files are not what it
# expects.
node patch-generated-project.mjs
npm run -s build:unsigned </dev/null

unsigned="app-release-unsigned-aligned.apk"
version_name="$(node -e 'console.log(JSON.parse(require("fs").readFileSync("twa-manifest.json","utf8")).appVersionName)')"
mkdir -p release
find release -maxdepth 1 -type f -delete
apk="release/color-vision-plates-${version_name}.apk"
# Passwords are read from the environment by name and never appear in argv.
"${build_tools}/apksigner" sign \
  --ks "${COLOR_VISION_PLATES_RELEASE_STORE_FILE}" \
  --ks-key-alias "${COLOR_VISION_PLATES_RELEASE_KEY_ALIAS}" \
  --ks-pass env:COLOR_VISION_PLATES_RELEASE_STORE_PASSWORD \
  --key-pass env:COLOR_VISION_PLATES_RELEASE_KEY_PASSWORD \
  --out "${apk}" "${unsigned}"
rm -f "${apk}.idsig"

badging="$("${build_tools}/aapt" dump badging "${apk}")"
if grep -q '^application-debuggable' <<<"${badging}"; then
  echo "The release APK is debuggable; refusing to stage it." >&2
  exit 1
fi
certificate="$("${build_tools}/apksigner" verify --print-certs "${apk}" \
  | sed -n 's/^Signer #1 certificate SHA-256 digest: //p')"
expected="$(node -e 'const m=JSON.parse(require("fs").readFileSync("twa-manifest.json","utf8"));console.log(m.fingerprints.find(f=>f.name==="assetlinks").value.replace(/:/g,"").toLowerCase())')"
if [[ "${certificate}" != "${expected}" ]]; then
  echo "The APK's certificate is not the one twa-manifest.json and Asset Links name." >&2
  exit 1
fi
target_sdk="$(sed -n "s/^targetSdkVersion:'\\([0-9]*\\)'.*/\\1/p" <<<"${badging}")"
if [[ "${target_sdk}" != "36" ]]; then
  echo "The release APK targets API ${target_sdk}, not 36; refusing to stage it." >&2
  exit 1
fi

# The same Gradle run also leaves an unsigned app bundle, which is what Google
# Play takes. Sign it with the same key (jarsigner; bundles have no v2 scheme).
version_code="$(node -e 'console.log(JSON.parse(require("fs").readFileSync("twa-manifest.json","utf8")).appVersionCode)')"
aab="release/color-vision-plates-${version_name}-${version_code}.aab"
cp app/build/outputs/bundle/release/app-release.aab "${aab}"
jarsigner -keystore "${COLOR_VISION_PLATES_RELEASE_STORE_FILE}" \
  -storepass:env COLOR_VISION_PLATES_RELEASE_STORE_PASSWORD \
  -keypass:env COLOR_VISION_PLATES_RELEASE_KEY_PASSWORD \
  "${aab}" "${COLOR_VISION_PLATES_RELEASE_KEY_ALIAS}" >/dev/null
bundle_certificate="$(keytool -printcert -jarfile "${aab}" \
  | sed -n 's/^.*SHA256: //p' | head -1 | tr -d ':' | tr 'A-F' 'a-f')"
if [[ "${bundle_certificate}" != "${expected}" ]]; then
  echo "The bundle's certificate is not the one twa-manifest.json and Asset Links name." >&2
  exit 1
fi
(cd release && shasum -a 256 "$(basename "${apk}")" "$(basename "${aab}")" > SHA256SUMS.txt)
printf 'Release certificate SHA-256: %s\n' "${certificate}" > release/RELEASE-CERTIFICATE.txt
echo "Signed Color Vision Plates ${version_name} staged in ${here}/release."
