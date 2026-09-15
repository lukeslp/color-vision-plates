# Project guidance

Color Vision Plates is an independent repository containing a web screening, a native iOS shell/widget, and Android TWA configuration. No private sibling checkout is required for development.

## Run and verify

Follow README.md for local setup. `python api.py` binds to 127.0.0.1:5012. `./start.sh` runs Gunicorn on the same loopback address. No signup API or credential configuration is needed.

Run `node --test tests/*.test.cjs` and `python -m unittest discover -s tests -p 'test_*.py'` before merging relevant changes. The Node tests exercise the actual page functions and bundled color math. Simulation checks establish software behavior, not clinical validity.

## Source ownership

- Keep the single-page architecture: index.html owns rendering, plate definitions, scoring, and the native bridge. Do not add a bundler or framework.
- color-math.js is shared original code from What Color. This repository's standalone fixtures replace the former private sibling test requirement.
- Use CIELAB plate specifications. Preserve foreground/background luminance conventions and the control exception. Changes to PLATES require numerical fixtures and a browser verifier check, followed by a complete screening and retake.
- Preserve scoring order, internal result identifiers, and native history compatibility unless the task explicitly changes them. Visible labels describe answer patterns, not established diagnoses.
- api.py serves only explicit public routes. Do not enable a static route covering the repository root.

## Native contracts

The iOS app bundles the root index.html and color-math.js. `window.CVT_NATIVE` gates native history (`screeningResult`), sharing, settings, companion links, and removal of remote fonts/analytics. Read ios/README.md and run the relevant unit/UI tests when changing these paths.

Edit ios/project.yml and regenerate with XcodeGen; do not hand-edit the generated Xcode project. Android identity, origin association, and signing are separate from a source release; see android-build/README.md.

## Privacy and claims

Keep the screening limitation below the progress bar and on the results screen. Do not claim sensitivity, specificity, subtype accuracy, severity assessment, or clinical validation without evidence. A gray-patch check cannot calibrate colors. Preserve accurate disclosure of local result storage and web analytics.

Never commit historical signup records, credentials, local settings, signing material, or personal review information. Production hosting, store submissions, and repository publication are distinct actions. Credit Luke Steuber; use first person in authored documentation.
