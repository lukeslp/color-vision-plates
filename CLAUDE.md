# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working in this repository.

## Project

Color Vision Screening Test served at `/test/` on `whatcoloristhis.one`, `whatcoloristhat.one`, `whatcolouristhat.com`, `dr.eamer.dev`, and `lukesteuber.com`. Companion to the [What Color Is This?](https://whatcoloristhis.one) app at `../whatcolor/`. Beta-tester signup feeds into the same SQLite database (`beta.db`).

This is a separate git repo from `../whatcolor/`. Root `git status` will not show changes here.

## Run locally

```bash
pip install -r requirements.txt
python api.py                          # Flask dev server on 0.0.0.0:5012
./start.sh                             # gunicorn, 2 workers (production entrypoint)
```

Production deployment is via `whatcolor-beta.service` (systemd), reverse-proxied by Caddy at `/test/`.

## Architecture

**Two-file core**: `index.html` (~1400 lines, hand-edited, no build step) + `api.py` (Flask, ~150 lines). `color-math.js` is a copy of `../whatcolor/color-math.js` (same Brettel CVD simulation, CIEDE2000, and hex/LAB conversions). Drift is protected by `../whatcolor/tests/parity_test.py`.

The frontend is intentionally a single HTML file (matching the parent whatcolor convention): zero build tooling, one request, trivial to cache offline. Don't introduce a bundler, framework, or component library.

## iOS app (`ios/`)

Standalone iOS app ("Color Vision Test", `one.whatcoloristhis.visiontest`), same shape as `../whatcolor/ios/`: a WKWebView shell that loads the **bundled** root `index.html` + `color-math.js` (referenced from the repo root in `project.yml`, never copied), plus native screening history, Settings, and share sheet. The `.xcodeproj` is generated — edit `ios/project.yml` and rerun `xcodegen generate`; never hand-edit the project file.

The shell injects `window.CVT_NATIVE = true` at document start. Every native behavior in `index.html` is gated on that flag: results post to the `screeningResult` message handler, the share button posts to `share` (no `navigator.share`/`clipboard` in a `file://` WKWebView), the companion-app card collapses to a single link, GoatCounter never loads, and a settings gear posts to `settings`. When touching `showResults`, the share handler, or the CTA card, keep those branches working — `ios/ColorVisionTestUITests/SmokeTest.swift` drives a full screening through the bridge and fails if the contract breaks:

```bash
cd ios && xcodegen generate && xcodebuild -project ColorVisionTest.xcodeproj \
  -scheme ColorVisionTest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

See `ios/README.md` for the full bridge contract and App Review notes.

## Plate science (the load-bearing part)

The 14 plates are defined in the `PLATES` array in `index.html`. Each plate has:
- `type`: `'number'` or `'shape'`
- `value`: the digit or shape name
- `correct`: matching value (lowercased on submit)
- `tests`: array of CVD types this plate screens for (`'protan'`, `'deutan'`, `'tritan'`, or `[]` for control)
- `fg` and `bg`: CIELAB triples + per-channel noise ranges (`L`, `LR`, `a`, `aR`, `b`, `bR`)
- `nearMisses`: array of acceptable partial-credit answers (e.g., "0" for "6" under degraded contrast)
- `seed`: PRNG seed for deterministic dot placement

The plate verifier (`verifyPlates` in `index.html`, runs at module load) simulates each fg/bg pair under Brettel's protan/deutan/tritan matrices and asserts:
- ΔE(fg, bg) > 12 in normal vision (visible to trichromats)
- ΔE(fg, bg) < 10 in target-dichromat-simulated space (figure invisible to that type)

Results are exposed at `window.__PLATE_VERIFICATION` for debugging. V1 is in warn mode; tighten thresholds in a future revision after collecting field data.

**When editing PLATES, you must:**
1. Re-run the verifier in browser console: confirm 0 issues
2. Regenerate the `BETA_PLATES` snapshot in `../whatcolor/tests/parity_test.py` (see "Parity test" below)
3. Run `cd ../whatcolor && python tests/parity_test.py`: must pass

**Color science conventions:**
- All colors specified in CIELAB. HSL is forbidden in plate definitions: HSL "lightness" is geometric, not perceptual, and equal HSL L for red and green produces ~20 L\* of luminance leak.
- FG and BG always share `L` and `LR`. Any luminance difference between figure and background is a leak that compromises the test.
- Red-green plates separate on `a`. Blue-yellow plates separate on the tritan confusion line, which is NOT the b\* axis (the original v1 implementation made that mistake; verifier exposed it; rewrite uses Brettel-line pairs found via grid search).

## Scoring cascade

`scoreResults` in `index.html` is a 12-rule cascade evaluated in order, first match wins. The order matters:
1. Control plate fail comes first (display issue invalidates everything else).
2. All-near-miss check before any threshold rule (otherwise an anomalous trichromat with 4 near-miss failures gets misclassified as dichromat).
3. Protan-type and deutan-type signals before lump red-green (the new classifier plates carry strong signal; using them is the whole point).
4. Mixed classifier (both protan-only AND deutan-only fail) before generic red-green (this is unusual and worth a distinct label).

The `vision_type` strings produced are documented in `api.py:90` (the column comment). Adding a new branch requires updating that comment.

## Parity test (mandatory before merge)

Plate science is parity-tested:

```bash
cd /home/coolhand/html/whatcolor && python tests/parity_test.py
```

The `BETA_PLATES` constant in `parity_test.py` is a snapshot of beta's plate hex codes (computed from the LAB triples via beta's `labToHex`). When PLATES change, regenerate via:

```bash
cd /home/coolhand/html/beta && node -e "
const fs = require('fs');
const html = fs.readFileSync('index.html', 'utf8');
function labToHex(L, a, b) {
  const delta = 6/29, k = 3*delta*delta;
  const fInv = t => t > delta ? t*t*t : k*(t - 4/29);
  const fy = (L+16)/116;
  const X = 0.95047*fInv(fy+a/500), Y = 1.00000*fInv(fy), Z = 1.08883*fInv(fy-b/200);
  const rl = 3.2404542*X - 1.5371385*Y - 0.4985314*Z;
  const gl = -0.9692660*X + 1.8760108*Y + 0.0415560*Z;
  const bl = 0.0556434*X - 0.2040259*Y + 1.0572252*Z;
  const g = c => { c = Math.max(0, Math.min(1, c)); return c <= 0.0031308 ? 12.92*c : 1.055*Math.pow(c, 1/2.4) - 0.055; };
  const h = v => { const n = Math.round(Math.max(0, Math.min(255, v*255))); return (n<16?'0':'') + n.toString(16); };
  return '#' + h(g(rl)) + h(g(gl)) + h(g(bl));
}
const m = html.match(/var PLATES = \[[\s\S]*?\n        \];/);
eval(m[0]);
console.log(JSON.stringify(PLATES.map((p,i)=>({index:i+1,value:p.value,tests:p.tests,fg_hex:labToHex(p.fg.L,p.fg.a,p.fg.b),bg_hex:labToHex(p.bg.L,p.bg.a,p.bg.b)})),null,2));
"
```

Paste the JSON into the `BETA_PLATES` list. Run the parity test. Commit both changes together.

## API surface

| Endpoint | Purpose |
|---|---|
| `GET /` | Serves `index.html` |
| `GET /color-math.js` | Static JS bundle (explicit route since Flask `static_folder='.'` doesn't auto-serve at root with the existing index handler) |
| `GET /og-beta.png`, `GET /og-beta-v2.png` | Open Graph card image |
| `GET /health` | Liveness check (used by `service_manager.py`) |
| `POST /api/signup` | Beta tester signup. Body: `{email, vision_type, test_results, calibration_warning?}` |
| `GET /api/signup/count` | Public signup count |
| `GET /api/admin/signups` | CSV export, gated by `BETA_ADMIN_KEY` |

CORS is allowlisted to: `whatcoloristhis.one`, `whatcoloristhat.one`, `whatcolouristhat.com`, `dr.eamer.dev`, `lukesteuber.com`, and `localhost:5012`.

## Service management

The service is registered in the parent monorepo's `service_manager.py` as `beta-signup` on port 5012. It uses systemd (the `coca`-style exception, not the default `sm`-managed pattern):

```bash
sudo systemctl status whatcolor-beta.service
sudo systemctl restart whatcolor-beta.service
sudo journalctl -u whatcolor-beta -f
```

The unit lives at `/etc/systemd/system/whatcolor-beta.service`. `Restart=always` so it self-recovers from crashes. Environment variables (`RESEND_API_KEY`, `BETA_ADMIN_KEY`) are baked into the unit.

## Caddy routing

Reverse-proxy routes at `/test/` on five domains. The relevant Caddyfile blocks are in `/etc/caddy/Caddyfile`. After any route change:

```bash
sudo caddy validate --config /etc/caddy/Caddyfile
sudo systemctl reload caddy
```

A bad config locks all routed services out at once: validate before reload.

## Conventions

- **Single HTML file is intentional** (matches whatcolor): no bundler, no framework, no component library. Inline new scripts.
- **Pure-JS plate verifier is intentional**: Brettel + CIEDE2000 are imported from `color-math.js`, plate definitions stay inline in `index.html` for grep-ability.
- **Verifier in warn mode for v1**: the existing red-green plates pass at the threshold-10 boundary. After plate redesign for stricter thresholds, switch to throw mode so a broken plate fails CI.
- **No new dependencies** without justification: current Python deps are Flask + flask-cors + requests + python-dotenv. Resist the urge to add ORMs, JS frameworks, or test runners.
- **Privacy-first**: only PII stored is email + vision_type + test answers + IP + UA in SQLite. Don't expand. GoatCounter handles web analytics on the parent whatcolor domain, not here.
- **Never claim diagnostic accuracy**: this is a screener. The disclaimer "Screening tool, not a clinical diagnosis" is persistent below the progress bar AND in the results page; both must stay.

## Credit

Luke Steuber (luke@lukesteuber.com). Use first person ("I") in documentation. Don't credit Claude or AI in commits or content.
