/**
 * File Purpose: Applies the two changes Bubblewrap 1.24.1 cannot express to the Android project it generates.
 * Primary Functions: Set targetSdkVersion 36; let large screens rotate while phones stay in portrait.
 * Inputs and Outputs: Edits app/build.gradle and the generated LauncherActivity.java in place; exits non-zero
 * if the generated text is not what this expects, so a Bubblewrap update cannot silently drop a change.
 */

import { readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';

const here = import.meta.dirname;
const twa = JSON.parse(readFileSync(resolve(here, 'twa-manifest.json'), 'utf8'));

function replaceOnce(text, find, replacement, what) {
  const parts = text.split(find);
  if (parts.length !== 2) {
    throw new Error(`Generated project changed: expected exactly one "${what}", found ${parts.length - 1}.`);
  }
  return parts.join(replacement);
}

// 1. Google Play needs target API 36. Bubblewrap writes 35 and has no manifest field for it.
const gradlePath = resolve(here, 'app', 'build.gradle');
let gradle = readFileSync(gradlePath, 'utf8');
if (!/^ *targetSdkVersion 36$/m.test(gradle)) {
  gradle = replaceOnce(gradle, 'targetSdkVersion 35\n', 'targetSdkVersion 36\n', 'targetSdkVersion 35');
  writeFileSync(gradlePath, gradle);
}

// 2. twa-manifest.json holds the app in portrait, which suits a phone: in
//    landscape the number keyboard covers the plate. A Trusted Web Activity
//    has one orientation setting for every device, so on a tablet in
//    landscape the app became a portrait column with black bars. Screens at
//    least 600dp on their short side (tablets, unfolded foldables) are left
//    free to rotate; phones keep the manifest's lock.
if (twa.orientation !== 'portrait') {
  throw new Error('The large-screen patch expects "orientation": "portrait" in twa-manifest.json.');
}
const activityPath = resolve(here, 'app', 'src', 'main', 'java', ...twa.packageId.split('.'), 'LauncherActivity.java');
let activity = readFileSync(activityPath, 'utf8');
if (!activity.includes('isLargeScreen()')) {
  activity = replaceOnce(
    activity,
    'setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_USER_PORTRAIT);',
    'setRequestedOrientation(isLargeScreen()\n'
      + '                    ? ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED\n'
      + '                    : ActivityInfo.SCREEN_ORIENTATION_USER_PORTRAIT);',
    'portrait splash orientation',
  );
  activity = replaceOnce(
    activity,
    '    @Override\n    protected Uri getLaunchingUrl() {',
    `    private boolean isLargeScreen() {
        return getResources().getConfiguration().smallestScreenWidthDp >= 600;
    }

    // The browser applies the orientation carried by the launch intent, so
    // clear the portrait lock there too on large screens.
    @Override
    protected com.google.androidbrowserhelper.trusted.TwaLauncher createTwaLauncher() {
        final boolean largeScreen = isLargeScreen();
        return new com.google.androidbrowserhelper.trusted.TwaLauncher(this) {
            @Override
            public void launch(
                    androidx.browser.trusted.TrustedWebActivityIntentBuilder twaBuilder,
                    androidx.browser.customtabs.CustomTabsCallback customTabsCallback,
                    com.google.androidbrowserhelper.trusted.splashscreens.SplashScreenStrategy splashScreenStrategy,
                    Runnable completionCallback,
                    com.google.androidbrowserhelper.trusted.TwaLauncher.FallbackStrategy fallbackStrategy) {
                if (largeScreen) {
                    twaBuilder.setScreenOrientation(androidx.browser.trusted.ScreenOrientation.DEFAULT);
                }
                super.launch(twaBuilder, customTabsCallback, splashScreenStrategy,
                        completionCallback, fallbackStrategy);
            }
        };
    }

    @Override
    protected Uri getLaunchingUrl() {`,
    'getLaunchingUrl override',
  );
  writeFileSync(activityPath, activity);
}

console.log('Generated project patched: target API 36; large screens rotate, phones stay in portrait.');
