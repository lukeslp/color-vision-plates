# Color Vision Plates — iOS

Native iOS shell for the color vision screening at the repo root.
A WKWebView app loads the **bundled** root `index.html` and
`color-math.js` without a network dependency. Native screens provide
on-device screening history, retest comparison, Settings, and sharing.
No sibling source checkout is required.

- App name: **Color Vision Plates** ("Color Vision Test" was taken on the App Store; bundle id unchanged)
- Bundle id: `one.whatcoloristhis.visiontest`
- Team: Bridge City Lab LLC (`596T7J7FB6`)
- Min iOS: 16.0

## Build

The `.xcodeproj` is generated — edit `project.yml`, never the project
file.

```bash
brew install xcodegen        # once — keep ≥ the version that generated
                             # the committed project (regenerating with
                             # an older xcodegen silently drops newer
                             # build settings; diff before committing)
cd ios
xcodegen generate
xcodebuild -project ColorVisionPlates.xcodeproj -scheme ColorVisionPlates \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Smoke test (drives a full screening, verifies the JS bridge end to end)
xcodebuild -project ColorVisionPlates.xcodeproj -scheme ColorVisionPlates \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:ColorVisionTestUITests/SmokeTest \
  -only-testing:ColorVisionWidgetTests test
```

Web assets are referenced from the repo root via `path: ../index.html`
entries in `project.yml` (`buildPhase: resources`) — one source of
truth, no copies. Editing the web app updates the iOS app on next
build.

## JS bridge contract

The shell injects `window.CVT_NATIVE = true` at document start.
`index.html` checks that flag and:

| Direction | Channel | Purpose |
|---|---|---|
| JS → Swift | `screeningResult` | `showResults()` posts `{type, label, rgFailed, rgTotal, byFailed, byTotal}`; `ResultStore` stamps the date and persists to UserDefaults (`screeningHistory`, capped at 100) |
| JS → Swift | `settings` | The injected gear button opens the native Settings sheet |
| JS → Swift | `share` | The share button posts `{text, url}` → `UIActivityViewController` (`navigator.share`/`clipboard` don't exist in a `file://` WKWebView) |
| native-mode DOM | — | Companion-app card collapses to one link (no TestFlight/APK links — Guideline 2.2); GoatCounter never loads (privacy label: no data collected) |

`navigator.wakeLock` is unavailable in WKWebView; the shell pins
`UIApplication.isIdleTimerDisabled` for its foreground lifetime
instead.

## App icon

Source artwork + derived appearances — `scripts/icon-source.png` is
an Ishihara-style sibling of whatcolor's icon (green/cyan plate dots,
orange/red figure; a hidden triangle where whatcolor hides its
magnifying glass). `scripts/generate_icon.py` fits it to 1024 and
derives the dark appearance (white field → charcoal, dot colors
preserved) and the tinted appearance (luminance-separated mask, since
the plate's chroma-separated dots vanish in naive grayscale — that
being literally what the app tests for). Rerun after replacing the
source art.

## Release assets

`app-store-listing.md`, fastlane metadata, and the checked-in screenshots
are retained release materials from earlier versions. They are not proof
of current store status and may show older result wording. Before another
store submission, reconcile the listing and capture screenshots from the
exact candidate binary. Source preparation alone does not update a store.

`scripts/capture_screenshots.sh` runs the separate `ScreenshotTest` capture
flow. It is not part of the regression command above. Supply the ignored
`fastlane/metadata/review_information/phone_number.txt` locally before an
authorized listing upload; do not commit private review contact details.

## App Review positioning (Guideline 4.2)

The native surface is real, not decorative: screening history with
retest-over-time comparison lives entirely in native UI, results
arrive over the bridge, the app runs fully offline from bundled
assets, and there are no accounts, ads, analytics, or tracking
(`PrivacyInfo.xcprivacy` declares UserDefaults/CA92.1 only). Review
notes should say exactly that, plus: this is a screening, not a
diagnostic device — the in-app copy repeats the disclaimer on the
test screen, the results page, and the history footer.

## Validation boundaries

The root page uses experimental scoring. Internal result IDs are retained
for history compatibility; visible answer summaries do not establish a
diagnosis, subtype, or severity. Simulator checks cover the bridge and
workflow, not physical display accuracy or clinical performance.

A future binary release needs its own device checks, screenshots, metadata
review, and store verification. Choose an available simulator name from
`xcrun simctl list devices available` when running the example commands.
