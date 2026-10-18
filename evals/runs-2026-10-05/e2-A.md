## Diagnosis

Your manifest's `configChanges` is the stock RN template list:

```
keyboard|keyboardHidden|orientation|screenLayout|screenSize|smallestScreenSize|uiMode
```

It is missing **`density`**. That explains why folding is fine and dragging to a monitor is not. Folding changes size and smallest-width, which you declare. Dragging the window to an external monitor (Pixel connected-display desktop windowing, GA since Android 16 QPR3: Pixel 8/9/10) moves it to a display with a different density. Android then treats that as an undeclared configuration change and recreates `MainActivity`. The React tree goes with it, so users lose their place.

(The stock RN template omits `density` too, so this isn't something you did wrong. Desktop windowing is what exposes it.)

`audit.sh` finds nothing here. It only does static greps, so the missing `density` has to be caught by reading the manifest.

## Fix

1. Add `density` (and `navigation`, which RULES.md also lists) to `configChanges`:

```xml
<activity
  android:name=".MainActivity"
  android:configChanges="keyboard|keyboardHidden|navigation|orientation|screenLayout|screenSize|smallestScreenSize|density|uiMode"
  android:launchMode="singleTask"
  android:windowSoftInputMode="adjustResize"
  android:exported="true">
```

2. **`density` alone isn't enough.** React Native's `DisplayMetricsHolder` is initialised once, so after the move, text and layout can render at the wrong scale. Re-initialise it in `MainActivity.onConfigurationChanged` with `DisplayMetricsHolder.initDisplayMetrics(this)`. This is a known open RN issue (react-native #57183, fix PRs pending per STATUS.md as of 5 Oct 2026), so re-check its status before relying on it.

3. If you use Expo, make the change through a config plugin (`withAndroidManifest`) so `prebuild` doesn't overwrite it.

## Related notes

- Don't try to fix this with `resizeableActivity="false"`, `screenOrientation` or `maxAspectRatio`. From targetSdk 36, Android ignores them on displays at least 600dp wide (an external monitor qualifies), and the opt-out goes away at targetSdk 37.
- Test by connecting a Pixel to a monitor in desktop mode, dragging the app across, and checking that state survives and the text scale is right on both displays.
