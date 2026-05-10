# Launch post copy — colorblindness-test

Drafts for the channels where this actually lives. The test ships at `https://whatcoloristhis.one/test/` (canonical URL). All posts written in Luke's voice — colorblind dev, Bridge City Lab LLC, OR colleague-of-Luke voice where the dev shouldn't be the protagonist.

---

## Show HN

### Title (80 char max — HN truncates aggressively)

```
Show HN: Free 14-plate color vision test, plates generated, sources cited
```
*(73 chars)*

### Body (HN's text-post format, no markdown — plain text + paragraphs)

```
I'm colorblind. Most online color vision tests are scanned Ishihara JPEGs of dubious provenance, locked behind email signup, or sketchy ad-heavy pages. None of the free ones I've used cite their sources, and the paid ones charge $30 for a plate book to find out something most people just want to confirm in 60 seconds.

So I built one. https://whatcoloristhis.one/test/

It's 14 plates: 1 luminance-control, 5 red-green screeners, 2 protan-only and 2 deutan-only classifier plates (so it can separate protan from deutan, not just lump them as "red-green CVD"), and 4 tritan plates that use Brettel-1997 confusion-line geometry instead of the naive b*-axis pairs that leak ~30 ΔE in tritan-simulated space. Plates are generated at runtime from CIELAB specs and validated by simulating each fg/bg pair under Brettel dichromacy at module load — anything leaking >10 ΔE in the wrong space throws a console warning. The original tritan plates leaked 26-34 ΔE; the redesigned ones leak under 1.

Other things in the box: a pre-test gray-ramp calibration probe (catches Night Shift, blue-light filters, dim screens before they ruin the result); session-salted dot positions so the same test doesn't show identical patterns across visits or to a friend who shares the link; randomized plate order; 5/6 and 8/0 typography ambiguity addressed by a tighter mask threshold so dot-rendered digits read sharp.

Citations are inline — Ishihara 1917, Hardy/Rand/Rittler 1954, Brettel/Vienot/Mollon 1997, Sharma/Wu/Dalal 2005 (CIEDE2000), Birch 2012, Cole 2007. Methodology is exposed before the test (link in the hero) so people aren't asked to trust it sight-unseen.

It's a screening, not a diagnosis. There's a "see an eye care professional" line both inline and at the result. No signup. No email collected. No tracking. No ads. MIT licensed. Single static HTML + Flask backend that just serves the file.

Companion to a colorblindness-focused color identification PWA at whatcoloristhis.one — that's the "What Color Is This?" project, this is "What KIND of color vision do you have?". The companion app's iOS public TestFlight beta is at https://testflight.apple.com/join/5y2mqQcH if you want to try it. Both are free and stay free.

Source: https://github.com/lukeslp/colorblindness-test
```

### Why this works for HN

- Lead paragraph identifies a real personal pain ("I'm colorblind") and a market failure (existing free tests are bad)
- Second paragraph is technical density — HN respects "I generated the plates from CIELAB and validated under Brettel" because it shows actual work
- Third paragraph shows the engineering details (calibration probe, session salt, mask threshold) — these are the kinds of details that get HN comments going
- Fourth paragraph is the academic citation defense — preempts "but how do we know it's real" comments
- Fifth paragraph is the privacy stance + license — HN cares
- Closing is the soft cross-promo to the companion app

### Comments to be ready for

- "Why not contribute to an existing open-source test like X?" → Most don't exist; the few that do are unmaintained scans of expired-copyright Ishihara plates
- "What about the Cambridge Colour Test / CCT?" → Gold standard, requires a calibrated CRT, $$, not a screening
- "Why CIEDE2000 and not Lab distance?" → because Lab distance overweights lightness in saturation-driven discrimination; CIEDE2000 is the formula clinical research has converged on
- "Can I link to a specific plate?" → not yet; happy to add if there's demand
- "Will you collect this data anonymously to validate the test?" → no, by design — privacy first; would need IRB approval anyway

---

## Reddit r/Colorblind

### Title

```
Built a free 14-plate color vision test (no signup, sources cited, MIT) — feedback welcome
```

### Body

