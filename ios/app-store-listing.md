# App Store Connect Listing — Color Vision Plates

Drop-in copy for App Store Connect submission. Field names match App Store Connect's UI exactly. Character limits are Apple's hard caps (over = upload error). Same format as `../../whatcolor/app-store-listing.md`.

**Pricing:** Free. No In-App Purchases. No subscriptions. No ads. (Same as the web test. Same as What Color Is This?)

---

## Creating the record (one-time, needs your Apple ID + 2FA)

No App Store Connect API key exists on this machine, so the record is a
5-minute manual step — same dance as whatcolor
(`../../whatcolor/ios/post-enrollment-checklist.md` § 4):

1. The bundle id registers itself the first time you archive with
   automatic signing, or add it at developer.apple.com → Identifiers →
   `one.whatcoloristhis.visiontest` (no capabilities needed — no app
   groups, no associated domains in v1).
2. App Store Connect → My Apps → "+" → New App:
   - Platform: iOS · Name: **Color Vision Plates** · Language: English (U.S.) — done; "Color Vision Test" was taken
   - Bundle ID: `one.whatcoloristhis.visiontest` · SKU: `colorvisiontest-ios-001`
   - Full Access
3. Paste the fields below.

---

## App Information

### Name (30 char max)
```
Color Vision Plates
```
*(19 chars — "Color Vision Test" wasn't available as an App Store
name; the ASC record was created as Color Vision Plates. Bundle id
and SKU are unchanged.)*

