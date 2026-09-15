/**
 * File Purpose: Stages APK/AAB artifacts and SHA-256 checksums without copying signing credentials.
 * Primary Functions: Validate artifact extensions, copy artifacts to the ignored release directory, and write checksums.
 * Inputs and Outputs: Accepts built APK/AAB paths; creates android-build/release artifacts and SHA256SUMS.txt.
 */

import { copyFileSync, createHash, existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { basename, extname, resolve } from 'node:path';

const inputPaths = process.argv.slice(2);
if (inputPaths.length === 0) {
  throw new Error('Usage: node stage-release.mjs <artifact.apk|artifact.aab> [...]');
}

const manifest = JSON.parse(readFileSync(resolve(import.meta.dirname, 'twa-manifest.json'), 'utf8'));
const releaseDirectory = resolve(import.meta.dirname, 'release');
const version = `v${manifest.appVersionName}-${manifest.appVersionCode}`;
const staged = [];

mkdirSync(releaseDirectory, { recursive: true });
for (const inputPath of inputPaths) {
  const source = resolve(inputPath);
  const extension = extname(source).toLowerCase();
  if (!['.apk', '.aab'].includes(extension)) {
    throw new Error(`Unsupported release artifact: ${basename(source)}`);
  }
  if (!existsSync(source)) {
    throw new Error(`Artifact does not exist: ${source}`);
  }

  const destination = resolve(
    releaseDirectory,
    `color-vision-plates-${version}-${extension === '.apk' ? 'android' : 'bundle'}${extension}`,
  );
  copyFileSync(source, destination);
  staged.push(destination);
}

const checksums = staged
  .map((path) => {
    const digest = createHash('sha256').update(readFileSync(path)).digest('hex');
    return `${digest}  ${basename(path)}`;
  })
  .join('\n');

writeFileSync(resolve(releaseDirectory, 'SHA256SUMS.txt'), `${checksums}\n`, 'utf8');
console.log(`Staged ${staged.length} artifact(s) in ${releaseDirectory}.`);
