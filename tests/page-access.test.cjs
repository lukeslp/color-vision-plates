'use strict';
// Checks on the page's markup and styles that keep it usable with a screen
// reader, by touch, and without telling colors apart.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { test } = require('node:test');
const html = fs.readFileSync(path.join(__dirname, '../index.html'), 'utf8');

test('plate label for screen readers names the task, not the plate group', () => {
  assert.ok(html.includes("': ' + prompt + ' hidden in the colored dots'"), 'Missing the plate label');
  assert.doesNotMatch(html, /testName \+ ' test/);
});

test('plate-by-plate rows mark matched, close and missed without relying on color', () => {
  for (const [mark, word] of [['\\u2713', 'Matched: '], ['\\u2248', 'Close: '], ['\\u2717', 'Missed: ']]) {
    assert.ok(html.includes(`mark = '${mark}'; spoken = '${word}';`), word);
  }
  assert.match(html, /markEl\.setAttribute\('aria-hidden', 'true'\)/);
  assert.match(html, /\.visually-hidden \{[^}]*clip/);
});

test('shape plates do not show a suggested answer', () => {
  // Hover styles only where a pointer can hover; focus goes to the group.
  assert.match(html, /@media \(hover: hover\) \{\s*\.shape-btn:hover/);
  assert.doesNotMatch(html.replace(/@media \(hover: hover\) \{[^}]*\}\s*\}/, ''), /\.shape-btn:hover/);
  assert.match(html, /getElementById\('shape-buttons'\);\s*if \(shapeGroup\) shapeGroup\.focus\(\);/);
  assert.doesNotMatch(html, /firstShape\.focus\(\)/);
  assert.match(html, /id="shape-buttons" role="group" aria-labelledby="plate-question" tabindex="-1"/);
});

test('small text keeps its contrast and small links keep a 48px touch target', () => {
  const note = html.match(/\.hero \.note \{[^}]*\}/)[0];
  assert.doesNotMatch(note, /opacity/);
  assert.match(html, /\.badge-cvd \{[^}]*color: #93a8f4;/);
  assert.match(html, /\.footer-links a \{[^}]*min-width: 48px; padding: 14px 8px;/);
  assert.match(html, /\.hero-method-link \{[^}]*padding: 14px 0;/);
  assert.match(html, /\.methodology-link \{[^}]*padding: 15px 12px;/);
});

test('progress bar has a name and a spoken value; Privacy opens beside the result', () => {
  assert.match(html, /role="progressbar" aria-label="Progress"[^>]*aria-valuetext="Plate 1 of 14"/);
  assert.match(html, /setAttribute\('aria-valuetext', 'Plate ' \+ \(index \+ 1\) \+ ' of ' \+ PLATES\.length\)/);
  assert.match(html, /<a href="https:\/\/whatcoloristhis\.one\/test\/privacy\.html" target="_blank" rel="noopener">Privacy<\/a>/);
});
