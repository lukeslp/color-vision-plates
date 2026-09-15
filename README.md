# Color Vision Plates

An open-source colorblindness test with 14 original colored-dot plates, published color-science references, and reproducible software tests. Numbers and shapes are generated in your browser, and your answers stay on your device.

**[Try Color Vision Plates](https://whatcoloristhis.one/test/)** · [Read the methods](#how-it-works) · [Run the checks](#verify-changes)

I built this screening as a companion to [What Color Is This?](https://whatcoloristhis.one). That color-identification app is a separate project. This repository contains Color Vision Plates: the screening, its native iOS app and widget, and Android build configuration.

## What backs it up

- **Original plates.** The code generates numbers and shapes from CIELAB color specifications. Every plate's colors, answer, and design group are available to inspect.
- **Published methods.** Color calculations use CIEDE2000 and color-vision simulation methods discussed in the [references](#references). The documentation explains how those methods are used and where the approximations matter.
- **Reproducible checks.** The test suite checks color differences against 34 published reference pairs, verifies all 14 plate definitions, and exercises scoring and server behavior. You can run it locally without another repository or an account.

**This is a screening tool, not a clinical diagnosis.** Its plates and scoring rules have not been clinically validated: sensitivity, specificity, subtype accuracy, and severity assessment have not been established. Matching every plate does not rule out a color vision difference. An eye care professional can provide a clinical assessment.

## Run locally

Python 3 and the dependencies below are sufficient. No private sibling repository, account, API key, or JavaScript build step is required.

```sh
python3 -m venv .venv
. .venv/bin/activate
python -m pip install -r requirements.txt
python api.py
```

Open **http://127.0.0.1:5012/**. The Flask server serves an explicit set of public assets and `/health`. For a local Gunicorn process, run `./start.sh` from the same environment. Keep databases, credentials, and other private files outside any public static document root.

## Verify changes

With Node.js and the Python environment above:

```sh
node --test tests/*.test.cjs
python -m unittest discover -s tests -p 'test_*.py'
```

These checks cover numerical fixtures, plate definitions and the existing simulation verifier, scoring rules, and the static-server route boundary. They run from this repository alone. Arithmetic and simulation consistency are engineering checks; they do not validate clinical performance.

For browser changes, run the full sequence: gray-patch check, practice plate, all 14 scored plates, results, and retake. Check keyboard operation and a narrow viewport. Changes to the shared page also affect the bundled iOS application; its native smoke tests cover the history bridge and retake flow. See [iOS instructions](ios/README.md).

## How it works

Plates are rendered at runtime from CIELAB foreground/background specifications and seeded dot positions. They use numbers and geometric shapes inspired by Ishihara and HRR, rather than scans of those clinical plate sets.

| Count | Design group |
|---|---|
| 1 | Brightness-contrast control |
| 5 | General red-green |
| 2 | Experimental protan-design |
| 2 | Experimental deutan-design |
| 4 | Blue-yellow |

`PLATES` and `scoreResults` are in `index.html`. All 14 scored plates run. The control stays first; the remaining order is shuffled. The result summarizes answers using ordered heuristic rules. Existing internal identifiers such as `protan`, `normal`, and `mild-tritan` are retained for native history and companion-app compatibility; they are not diagnoses or validated severity categories.

The gray-patch exercise checks visibility of grayscale differences. It cannot calibrate screen colors or detect all display filters. Display rendering, lighting, viewing distance, input, and number recognition can affect answers.

Retakes change dot positions and presentation order, but keep the same answers. Familiarity and answer memorization can therefore affect later attempts.

### Color mathematics

`color-math.js` contains Luke Steuber's JavaScript implementation shared with What Color, including sRGB/CIELAB conversion, CIEDE2000, and single-plane color-vision simulations. This repository includes the code needed for its own screening and tests.

The page's `verifyPlates` checks color distances within that implementation and exposes `window.__PLATE_VERIFICATION`. Its thresholds are project heuristics. Viénot, Brettel, and Mollon (1999) describe protan/deutan display simulations; that paper does not validate this screening or its approximate tritan matrix. None of these simulation checks establishes which figures a person can see.

## Privacy

The screening runs in the browser. Answers are not submitted to the Flask server. After a completed run, the page stores the result category, label, and timestamp in local storage under `whatcolor_test_result`, allowing the companion app on the same origin to read it. The Android banner stores its dismissal locally. The iOS shell stores screening history on the device through its native bridge.

The current web page loads pageview analytics from `stats.dr.eamer.dev`. The bundled iOS path disables analytics; the page uses local system fonts. Sharing is initiated by the user. Server access logs can record page requests. The former signup API has been removed; no signup database is required or included in the source release.

## Source map

| Path | Purpose |
|---|---|
| `index.html` | Page, plate rendering, answer grouping, native bridge |
| `color-math.js` | Color conversion, simulation, and difference calculations |
| `api.py`, `start.sh` | Optional Flask/Gunicorn static hosting |
| `tests/` | Standalone numerical, scoring, and server checks |
| `ios/` | Native app, history, widget, and tests; bundles the root page |
| `android-build/` | Bubblewrap TWA configuration and release checks |
| `pwa.webmanifest`, `.well-known/assetlinks.json` | Hosted Android identity and origin association |
| `privacy.html` | Hosted privacy page |

The Android TWA loads the hosted site. Building your own distribution requires your own application identity, signing material, and origin association. See [Android build instructions](android-build/README.md). Source availability does not describe current store approval or device-test status.

## Contributing

Keep the page dependency-light: no bundler or framework is required. Preserve the screening limitation on both the test and results screens. Include reproducible evidence for changes to color math or scoring, and distinguish a numerical test from evaluation with participants. Never commit signup records, local configuration, signing credentials, or personal review information.

## References

- [Brettel, Viénot & Mollon (1997), *Computerized simulation of color appearance for dichromats*](https://vision.psychol.cam.ac.uk/jdmollon/papers/Dichromat_simulation.pdf).
- [Viénot, Brettel & Mollon (1999), *Digital video colourmaps for checking the legibility of displays by dichromats*](https://vision.psychol.cam.ac.uk/jdmollon/papers/colourmaps.pdf).
- Sharma, Wu & Dalal (2005), *The CIEDE2000 color-difference formula: implementation notes, supplementary test data, and mathematical observations*. Color Research & Application 30(1), 21–30.
- Ishihara (1917), *Tests for Colour-Blindness*, and Hardy, Rand & Rittler (1954), *HRR Pseudoisochromatic Plates*: historical inspiration for numbers and shapes, not a claim of equivalent performance.
- [National Eye Institute: testing for color vision deficiency](https://www.nei.nih.gov/eye-health-information/eye-conditions-and-diseases/color-blindness/testing-color-vision-deficiency).

## Author and license

Luke Steuber — [lukesteuber.com](https://lukesteuber.com).

Original code is available under the [MIT License](LICENSE). See [third-party notices](THIRD_PARTY_NOTICES.md) for the Feather Settings icon. Research citations identify methods and inspiration; they do not relicense the cited publications or clinical plate collections.
