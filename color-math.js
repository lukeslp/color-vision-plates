/* color-math.js — direct port of api.py for offline use in the iOS bundle.
 *
 * The web app calls this only when window.WHATCOLOR_OFFLINE === true; otherwise
 * fetch() to the Flask backend stays the source of truth. The Python and JS
 * implementations are kept in lockstep by tests/parity_test.py.
 *
 * Public surface (mirrors /api/* JSON shapes):
 *   ColorMath.match(hex)              -> /api/match payload
 *   ColorMath.random()                -> /api/random payload
 *   ColorMath.accessible(hex, cvd)    -> /api/accessible payload
 *   ColorMath.loadDatabase(arr)       -> set the [{name,hex}] color list
 *   ColorMath.isReady()               -> true once loadDatabase has been called
 */
(function (root) {
    'use strict';

    // --- color conversion utilities --------------------------------------

    // Python's `%` always returns a non-negative remainder when divisor > 0.
    // JS's `%` keeps the sign of the dividend. Naive `((a%b)+b)%b` works for
    // negatives but introduces FP drift when `a` is already in [0, b) — match
    // Python exactly with a branch instead.
    function pyMod(a, b) {
        const r = a % b;
        return r < 0 ? r + b : r;
    }

    // Python's built-in round() uses banker's rounding (round half to even).
    // JS's Math.round() rounds half away from zero. Use this everywhere we
    // need byte-exact parity with api.py.
    function pyRound(x, digits) {
        if (typeof digits === 'number' && digits > 0) {
            const factor = Math.pow(10, digits);
            return pyRound(x * factor) / factor;
        }
        const floorVal = Math.floor(x);
        const diff = x - floorVal;
        if (diff < 0.5) return floorVal;
        if (diff > 0.5) return floorVal + 1;
        return floorVal % 2 === 0 ? floorVal : floorVal + 1;
    }

    function hexToRgb(hexStr) {
        hexStr = hexStr.replace(/^#/, '');
        return [
            parseInt(hexStr.slice(0, 2), 16),
            parseInt(hexStr.slice(2, 4), 16),
            parseInt(hexStr.slice(4, 6), 16),
        ];
    }

    function rgbToLinear(c) {
        c = c / 255.0;
        if (c > 0.04045) return Math.pow((c + 0.055) / 1.055, 2.4);
        return c / 12.92;
    }

    function rgbToXyz(r, g, b) {
        const rl = rgbToLinear(r);
        const gl = rgbToLinear(g);
        const bl = rgbToLinear(b);
        const x = (0.4124564 * rl + 0.3575761 * gl + 0.1804375 * bl) * 100.0;
        const y = (0.2126729 * rl + 0.7151522 * gl + 0.0721750 * bl) * 100.0;
        const z = (0.0193339 * rl + 0.1191920 * gl + 0.9503041 * bl) * 100.0;
        return [x, y, z];
    }

    function xyzToLab(x, y, z) {
        const xn = 95.047, yn = 100.0, zn = 108.883;
        function f(t) {
            const delta = 6.0 / 29.0;
            if (t > Math.pow(delta, 3)) return Math.pow(t, 1.0 / 3.0);
            return t / (3.0 * delta * delta) + 4.0 / 29.0;
        }
        const fx = f(x / xn);
        const fy = f(y / yn);
        const fz = f(z / zn);
        const L = 116.0 * fy - 16.0;
        const a = 500.0 * (fx - fy);
        const b = 200.0 * (fy - fz);
        return [L, a, b];
    }

    function hexToLab(hexStr) {
        const [r, g, b] = hexToRgb(hexStr);
        const [x, y, z] = rgbToXyz(r, g, b);
        return xyzToLab(x, y, z);
    }

    function deltaECiede2000(lab1, lab2) {
        const [L1, a1, b1] = lab1;
        const [L2, a2, b2] = lab2;
        const C1 = Math.sqrt(a1 * a1 + b1 * b1);
        const C2 = Math.sqrt(a2 * a2 + b2 * b2);
        const CabMean = (C1 + C2) / 2.0;
        const G = 0.5 * (1.0 - Math.sqrt(Math.pow(CabMean, 7) / (Math.pow(CabMean, 7) + Math.pow(25.0, 7))));
        const a1p = a1 * (1.0 + G);
        const a2p = a2 * (1.0 + G);
        const C1p = Math.sqrt(a1p * a1p + b1 * b1);
        const C2p = Math.sqrt(a2p * a2p + b2 * b2);
        const h1p = pyMod(Math.atan2(b1, a1p) * 180.0 / Math.PI, 360.0);
        const h2p = pyMod(Math.atan2(b2, a2p) * 180.0 / Math.PI, 360.0);

        const dLp = L2 - L1;
        const dCp = C2p - C1p;

        let dhp;
        if (C1p * C2p === 0) dhp = 0.0;
        else if (Math.abs(h2p - h1p) <= 180.0) dhp = h2p - h1p;
        else if (h2p - h1p > 180.0) dhp = h2p - h1p - 360.0;
        else dhp = h2p - h1p + 360.0;

        const dHp = 2.0 * Math.sqrt(C1p * C2p) * Math.sin((dhp / 2.0) * Math.PI / 180.0);

        const LpMean = (L1 + L2) / 2.0;
        const CpMean = (C1p + C2p) / 2.0;

        let hpMean;
        if (C1p * C2p === 0) hpMean = h1p + h2p;
        else if (Math.abs(h1p - h2p) <= 180.0) hpMean = (h1p + h2p) / 2.0;
        else if (h1p + h2p < 360.0) hpMean = (h1p + h2p + 360.0) / 2.0;
        else hpMean = (h1p + h2p - 360.0) / 2.0;

        const T = 1.0
            - 0.17 * Math.cos((hpMean - 30.0) * Math.PI / 180.0)
            + 0.24 * Math.cos((2.0 * hpMean) * Math.PI / 180.0)
            + 0.32 * Math.cos((3.0 * hpMean + 6.0) * Math.PI / 180.0)
            - 0.20 * Math.cos((4.0 * hpMean - 63.0) * Math.PI / 180.0);

        const SL = 1.0 + 0.015 * Math.pow(LpMean - 50.0, 2) / Math.sqrt(20.0 + Math.pow(LpMean - 50.0, 2));
        const SC = 1.0 + 0.045 * CpMean;
        const SH = 1.0 + 0.015 * CpMean * T;

        const RTtheta = 30.0 * Math.exp(-Math.pow((hpMean - 275.0) / 25.0, 2));
        const RC = 2.0 * Math.sqrt(Math.pow(CpMean, 7) / (Math.pow(CpMean, 7) + Math.pow(25.0, 7)));
        const RT = -Math.sin((2.0 * RTtheta) * Math.PI / 180.0) * RC;

        return Math.sqrt(
            Math.pow(dLp / SL, 2) +
            Math.pow(dCp / SC, 2) +
            Math.pow(dHp / SH, 2) +
            RT * (dCp / SC) * (dHp / SH)
        );
    }

    function qualityLabel(de) {
        if (de < 1.0) return 'exact';
        if (de < 3.0) return 'very close';
        if (de < 6.0) return 'close';
        if (de < 12.0) return 'approximate';
        return 'rough';
    }

    function rgbToHsl(r, g, b) {
        r /= 255.0; g /= 255.0; b /= 255.0;
        const cmax = Math.max(r, g, b);
        const cmin = Math.min(r, g, b);
        const delta = cmax - cmin;
        const l = (cmax + cmin) / 2.0;
        let h, s;
        if (delta === 0) { h = 0.0; s = 0.0; }
        else {
            s = l < 0.5 ? delta / (cmax + cmin) : delta / (2.0 - cmax - cmin);
            if (cmax === r) h = pyMod((g - b) / delta, 6);
            else if (cmax === g) h = (b - r) / delta + 2;
            else h = (r - g) / delta + 4;
            h *= 60.0;
            if (h < 0) h += 360.0;
        }
        return [h, s * 100.0, l * 100.0];
    }

    function hslToRgb(h, s, l) {
        s /= 100.0; l /= 100.0;
        const c = (1.0 - Math.abs(2.0 * l - 1.0)) * s;
        const x = c * (1.0 - Math.abs(pyMod(h / 60.0, 2) - 1.0));
        const m = l - c / 2.0;
        let r1, g1, b1;
        if (h < 60) [r1, g1, b1] = [c, x, 0];
        else if (h < 120) [r1, g1, b1] = [x, c, 0];
        else if (h < 180) [r1, g1, b1] = [0, c, x];
        else if (h < 240) [r1, g1, b1] = [0, x, c];
        else if (h < 300) [r1, g1, b1] = [x, 0, c];
        else [r1, g1, b1] = [c, 0, x];
        return [
            Math.max(0, Math.min(255, pyRound((r1 + m) * 255))),
            Math.max(0, Math.min(255, pyRound((g1 + m) * 255))),
            Math.max(0, Math.min(255, pyRound((b1 + m) * 255))),
        ];
    }

    function rgbToHex(r, g, b) {
        const h = (n) => n.toString(16).padStart(2, '0');
        return `#${h(r)}${h(g)}${h(b)}`;
    }

    function describeAchromatic(l) {
        if (l > 95) return 'white';
        if (l > 85) return 'very light gray';
        if (l > 70) return 'light gray';
        if (l > 55) return 'medium light gray';
        if (l > 40) return 'medium gray';
        if (l > 25) return 'dark gray';
        if (l > 12) return 'very dark gray';
        return 'black';
    }

    function classifyColor(r, g, b) {
        const [h, s, l] = rgbToHsl(r, g, b);
        let family;
        if (s < 8) {
            if (l > 92) family = 'white';
            else if (l < 12) family = 'black';
            else family = 'gray';
            return { family, descriptor: describeAchromatic(l) };
        }
        if (h < 12 || h >= 348) family = 'red';
        else if (h < 38) family = 'orange';
        else if (h < 55) family = 'yellow-orange';
        else if (h < 73) family = 'yellow';
        else if (h < 105) family = 'yellow-green';
        else if (h < 160) family = 'green';
        else if (h < 195) family = 'teal';
        else if (h < 255) family = 'blue';
        else if (h < 290) family = 'purple';
        else if (h < 330) family = 'magenta';
        else family = 'pink';

        const parts = [];
        if (l > 85) parts.push('very light');
        else if (l > 70) parts.push('light');
        else if (l < 15) parts.push('very dark');
        else if (l < 30) parts.push('dark');
        if (s < 20) parts.push('grayish');
        else if (s < 40) parts.push('muted');
        else if (s > 85) parts.push('vivid');
        parts.push(family);
        return { family, descriptor: parts.join(' ') };
    }

    // --- harmonies -------------------------------------------------------

    function computeHarmonies(rgb) {
        const [h, s, l] = rgbToHsl(rgb[0], rgb[1], rgb[2]);
        function makeColor(hue) {
            hue = pyMod(hue, 360);
            const [r, g, b] = hslToRgb(hue, s, l);
            const c = classifyColor(r, g, b);
            return { hex: rgbToHex(r, g, b), descriptor: c.descriptor, family: c.family };
        }
        return {
            complementary: [makeColor(h + 180)],
            analogous: [makeColor(h - 30), makeColor(h + 30)],
            triadic: [makeColor(h + 120), makeColor(h + 240)],
            split_complementary: [makeColor(h + 150), makeColor(h + 210)],
        };
    }

    // --- CVD simulation (Brettel 1997) -----------------------------------

    const RGB_TO_LMS = [
        [0.31399022, 0.63951294, 0.04649755],
        [0.15537241, 0.75789446, 0.08670142],
        [0.01775239, 0.10944209, 0.87256922],
    ];
    const LMS_TO_RGB = [
        [5.47221206, -4.64196010, 0.16963708],
        [-1.12524190, 2.29317094, -0.16789520],
        [0.02980165, -0.19318073, 1.16364789],
    ];
    const PROTAN_SIM = [[0.0, 1.05118294, -0.05116099], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]];
    const DEUTAN_SIM = [[1.0, 0.0, 0.0], [0.9513092, 0.0, 0.04866992], [0.0, 0.0, 1.0]];
    const TRITAN_SIM = [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [-0.86744736, 1.86727089, 0.0]];

    const WONG_PALETTE = [
        '#000000', '#E69F00', '#56B4E9', '#009E73',
        '#F0E442', '#0072B2', '#D55E00', '#CC79A7',
    ];

    function matrixMultiply(mat, vec) {
        return mat.map(row => row.reduce((sum, m, i) => sum + m * vec[i], 0));
    }

    function linearToSrgb(c) {
        const s = c <= 0.0031308 ? 12.92 * c : 1.055 * Math.pow(c, 1.0 / 2.4) - 0.055;
        return Math.max(0, Math.min(255, pyRound(s * 255)));
    }

    function simulateCvd(rgb, cvdMatrix) {
        const lin = [rgbToLinear(rgb[0]), rgbToLinear(rgb[1]), rgbToLinear(rgb[2])];
        const lms = matrixMultiply(RGB_TO_LMS, lin);
        const simLms = matrixMultiply(cvdMatrix, lms);
        const simLin = matrixMultiply(LMS_TO_RGB, simLms);
        return [linearToSrgb(simLin[0]), linearToSrgb(simLin[1]), linearToSrgb(simLin[2])];
    }

    // --- color database (loaded by host once at startup) -----------------

    let COLOR_CACHE = null;
    let remainingColors = [];
    let lastColor = null;

    function loadDatabase(arr) {
        COLOR_CACHE = arr.map(entry => {
            const lab = hexToLab(entry.hex);
            const rgb = hexToRgb(entry.hex);
            return { name: entry.name, hex: entry.hex, lab, rgb };
        });
    }

    function isReady() { return COLOR_CACHE !== null; }

    // --- public API (matches /api/* shapes) ------------------------------

    function normalizeHex(hex) {
        hex = String(hex).trim().replace(/^#/, '');
        if (hex.length !== 6 || !/^[0-9a-fA-F]{6}$/.test(hex)) return null;
        return `#${hex.toLowerCase()}`;
    }

    function match(hexInput, count) {
        if (!isReady()) throw new Error('color database not loaded');
        if (typeof count !== 'number') count = 5;
        const hex = normalizeHex(hexInput);
        if (hex === null) return null;
        const inputRgb = hexToRgb(hex);
        const inputLab = hexToLab(hex);
        const classification = classifyColor(inputRgb[0], inputRgb[1], inputRgb[2]);

        const distances = COLOR_CACHE.map(c => [deltaECiede2000(inputLab, c.lab), c]);
        distances.sort((a, b) => a[0] - b[0]);

        const matches = distances.slice(0, count).map(([d, c]) => ({
            name: c.name,
            hex: c.hex,
            distance: pyRound(d, 2),
            rgb: [...c.rgb],
            family: classifyColor(c.rgb[0], c.rgb[1], c.rgb[2]).family,
            quality: qualityLabel(d),
        }));

        return {
            input: hex,
            family: classification.family,
            descriptor: classification.descriptor,
            matches,
            harmonies: computeHarmonies(inputRgb),
        };
    }

    function randomColor() {
        if (!isReady()) throw new Error('color database not loaded');
        if (remainingColors.length === 0) {
            remainingColors = COLOR_CACHE.slice();
            // Fisher-Yates shuffle
            for (let i = remainingColors.length - 1; i > 0; i--) {
                const j = Math.floor(Math.random() * (i + 1));
                [remainingColors[i], remainingColors[j]] = [remainingColors[j], remainingColors[i]];
            }
            if (lastColor && remainingColors.length > 1 && remainingColors[remainingColors.length - 1] === lastColor) {
                [remainingColors[remainingColors.length - 1], remainingColors[0]] =
                    [remainingColors[0], remainingColors[remainingColors.length - 1]];
            }
        }
        const color = remainingColors.pop();
        lastColor = color;
        const hexUpper = color.hex.toUpperCase();
        const cls = classifyColor(color.rgb[0], color.rgb[1], color.rgb[2]);
        return {
            color: hexUpper,
            name: color.name,
            rgb: [...color.rgb],
            family: cls.family,
            descriptor: cls.descriptor,
        };
    }

    function accessible(hexInput, cvdType) {
        if (!isReady()) throw new Error('color database not loaded');
        const hex = normalizeHex(hexInput);
        if (hex === null) return null;
        const upperHex = `#${hex.slice(1).toUpperCase()}`;
        const inputRgb = hexToRgb(upperHex);
        const inputLab = hexToLab(upperHex);

        const sims = {};
        const matrices = [['protanopia', PROTAN_SIM], ['deuteranopia', DEUTAN_SIM], ['tritanopia', TRITAN_SIM]];
        for (const [name, mat] of matrices) {
            const simRgb = simulateCvd(inputRgb, mat);
            const simHex = rgbToHex(simRgb[0], simRgb[1], simRgb[2]).toUpperCase();
            const simClass = classifyColor(simRgb[0], simRgb[1], simRgb[2]);
            sims[name] = { hex: simHex, descriptor: simClass.descriptor };
        }

        const wongLabs = WONG_PALETTE.map(wHex => {
            const wLab = hexToLab(wHex);
            const wRgb = hexToRgb(wHex);
            const wClass = classifyColor(wRgb[0], wRgb[1], wRgb[2]);
            return {
                hex: wHex.toUpperCase(),
                lab: wLab,
                descriptor: wClass.descriptor,
                distance: deltaECiede2000(inputLab, wLab),
            };
        });

        let closestIdx = 0;
        for (let i = 1; i < wongLabs.length; i++) {
            if (wongLabs[i].distance < wongLabs[closestIdx].distance) closestIdx = i;
        }
        const inputClass = classifyColor(inputRgb[0], inputRgb[1], inputRgb[2]);
        const palette = wongLabs.slice();
        palette[closestIdx] = {
            hex: upperHex,
            lab: inputLab,
            descriptor: inputClass.descriptor,
            distance: 0.0,
        };

        const selected = [closestIdx];
        const remaining = new Set();
        for (let i = 0; i < palette.length; i++) if (i !== closestIdx) remaining.add(i);
        while (selected.length < 5 && remaining.size > 0) {
            let bestIdx = null;
            let bestMinDist = -1;
            for (const idx of remaining) {
                let minDist = Infinity;
                for (const s of selected) {
                    const d = deltaECiede2000(palette[idx].lab, palette[s].lab);
                    if (d < minDist) minDist = d;
                }
                if (minDist > bestMinDist) { bestMinDist = minDist; bestIdx = idx; }
            }
            selected.push(bestIdx);
            remaining.delete(bestIdx);
        }

        const universalSafe = selected.map(idx => ({
            hex: palette[idx].hex,
            descriptor: palette[idx].descriptor,
            role: idx === closestIdx ? 'your color' : 'safe pair',
        }));

        const wongByDist = wongLabs.slice().sort((a, b) => b.distance - a.distance);
        const highContrast = wongByDist.slice(0, 2).map(w => ({
            hex: w.hex,
            descriptor: w.descriptor,
            delta_e: pyRound(w.distance, 1),
        }));

        let personal = null;
        if (cvdType && Object.prototype.hasOwnProperty.call(sims, cvdType)) {
            personal = { type: cvdType, hex: sims[cvdType].hex, descriptor: sims[cvdType].descriptor };
        }

        return {
            input: upperHex,
            universal_safe: universalSafe,
            high_contrast: highContrast,
            simulations: sims,
            personal,
        };
    }

    const ColorMath = {
        // public API
        match,
        random: randomColor,
        accessible,
        loadDatabase,
        isReady,
        // exposed for parity testing
        _internal: {
            hexToRgb, hexToLab, rgbToHsl, classifyColor, computeHarmonies,
            deltaECiede2000, qualityLabel, simulateCvd, rgbToHex,
            PROTAN_SIM, DEUTAN_SIM, TRITAN_SIM, WONG_PALETTE,
        },
    };

    if (typeof module !== 'undefined' && module.exports) {
        module.exports = ColorMath;
    } else {
        root.ColorMath = ColorMath;
    }
})(typeof window !== 'undefined' ? window : globalThis);