```
Hey r/Colorblind 👋

I'm a colorblind dev (mild deutan, the usual). I got tired of the situation around free CVD tests — most are sketchy Ishihara JPEG scans, ad-heavy, or behind email walls — so I built one.

**Link:** https://whatcoloristhis.one/test/

**What it does:** 14 plates total. 1 luminance control, 5 red-green screeners, 2 protan-only + 2 deutan-only classifier plates (so it can separate protan from deutan rather than lumping you as "red-green"), and 4 tritan plates.

**Why I'm posting here:** I want this community's feedback before sharing more widely.

A few things I'd love to hear about:

1. **Plates that misread for you** — does any plate show you a different number than you'd expect from your CVD type? The plates have known near-misses encoded for each type, but real-world variation is what tells me whether the test works.
2. **Tritan plates** — those are notoriously hard to design. Mine use Brettel-1997 confusion-line geometry. If you're tritan or know someone who is, I'd love to know whether the result tracks.
3. **The classifier plates** (protan-only vs deutan-only) — do they correctly classify your subtype if you know it?
4. **Anything that feels broken** — typography ambiguity (5 vs 6, 8 vs 0), color drift on your display, weird scoring, etc.

**What it isn't:** a clinical diagnosis. The only way to actually diagnose CVD is anomaloscopy + clinical Ishihara/HRR plate book under standard illumination. This is a screening for "should I see someone about this" or "I want to confirm what I already suspect".

**The privacy stance:** no signup, no email, no tracking, no ads. The end of the test links to the iOS public TestFlight for the companion color-identification app, which is also free.

Source code: https://github.com/lukeslp/colorblindness-test (MIT)

Happy to take feedback on the plates themselves, the result copy, the methodology section, or the tritan classification logic. Especially interested in feedback from anyone with confirmed clinical results — does the screening match what your eye doc told you?
```

### Why this works for r/Colorblind

- They've seen many "I made a CVD test" posts. Differentiating: cite sources, ask for SPECIFIC feedback (not just "what do you think")
- Lead with the dev being colorblind — establishes you're not an outsider
- The 4 numbered asks are the conversation starters; r/Colorblind is generous with this kind of structured ask
- Privacy + open-source explicitly mentioned — the sub is wary of data collection
- "Feedback from anyone with confirmed clinical results" closes with the most credible validation request

---

## Bluesky thread (300-char chunks)

### Post 1 (the hook + og card)

```
Built a free color vision deficiency test. 14 plates, generated from CIELAB and validated against the Brettel 1997 dichromacy model. Sources cited. No signup. No tracking.

I'm colorblind. The existing free tests are mostly scanned JPEGs of dubious provenance.

🔗 whatcoloristhis.one/test/
```
*(290 chars — leaves room for the linkcard)*

### Post 2 (the engineering brag)

```
The 4 tritan plates were a bear. The naive design (separate fg/bg on the b* axis) leaks 26-34 ΔE in tritan-simulated space — meaning a tritan can still partially see the figure, defeating the test.

Used Brettel confusion-line geometry. Final pairs leak under 1 ΔE. Now it works.
```
*(298 chars)*

### Post 3 (the classifier story)

```
Most "free CVD tests" tell you "you might be red-green colorblind" and stop. Mine separates protan-type from deutan-type using classifier plates whose colors vanish under one form of dichromacy but stay visible under the other.

It's not a clinical diagnosis. But you'll know which kind.
```
*(285 chars)*

### Post 4 (the soft CTA + companion app)

```
Companion to a color identification PWA I'm shipping (also free, also colorblindness-focused). iOS public TestFlight beta: testflight.apple.com/join/5y2mqQcH (link is also at the end of the test).

Open source: github.com/lukeslp/colorblindness-test
```
*(259 chars)*

### Why this works for Bluesky

- Visual-first: post 1's link autocard does most of the work
- Each post stands alone (people skim threads)
- Engineering details in post 2 are the share-bait for the dev community
- "Made by a colorblind dev" tone throughout
- Post 4 is soft — no aggressive ask

---

## Mastodon (single post, 500 char)

```
Built a free color vision deficiency test 👁️🌈

14 plates generated at runtime from CIELAB specs and validated against the Brettel 1997 dichromacy model. Tests for protan, deutan, AND tritan with classifier plates that separate the subtypes (most free tests don't).

Sources cited inline. No signup. No tracking. MIT licensed.

I'm colorblind. The existing free tests are bad. So.

🔗 whatcoloristhis.one/test/
🐙 github.com/lukeslp/colorblindness-test

#Accessibility #Colorblindness #OpenSource
```
*(490 chars)*

---

## Accessibility newsletter pitch

For: Smashing Magazine accessibility column, A11y Weekly, Web AIM newsletter, Sara Soueidan's newsletter, anyone who covers a11y tools.

### Subject line

```
Free, sourced, no-signup color vision screening tool you might find useful
```

### Body