### Subtitle (30 char max)
```
14-plate colorblind screening
```
*(29 chars — what it is, how thorough, who it's for, no filler)*

### Bundle ID
`one.whatcoloristhis.visiontest`

### SKU
`colorvisiontest-ios-001`

### Primary Language
English (U.S.)

---

## Pricing & Availability

- **Price Tier:** Free (Tier 0)
- **Availability:** All territories
- **In-App Purchases:** None
- **Subscriptions:** None

---

## Categories

- **Primary Category:** Utilities
- **Secondary Category:** Health & Fitness

*(Rationale: Utilities matches the family — What Color Is This? lives there — and keeps the listing positioned as a tool. Health & Fitness fits the screening angle without claiming the Medical category; Medical invites 5.1.1 device-claim scrutiny that a screening tool with a persistent "not a diagnosis" disclaimer doesn't need to volunteer for.)*

---

## Age Rating

4+ (no objectionable content, no user-generated content, no web access beyond external links opening in Safari)

---

## Description (4000 char max)

```
I'm colorblind. Every "color blind test" app I tried was either a marketing funnel, an ad farm, or scientifically wrong. So I built the one I wanted: the method written down, sources cited, nothing to sign up for.

Color Vision Plates is a 14-plate screening for red-green and blue-yellow color vision differences. It tells you which groups of plates you missed. It does not name a type or a severity, because a phone screening can't establish either.

HOW IT WORKS

• Number plates and shape plates inspired by the Ishihara (1917) and HRR (1954) tests. These are original generated plates, not scans of the clinical sets
• Plates are grouped into red-green, experimental protan-design and deutan-design, blue-yellow, and control sets
• Plate colors are specified in CIELAB and checked with color-vision simulations (Brettel, Viénot & Mollon 1997) and the CIEDE2000 color difference. Those checks describe the math, not what any one person will see
• A gray-patch check before the test starts, because a dimmed or Night-Shifted screen changes what you see. It does not calibrate your screen's colors
• A brightness-contrast control plate. Miss it and the result is marked inconclusive instead of guessing
• Plate order shuffles and dot patterns reroll on every retake

WHAT YOU GET

• A plain result that describes your answers, such as "Several red-green plates missed" or "Most or all plates matched"
• What can affect your answers: display, brightness, color filters, lighting
• A plate-by-plate review of every answer
• Screening history saved on your device, so you can retest over time and compare
• The method, its limits and full citations, one tap away

THE HONEST PART

This is an experimental screening, not a medical diagnosis. Its sensitivity, specificity and subtype accuracy have not been established. Phone screens vary; clinical tests use calibrated printed plates under standardized lighting. Matching every plate does not rule out a color vision difference. The app says this before the test, on your results and in your history, because a screening tool that oversells itself is worse than none. If your results suggest a color vision difference, see an eye care professional.

PRIVACY

No accounts. No tracking. No analytics. No ads. No network calls. The entire test is bundled with the app and runs offline. Your results stay on your device, and you can erase them anytime.

OPEN SOURCE

The app and its plate generator are MIT licensed. You can read exactly how every plate is made.

REFERENCES

Ishihara (1917); Hardy, Rand & Rittler (1954); Brettel, Viénot & Mollon (1997); Viénot, Brettel & Mollon (1999); Sharma, Wu & Dalal (2005) for CIEDE2000 color difference; Birch (2012) on prevalence.

From the maker of What Color Is This?, the camera color-identifier built for colorblind people. About 1 in 12 men and 1 in 200 women have a color vision difference. Most found out by accident.

Made by Luke Steuber. Published by Bridge City Lab LLC.
```
*(~3000 chars as of 1.0.4)*

---

## Keywords (100 char max, comma-separated, NO SPACES between commas)

```
colorblind,colorblindness,ishihara,screening,protan,deutan,tritan,daltonism,CVD,eye,hrr,test
```
*(92 chars. "color", "vision", and "plates" are already in the app name — don't waste keyword chars on them. "test" earns its slot now that the name no longer contains it ("color blind test" is the niche's biggest query). "daltonism" pulls non-English searches; "ishihara" is the highest-intent term.)*

---

## Promotional Text (170 char max — editable WITHOUT app review)

```
Fourteen plates, the method written down, sources cited. An experimental color vision screening built by a colorblind developer. Free, offline, open source.
```
*(158 chars)*

---

## What's New — v1.0.0

```
First release. 14 plates (Ishihara-style numbers + HRR-style shapes), protan/deutan/tritan classification, display calibration check, on-device screening history, full methodology with citations. Free, offline, no accounts, no tracking.
```

---

## Screenshots (6.9" iPhone + 13" iPad, captured by ios/scripts/capture_screenshots.sh)

| # | File | Caption (if framing later) |
|---|------|---------------------------|
| 1 | 01-hero | A real screening, not a marketing funnel |
| 2 | 02-calibration | It checks your screen before it tests your eyes |
| 3 | 03-plate | 14 plates, Ishihara + HRR methodology |
| 4 | 04-results | Plain-English results, type classified |
| 5 | 05-settings | No accounts. Nothing leaves your device |
| 6 | 06-history | Retest over time, compared honestly |

Upload order: results (04) first or second — it's the conversion shot. Suggested order: 01, 04, 03, 02, 06, 05.

---

## App Privacy (nutrition label)

**Data Not Collected.** The app makes no network requests: no analytics, no crash reporting, no accounts. Screening history is stored in UserDefaults on-device only. (`PrivacyInfo.xcprivacy` declares UserDefaults access, reason CA92.1, and nothing else.)

- Privacy Policy URL: `https://whatcoloristhis.one/privacy.html`
  (This repo's own `privacy.html` has also been live at `/test/privacy.html`
  since the 2026-11-10 deploy of the test page.)

---

## URLs

- **Support URL:** `https://lukesteuber.com`
- **Marketing URL:** `https://whatcoloristhis.one/test/`

---

## App Review Information

### Notes for the reviewer

```
Color Vision Plates is a color vision (colorblindness) screening utility built by a colorblind developer.

The app ships fully bundled and operates entirely offline: the 14 screening plates are generated on-device in CIELAB color space; there are no network calls, no account system, no ads, and no tracking (privacy manifest declares UserDefaults only). The web view loads only bundled local assets and is locked to App-Bound Domains; external links open in Safari.

Native iOS surface beyond the screening itself: on-device screening history with retest-over-time comparison (Settings → Screening History), a native Settings screen (About, Privacy, Sources & Licenses), and native share-sheet integration.

This is a screening tool, not a medical device, and it does not claim to diagnose. The "screening, not a medical diagnosis" disclaimer is persistent: shown on the test screen, on every results page, and in the screening history. Results that fail the built-in display-calibration control are reported as inconclusive rather than scored. All methodology is cited in-app (Ishihara 1917; Hardy-Rand-Rittler 1954; Brettel-Viénot-Mollon 1997; Sharma-Wu-Dalal 2005).

The same screening runs on the web at https://whatcoloristhis.one/test/ ; the iOS app adds native iOS integrations. The plates and scoring rules are experimental and have not been clinically validated, and the app says so. Companion app: What Color Is This? (one.whatcoloristhis.ios), same developer.

No demo account needed — there are no accounts. To see a full flow quickly: Start Screening → tap the brighter gray patch → answer the practice plate → answer or skip the 14 plates → results → gear icon (top right) → Screening History.
```

### Contact
- First name: Luke · Last name: Steuber
- Email: luke@lukesteuber.com

---

## Build & upload (when ready)

1. `cd ios && xcodegen generate`
2. Xcode → Product → Archive (scheme ColorVisionPlates, Any iOS Device)
3. Distribute App → App Store Connect → Upload
4. TestFlight processing (~10-30 min), then internal testing
5. Push this listing + screenshots with fastlane (after the record
   exists): `brew install fastlane` once, then `cd ios && fastlane
   upload_listing` — prompts for Apple ID 2FA on first run, caches the
   session. (Don't use system-Ruby bundler: it wants sudo for
   /Library/Ruby/Gems and Ruby 2.6 is EOL.) The metadata files under
   `fastlane/metadata/` mirror this document; edit both together.
6. Attach the build to the 1.0.0 version in ASC and submit.
```
