# Color Vision Screening Test

A 14-plate web-based color vision screener served at [whatcoloristhis.one/test/](https://whatcoloristhis.one/test/), [whatcoloristhat.one/test/](https://whatcoloristhat.one/test/), [whatcolouristhat.com/test/](https://whatcolouristhat.com/test/), [dr.eamer.dev/test/](https://dr.eamer.dev/test/), and [lukesteuber.com/test/](https://lukesteuber.com/test/).

I built this as the companion screener for [What Color Is This?](https://github.com/lukeslp/whatcolor): if you're going to use a colorblindness-focused color identification app, you probably want to know which kind of color vision you have, and you probably don't want to pay $30 for an Ishihara plate book to find out.

## What it is

A 14-plate hybrid screening influenced by Ishihara (1917) and HRR (1954), with protan-vs-deutan classifier plates derived from the Viénot-Brettel-Mollon (1999) single-plane dichromacy simulation. Coverage scope mirrors HRR (red-green screen + protan/deutan separation + tritan + control); plate count is closer to abridged Ishihara.

It is a screening tool, not a clinical diagnosis. A clinical exam (anomaloscope, CAD test, formal HRR with calibrated plates) will give a more precise answer.

## What it tests

| Plates | Role | Method |
|---|---|---|
| 1 | Control (luminance contrast) | L\* difference, visible to everyone |
| 5 | Red-green screening | a\*-axis CIELAB pairs, mix of numbers and HRR-style shapes |
| 2 | Protan-only classifier | Simulation-validated near-invisible to protans, visible to deutans |
| 2 | Deutan-only classifier | Simulation-validated near-invisible to deutans, visible to protans |
| 4 | Tritan | Color pairs that map near-identically under tritan simulation |

A pre-test gray-ramp calibration probe runs first to catch dim or low-contrast displays (it is achromatic, so it cannot detect Night Shift or blue-light filters — those get a text warning instead). A demo plate teaches the input mechanic before scoring starts.

## Why the plates are different from a typical web Ishihara

Most web-based "colorblindness tests" reuse scanned Ishihara plates, which is both copyright-questionable and color-inaccurate (display calibration varies enough that scanned ink coordinates do not survive). I generate the plates at runtime from CIELAB specifications and validate every plate against the Viénot-Brettel-Mollon 1999 single-plane dichromacy simulation before it ships (the widely-implemented simplification of Brettel et al. 1997; its known weak spot is the tritan case, which is one reason the tritan result copy hedges on display factors). The verifier (`verifyPlates` in `index.html`) runs at module load and surfaces any plate that leaks more than 10 ΔE under simulation for a target dichromat type. The original v1 implementation had blue-yellow plates that leaked 26-34 ΔE in tritan-simulated space (a tritan could see the figure clearly): the verifier flagged this and the redesigned plates drop the leak to under 1 ΔE.

The protan-only and deutan-only classifier plates are the most novel part. They use color pairs that become near-invisible under one form of dichromacy but stay visible under the other, which lets the screener attempt to separate protan-type from deutan-type rather than reporting both as undifferentiated red-green CVD. The separation is tuned to dichromat confusion lines, so it is most reliable for dichromats and softer for the (more common) anomalous trichromats; the scoring requires multiple corroborating misses before issuing a subtype label.

## How the result is classified

Twelve cascading rules applied in order, first match wins:

1. Control fail = Inconclusive (display or lighting issue).
2. All failures were near-misses = Likely Anomalous Trichromacy.
3. Protan-only classifiers fail (both, or one plus two screeners) and deutan-only classifiers pass = Possible/Likely Red-Type.
4. Deutan-only classifiers fail (same gating) and protan-only classifiers pass = Possible/Likely Green-Type.
5. Both classifier types fail, with a third corroborating miss = Strong Red-Green Color Vision Difference (mixed).
6. Many lump screen failures, no classifier signal = Likely Red-Green CVD.
7. Tritan-line failures = Likely Blue-Yellow CVD.
8. Combined RG + tritan = Atypical Color Vision Pattern.
9-11. Mild variants of the above.
12. Clean = Typical Color Vision.

The full cascade is in `scoreResults` in `index.html`. Results stay client-side; the page stores nothing server-side.

## Length

All 14 plates always run (about 60-100 seconds). An earlier adaptive early-exit was removed when plate order became randomized: a clean run on a non-representative first-9 subset could falsely report Typical Color Vision.

## Retake

The "Try with different plates" button on the results screen rerolls a per-session salt that is XOR'd into each plate's seed before the dot positions are generated. The plate answers are unchanged (still "74", "8", and so on), but the constellation of dots that draws those figures shifts entirely. This defeats answer-key memorization without needing a second plate library.

## Run locally

```bash
pip install -r requirements.txt        # flask + flask-cors + gunicorn
python api.py                          # serves on 127.0.0.1:5012 with the Flask dev server
```

For production, `start.sh` runs gunicorn under systemd (`whatcolor-beta.service`):

```bash
./start.sh                             # gunicorn, 2 workers, 2 threads each
sudo systemctl status whatcolor-beta   # under systemd in production
```

The service is reverse-proxied at `/test/` on the public domains. See the parent `service_manager.py` and `/etc/caddy/Caddyfile` for the deployment wiring.

No environment variables are required: the backend only serves static files and a `/health` endpoint. (The former beta-signup API and its `RESEND_API_KEY`/`BETA_ADMIN_KEY` were removed 2026-06-09 when the iOS app shipped.)

## File map

| File | Role |
|---|---|
| `index.html` | All UI, rendering, scoring, and the plate verifier (~1700 lines, hand-edited, no build step) |
| `api.py` | Flask backend: static file routes + `/health` (~50 lines; signup API removed 2026-06-09) |
| `color-math.js` | Viénot-1999 CVD simulation, CIEDE2000, hex/LAB conversions. Copy of `whatcolor/color-math.js`, kept in parity by `whatcolor/tests/parity_test.py` |
| `start.sh` | Production entrypoint (gunicorn) |
| `requirements.txt` | Flask, flask-cors, gunicorn |
| `beta.db` | Historical beta signups (gitignored; no longer read or written) |

## Test parity

The 14 plates' fg/bg color pairs are covered by `whatcolor/tests/parity_test.py`. After any change to the `PLATES` array in `index.html`, regenerate the `BETA_PLATES` snapshot in the parity test. The `whatcolor/CLAUDE.md` "Tests" section has the regeneration command.

```bash
cd /home/coolhand/html/whatcolor && python tests/parity_test.py
```

A passing run exits 0 and confirms that Python (`api.py` Brettel + CIEDE2000) and JS (`color-math.js` same math) produce byte-identical dE values for every plate in the test, in normal-vision, protan-simulated, deutan-simulated, and tritan-simulated spaces. A regression in either runtime fails this test.

## References

- Ishihara, S. (1917). *Tests for Colour-Blindness*. Handaya, Tokyo.
- Hardy, L.H., Rand, G., & Rittler, M.C. (1954). *HRR Pseudoisochromatic Plates for Detecting and Classifying Color Vision Deficiency*. American Optical Company.
- Brettel, H., Viénot, F., & Mollon, J.D. (1997). Computerized simulation of color appearance for dichromats. *Journal of the Optical Society of America A*, 14(10), 2647-2655.
- Viénot, F., Brettel, H., & Mollon, J.D. (1999). Digital video colourmaps for checking the legibility of displays by dichromats. *Color Research & Application*, 24(4), 243-252. (The single-plane simulation implemented here.)
- Sharma, G., Wu, W., & Dalal, E.N. (2005). The CIEDE2000 color-difference formula: implementation notes, supplementary test data, and mathematical observations. *Color Research & Application*, 30(1), 21-30.
- Birch, J. (2012). Worldwide prevalence of red-green color deficiency. *Journal of the Optical Society of America A*, 29(3), 313-320.
- Cole, B.L. (2007). Assessment of inherited colour vision defects in clinical practice. *Clinical and Experimental Optometry*, 90(3), 157-175.
- Birch, J. & Platts, C.E. (2010). Colour vision testing in occupational health. *Occupational Medicine*, 60(8), 580-586.
- Wong, B. (2011). Points of view: color blindness. *Nature Methods*, 8(6), 441.

## Author

Luke Steuber
[lukesteuber.com](https://lukesteuber.com) · [@lukesteuber.com on Bluesky](https://bsky.app/profile/lukesteuber.com)

## License

MIT (see `../whatcolor/LICENSE`).
