# Handover: results wording and iPhone 1.0.5 (2026-11-14)

This note hands the results-wording work to the next session. Times are UTC.

## What Luke asked for and approved

In his words, in order:

1. "check the ending text on the color vision test - we need to REVERT that to a PRIOR version that doesn't go into plate designs and shit"
2. Relayed context: "people know it's not a clinical tool, we can make tha tclear, it still has to have useful language"
3. "Merge it", then "Deploy web" (PR 6)
4. "handle 'em" (the four open items from PR 6), then "Merge and deploy" (PR 7)
5. "fix the classifier sets wording too", then "Merge and deploy" (PR 8)
6. "fix the protan-only bullet too", then "commit, push, merge, deploy, the whole shebang - clean up" (PR 9)
7. "resolve the still open", then "Merge and deploy" (PR 10)
8. "Prepare 1.0.5" (this branch)

Each web deploy had its own yes. No iPhone or Android build, upload or submission has been approved.

Standing rule from this work: do not reword the results screen into answer-pattern or plate-group text. AGENTS.md now says so.

## Merged and live on the web

Main is 4d2efa7. The page at whatcoloristhis.one/test/, whatcoloristhat.one/test/ and whatcoloristhat.net/test/ is main's `index.html` (sha256 651be41c…, deployed 2026-11-15 06:17).

| PR | Merge commit | What it did |
|---|---|---|
| 6 | a563acd | Restored the result labels, descriptions and the "What this might mean day-to-day" card from b8c8d39 (2026-07-26), unchanged |
| 7 | 132ffc3 | AGENTS.md line; dropped "plates designed to vanish"; Android setting names in the inconclusive text; App Store description examples; store screenshots recaptured; smoke test labels |
| 8 | f338445 | Dropped "classifier" from two descriptions and the plate review labels |
| 9 | d5d56ea | Strong Red-Green bullet: "a typical red-type or green-type pattern" |
| 10 | 4d2efa7 | "trichromats", "CVD" and "tritan-type" reworded in seven bullets |

Deploy method: only `index.html` changes. Compare the live file's hash with the main commit it was deployed from, copy the live file to a dated folder, then replace it. The web root on Drummer is `~/www/dr.eamer.dev/test` (plain files, not a Git checkout). Previous files are kept on Drummer in `~/backups/test-predeploy-<timestamp>/index.html`; the newest is `test-predeploy-20261115T061731Z`.

Before/after screenshots for every change are on napoleon in `~/workspace/cvp-ending-text-20261114/screenshots/`. The comparison images PR 6 shows are on the branch `evidence/ending-text-20261114`; keep that branch.

## What this branch contains

Branch `claude/ios-1.0.5-20261114`. No change to `index.html` or app code.

- **Version:** 1.0.5, build 11, in `ios/project.yml` and both `Info.plist` files (app and widget). `xcodegen generate` leaves the committed project unchanged.
- **Release notes** (`ios/fastlane/metadata/en-US/release_notes.txt`): new draft. The 1.0.4 notes said results "name the plate groups you missed" and "no longer suggest a type or severity", which is no longer true.
- **Description** (`description.txt` and the copy in `ios/app-store-listing.md`): the second paragraph now says the app gives a plain result and is a screening, not a diagnosis; the plate-group bullet reads "red-green, red-type, green-type, blue-yellow, and control sets".
- **`ios/README.md`:** release-assets paragraph updated to say 1.0.5 is prepared and not built or submitted.

The release notes and description are new public text. Luke has not read or approved them.

## Test results

Run on this branch on napoleon, 2026-11-14:

- `node --test tests/*.test.cjs`: 40 pass, 0 fail.
- `python -m unittest discover -s tests -p 'test_*.py'`: 4 pass (in a scratch virtual environment; Flask is not installed system-wide).
- iPhone simulator (iPhone 17 Pro Max, iOS 26.5, debug build), whole scheme except `ScreenshotTest`: SmokeTest 4 pass; widget and unit suites 10 pass (IshiharaPlateTests, OfflineBundleContractTests, ReviewPromptPolicyTests). The smoke tests took about 29 minutes of wall time on a busy machine against about 70 seconds earlier in the day; they passed.
- The built simulator app reports 1.0.5 (11) for the app and the widget, and its bundled `index.html` is byte-identical to main's (sha256 651be41c…).

Not run: a release archive, a signed build, any device test, and `ScreenshotTest` on this branch (it passed on both devices for PR 9; nothing it captures changed since).

## Remaining steps

### iPhone 1.0.5

1. **Luke:** read and approve the release notes and the description change in the PR.
2. **Check the App Store record first.** 1.0.4 (build 10) was submitted 2026-11-10 and was waiting for review. Its status was not read in this work (the App Store Connect helper is not in napoleon's workspace). If 1.0.4 is still in review, Luke decides between pulling it and replacing the build, or letting it through and following with 1.0.5. If 1.0.4 was rejected or is live, 1.0.5 is the next version as prepared.
3. Merge the PR.
4. **Luke, in Terminal.app:** archive and sign. App sessions on napoleon cannot read the login keychain, so signing runs from a script Luke starts in Terminal after unlocking the keychain. Team is Bridge City Lab LLC (596T7J7FB6); bundle id `one.whatcoloristhis.visiontest`. Keep the checkout folder named `colorblindness-test`. When exporting, set `manageAppVersionAndBuildNumber` to false so the build number stays 11.
5. **Luke's yes:** upload the build to App Store Connect.
6. Supply `ios/fastlane/metadata/review_information/phone_number.txt` locally (ignored by Git), then push listing text and screenshots with the fastlane lane in `ios/fastlane/Fastfile`. This also needs Luke's yes.
7. The age rating must answer `socialMedia` or the submission fails with a 409.
8. **Luke's yes, for this submission only:** submit for review.

Screenshots in `ios/screenshots/` are current as of PR 9 (captured on iPhone 17 Pro Max and iPad Pro 13-inch (M5), iOS 26.5). PR 10 changed no bullet shown in them. The small arc in the bottom-right corner of the iPad screenshots is the iPadOS window resize handle; it is in the 1.0.4 screenshots too.

### Android

No build is needed for the wording. The app (`one.whatcoloristhis.plates.twa`, 1.0.3, version code 5) is a Trusted Web Activity that loads whatcoloristhis.one/test/, so it shows the live page on its next online launch. Its offline cache is the page's service worker, which is network-first.

Not checked: whether any older hosted Android build carries its own copy of the page.

## Cleaned up

- All session branches are deleted except this one and the evidence branch.
- Temporary simulators ("CVP Shots …", "CVP Check iPhone") are deleted and `ios/build` is removed.
- `origin/claude/release-signing-20261109` is merged and was not created in this work; it was left alone.

## Open questions

- The App Review status of 1.0.4.
- Whether Luke wants the 1.0.5 notes to mention 1.0.4 at all.
- The LocalStuff session was asked whether anything is in flight for this app's App Store record and had not answered.
