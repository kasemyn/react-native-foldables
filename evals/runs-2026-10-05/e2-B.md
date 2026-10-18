# Why the app restarts when dragged to an external monitor

## What's wrong

The `android:configChanges` on `MainActivity` is missing **`density`**:

```
keyboard|keyboardHidden|orientation|screenLayout|screenSize|smallestScreenSize|uiMode
```

Folding only changes size, orientation and layout. `screenSize`, `smallestScreenSize`, `screenLayout` and `orientation` are all declared, so the activity handles those itself. That is why folding works.

Moving the window to an external display is different. The external monitor usually has a different DPI from the phone panel, so Android reports a **density** configuration change as well. `density` isn't declared, so Android destroys and recreates `MainActivity`. The React Native host is rebuilt, JS state and navigation state are lost, and users end up back at the start.

## Fix

Add the missing flags. The usual full set for resizable and desktop windows is:

```xml
<activity
  android:name=".MainActivity"
  android:configChanges="keyboard|keyboardHidden|orientation|screenLayout|screenSize|smallestScreenSize|uiMode|density|layoutDirection|fontScale|colorMode|locale"
  ...
```

`density` is the one causing this bug. The others (`layoutDirection`, `fontScale`, `colorMode`, `locale`) can also change when a window moves between displays or when the user changes system settings. Adding them avoids similar restarts. Also check that your `MainActivity` forwards `onConfigurationChanged` to React Native. The default template does this, so this is only a concern if it has been customised.

## Other things to check

- **Don't lock the activity.** Make sure there is no `android:resizeableActivity="false"` and no fixed `screenOrientation`. The manifest you sent has neither, which is good. Apps targeting a recent SDK (36+) will have these restrictions ignored on large screens anyway.
- **Layout.** Don't read `Dimensions.get('screen')` once at startup. Use `useWindowDimensions()` so layouts and pixel ratios update when the window moves between displays. After the fix the activity stays alive, so the JS side has to react to the change itself.
- **Persist navigation state anyway.** Process death and other config changes can still happen. Persisting nav state (for example React Navigation's `initialState` and `onStateChange`) is a useful backstop.
- **Check `launchMode="singleTask"`.** It's fine here, but if you ever see a new task or window instead of a restart, look there.

## How to verify

1. Rebuild and install the app.
2. Connect a Pixel to an external display with desktop mode enabled, or use the "Desktop experience features" developer option or a desktop-mode emulator.
3. Navigate deep into the app and drag the window to the other display.
4. Confirm there is no activity recreation. Run `adb logcat | grep -i "ActivityTaskManager\|relaunch"` and check that no relaunch is logged.
5. Confirm the layout re-renders at the new density.
