# Color Vision Plates — iOS

Native iOS shell for the color vision screening at the repo root.
Same shape as the [What Color Is This?](https://whatcoloristhis.one)
iOS port (`../../whatcolor/ios/`): a WKWebView app that loads the
**bundled** `index.html` + `color-math.js` (no network dependency),
plus the native surface that makes it a real iOS app rather than a
wrapped website — on-device screening history with retest comparison,
a native Settings screen, and the native share sheet.

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
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
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

## App Store assets

- `app-store-listing.md` — every ASC field ready to paste (name,
  subtitle, description, keywords, privacy labels, review notes),
  plus the one manual step: creating the ASC record needs Luke's
  Apple ID + 2FA (no ASC API key on this machine).
- `screenshots/` — captured by `scripts/capture_screenshots.sh`,
  which boots the simulator, pins the 9:41 status bar, drives
  `ScreenshotTest` through a full screening, and exports the
  attachments. iPhone 6.9" (1320×2868) and iPad 13" (2064×2752).

## App Review positioning (Guideline 4.2)

The native surface is real, not decorative: screening history with
retest-over-time comparison lives entirely in native UI, results
arrive over the bridge, the app runs fully offline from bundled
assets, and there are no accounts, ads, analytics, or tracking
(`PrivacyInfo.xcprivacy` declares UserDefaults/CA92.1 only). Review
notes should say exactly that, plus: this is a screening, not a
diagnostic device — the in-app copy repeats the disclaimer on the
test screen, the results page, and the history footer.

## Not done yet

- App Store Connect record (manual, 5 min — steps at the top of
  `app-store-listing.md`), then archive + TestFlight upload.
- Swap the in-app companion CTA href to the What Color Is This? App
  Store URL once it's live (marked `TODO` in `index.html`).
- Device-matrix pass (small phone / Dynamic Island / iPad) before
  submission.