```
Hi [name],

I'm Luke Steuber. I'm a colorblind developer who got tired of the
situation around free CVD screening tests — most are scanned-Ishihara
PDFs of dubious provenance, locked behind email walls, or ad-heavy
pages with no methodology disclosure.

So I built one and open-sourced it. Free, no signup, sources cited.

Link: https://whatcoloristhis.one/test/
Code: https://github.com/lukeslp/colorblindness-test (MIT)

Three things that might be relevant for your readers:

1. **Plates are generated from CIELAB**, not scanned. That sidesteps
   the copyright issue around clinical Ishihara reproductions and
   makes the colors render correctly across modern displays.

2. **It validates plate quality at runtime** by simulating each
   fg/bg pair under Brettel-1997 dichromacy. Plates that "leak"
   more than 10 ΔE in the wrong color space throw a console warning.
   The original tritan plates leaked 26-34 ΔE; the redesigned ones
   leak under 1. That validation step is the kind of thing nobody
   shipping a "free CVD test" usually bothers with.

3. **The classifier plates** separate protan-type from deutan-type
   rather than lumping them together as "red-green CVD" — which is
   what most free tests do. It's a meaningful distinction for
   anyone designing for accessibility.

If you have readers who'd find this useful for self-screening, or
designers who want a tool to share with clients to demonstrate why
their palette doesn't work, please consider mentioning it.

Happy to answer questions about the methodology, the plate
generation, or the engineering. I'm also building a companion
color identification iOS app — that's separate and not what I'm
pitching here.

Thanks for reading,
Luke Steuber
luke@lukesteuber.com
Bridge City Lab LLC
```

### Why this works for newsletter pitches

- Lead with credentials (colorblind dev, not random outsider)
- Three numbered points = scannable; each is independently quotable
- "Three things that might be relevant for your readers" centers them, not you
- Soft close — no demand, no follow-up trigger
- Mention of the iOS app + immediate disclaimer ("not what I'm pitching") respects their time
- One-line attribution at the bottom (Bridge City Lab LLC) for cite/credit

---

## Open Graph share card audit

The share preview that appears when this URL is posted on Bluesky / Twitter / Reddit / Slack / Discord — the equivalent of an App Store screenshot for the web.

| Element | Current | Notes |
|---|---|---|
| og:image | `og-beta.png` (1200×630, 198 KB) | Fits OG spec exactly. Good. |
| og:image:alt | "What Color Is This? color vision screening test" | Just added — was missing, screen-reader users on Bluesky get the alt now. |
| og:title | "Color Vision Test — 14 plates, real sources, no signup" | Updated from the terse "Color Vision Deficiency Test". The new title says what it is + what makes it different. |
| og:description | Full sentence with methodology + "made by a colorblind developer" | Updated from "A real one, not marketing. With sources." — the personal angle survives, the technical credibility comes through. |
| og:url | `whatcoloristhis.one/test/` | Was `/beta/` (404 / redirect). Fixed. |
| og:site_name | "What Color Is This?" | Just added — gives the share card a publisher attribution. |
| twitter:title + description | Mirror og:* | Just added — explicit declarations vs falling back to og:* tags. |
| canonical link | `whatcoloristhis.one/test/` | Just added — search engines now know the canonical home across the 5 mirror domains. |

The og-beta.png is the visual hero. If you want to replace it later, the spec is 1200×630, RGB no alpha, < 8 MB. Show the test plate graphic (it's already that, presumably).

`og-beta-v2.png` is a byte-identical duplicate — vestigial, can be deleted. Leaving for now in case it's referenced from somewhere I missed.

---

## When to post

- **Bluesky** — anytime, weekday morning Pacific time gets the most reach for accessibility-related posts
- **Mastodon** — same as Bluesky
- **Reddit r/Colorblind** — Sunday-Monday morning UTC; that sub is most active when the EU is awake
- **Show HN** — Tuesday or Wednesday, 9 AM Pacific. Avoid Friday/weekend (low frontpage time). Do not submit twice if it doesn't catch traction; resubmit in 30 days max with a different title
- **Newsletter pitches** — send Tuesday-Thursday morning the contact's local time, never Monday or Friday

## What not to do

- **Don't post to r/all** or other big general subs first — small specialized subs (r/Colorblind, r/accessibility) reward authentic posts; general subs punish them
- **Don't add UTM tags** to the URL on first post — looks like growth-hacking, the audience that matters here notices
- **Don't say "we"** — it's a solo dev project, "we" reads as agency-like and untrustworthy
- **Don't drop the personal angle** — "I'm a colorblind developer" is the differentiator vs all the other "free CVD tests" online
- **TestFlight URL is the canonical beta link**: `https://testflight.apple.com/join/5y2mqQcH`. The end of the test now CTAs straight to it, no email collection step.