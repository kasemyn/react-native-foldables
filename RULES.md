# Rules

Each rule says what to do, why, and shows bad and good code. Version-specific facts live in [STATUS.md](STATUS.md).

---

## §1 Layout from the window

**Decide layout from the window's width class. Never from the device model, idiom, orientation, or a size read once.**

The same phone is 443dp wide folded and 852dp wide unfolded. A tablet in Split View is narrower than an unfolded foldable. iOS 27 makes every iPhone app resizable (iPhone Mirroring, iPhone apps on iPad), and the iPhone Duo inner display ignores your supported orientations.

Use the Material 3 width breakpoints. They work for both dp and pt:

| Class | Width | Typical windows |
|---|---|---|
| compact | < 600 | Phones, foldable cover screens, iPhone Duo outer display |
| medium | 600–839 | Portrait tablets, *some* unfolded foldables |
| expanded | 840–1199 | Landscape tablets, *some* unfolded foldables, iPhone Duo inner display |
| large | 1200–1599 | Desktop windows |
| extra-large | ≥ 1600 | Maximised desktop windows |

**Measure the real device. Don't assume.** Unfolded foldables straddle the medium/expanded line. Some models change class when rotated, and the user's display-size setting moves them again. See the dp table in [STATUS.md](STATUS.md).

```tsx
// ❌
const { width } = Dimensions.get('window');       // stale after the first fold
const isTablet = DeviceInfo.isTablet();           // a device, not a window
if (orientation === 'landscape') { /* two columns */ }

// ✅
const widthClass = useWindowWidthClass();         // §2
const columnCount = widthClass === 'compact' ? 1 : 2;
```

- Never `Platform.isPad`, `isTablet()`, `userInterfaceIdiom`, `DeviceInfo.getModel()` for layout decisions.
- Never orientation state (`expo-screen-orientation`, `width > height` named "landscape") for layout. Orientation describes the window's shape, not how much room you have.
- Never a module-scope `Dimensions.get`, a `SCREEN_WIDTH` constant, or a fixed width on a root view.
- Height classes (compact < 480, medium 480–899, expanded ≥ 900) matter for tabletop or laptop postures and short desktop windows.

---

## §2 Subscriptions

**Subscribe to the class you branch on, not to raw pixels, and measure the window the app actually lays out in.**

`useWindowDimensions()` has no selector, so every component using it re-renders on every size change the OS reports. Dragging a desktop window reports many. A width class only changes when the window crosses a breakpoint: a 600→1200dp drag crosses it twice.

Take the width from a root view's `onLayout`. That is the size your tree is laid out in, and React Native documents it as firing on mount and on every layout change. `Dimensions` is only the first value, before the first layout event. Mount the provider once at the app root, where it fills the window.

```tsx
import { createContext, useContext, useState, useSyncExternalStore, type ReactNode } from 'react';
import { Dimensions, View, type LayoutChangeEvent } from 'react-native';

export type WindowWidthClass = 'compact' | 'medium' | 'expanded' | 'large' | 'extraLarge';

export function classifyWindowWidth(widthDp: number): WindowWidthClass {
  if (widthDp >= 1600) return 'extraLarge';
  if (widthDp >= 1200) return 'large';
  if (widthDp >= 840) return 'expanded';
  if (widthDp >= 600) return 'medium';
  return 'compact';
}

function createWindowWidthStore(initialWidthDp: number) {
  let widthDp = initialWidthDp;
  const listeners = new Set<() => void>();
  return {
    getWidthClass: () => classifyWindowWidth(widthDp),
    subscribe(listener: () => void) {
      listeners.add(listener);
      return () => listeners.delete(listener);
    },
    setWidth(nextWidthDp: number) {
      widthDp = nextWidthDp;
      listeners.forEach(listener => listener());
    },
  };
}

const WindowWidthStoreContext = createContext<ReturnType<typeof createWindowWidthStore> | null>(null);

export function WindowWidthClassProvider({ children }: { children: ReactNode }) {
  const [store] = useState(() => createWindowWidthStore(Dimensions.get('window').width));
  const updateWidthFromRootLayout = (event: LayoutChangeEvent) =>
    store.setWidth(event.nativeEvent.layout.width);
  return (
    <WindowWidthStoreContext.Provider value={store}>
      <View testID="window-root" style={{ flex: 1 }} onLayout={updateWidthFromRootLayout}>
        {children}
      </View>
    </WindowWidthStoreContext.Provider>
  );
}

export function useWindowWidthClass(): WindowWidthClass {
  const store = useContext(WindowWidthStoreContext);
  if (!store) throw new Error('Wrap the app root in <WindowWidthClassProvider>');
  return useSyncExternalStore(store.subscribe, store.getWidthClass);
}
```

The snapshot is a string, so React skips the re-render when the class hasn't changed. Keep `useWindowDimensions()` for the few components that need exact pixels, such as a canvas or a hinge-aligned divider.

- `getSnapshot` must return a cached or primitive value. If you return a new object every call, React loops.
- For several values (width class + posture), select into a shallow-compared object and cache it. Don't return a fresh literal each time.
- Keep the classification pure (`classifyWindowWidth`) so tests can call it without React.
- Dev-only: `npx jest --config skills/react-native-foldables/examples/jest.config.js` (from a repo with React Native's Jest tooling installed) tests this snippet and checks that it matches this section.

---

## §3 Keep state across layout changes

**Change styles, not element trees.** When the window changes class, the user's typed text, scroll position and focus must survive.

```tsx
// ❌ Swapping trees: React unmounts the detail pane on every fold
return isWide ? <TwoPane list={list} detail={detail} /> : <Stack />;

// ✅ Same tree in every layout; only the styles change
return (
  <View style={{ flexDirection: showsBothPanes ? 'row' : 'column', flex: 1 }}>
    <View style={listPaneStyle}>{list}</View>
    <View style={detailPaneStyle}>{detail}</View>
  </View>
);
```

- When a pane is hidden in single-pane mode, keep it mounted offscreen: `position: 'absolute'`, `opacity: 0`, `pointerEvents: 'none'`, plus `accessibilityElementsHidden` / `importantForAccessibility="no-hide-descendants"`. Don't return `null`.
- Never change a `key`, a navigator type, or a navigator's screen list based on width.
- Reorder visually with `flexDirection: 'column-reverse'` / `'row-reverse'`, not by reordering children.
- **Prove it.** Count mounts in a test, or with a dev-only badge, while cycling through phone → unfolded → desktop → phone.

---

## §4 Android manifest

**The manifest is part of your layout code.** Android recreates the Activity for any configuration change you don't declare, and the React tree goes with it.

```xml
<activity
  android:name=".MainActivity"
  android:configChanges="keyboard|keyboardHidden|navigation|orientation|screenLayout|screenSize|smallestScreenSize|density|uiMode"
  android:windowSoftInputMode="adjustResize">
```

| Missing value | What recreates the Activity |
|---|---|
| `smallestScreenSize` | Unfolding or folding (the Expo bare template lacked it up to SDK 54) |
| `screenSize`, `screenLayout`, `orientation` | Resizing, multi-window, rotation |
| `density` | Moving the window to a display with a different density (external monitor, some foldable cover screens) |

- **`density` is necessary but not sufficient.** React Native's `DisplayMetricsHolder` is initialised once, so after a density change, text and layout can render at the wrong scale. Re-initialise it in `MainActivity.onConfigurationChanged` with `DisplayMetricsHolder.initDisplayMetrics(this)`, then check the open-issue status in [STATUS.md](STATUS.md).
- **Don't depend on `screenOrientation`, `resizeableActivity="false"` or `maxAspectRatio`.** From targetSdk 36, Android ignores them on displays whose smallest width is ≥ 600dp (games are exempt), and the opt-out goes away at targetSdk 37. Phones and cover screens still honour them.
- **Expo:** edit the manifest with a config plugin (`withAndroidManifest` from `expo/config-plugins`) rather than by hand, so `prebuild` keeps the change. `"orientation": "portrait"` in `app.json` has the same large-screen limits.

---

## §5 Folds and hinges

React Native core exposes **no** fold, hinge or posture API. Get fold data from a native module that wraps Jetpack WindowManager's `FoldingFeature` (Android) and UIKit's `reservedRegions(kind: .division)` with `UIHingeInteraction` (iOS 27.1+). You can write one, or use a community package (see [STATUS.md](STATUS.md)). Then:

**Classify posture with a pure function. No device names.**

```ts
type FoldPosture = 'flat' | 'book' | 'tabletop';

function classifyFoldPosture(fold: FoldingFeature | null): FoldPosture {
  if (!fold) return 'flat';
  const splitsTheWindow = fold.state === 'halfOpened' || fold.isSeparating;
  if (!splitsTheWindow) return 'flat';
  return fold.orientation === 'vertical' ? 'book' : 'tabletop';
}
```

- **Fold bounds are in window coordinates.** Your container usually isn't at the window origin, because of a navigation rail or a header. Convert with `measureInWindow` on the container, and only measure while a fold exists, so other devices pay nothing. Edge-to-edge offsets on Android make this easy to get wrong, so test it.
- **Fold events and window resizes are separate streams, and can arrive in either order.** Hold a fold report until the measured window size matches the size the report was computed for, with a short timeout as a fallback. Otherwise you'll draw one frame with a hinge outside the window, or a wide layout with no hinge.
- **Treat the fold as a band, not a line.** It has width. Keep content and controls out of it.
- **Book posture** (vertical fold): split panes on the fold when both panes can keep a usable minimum width (about 240dp). Otherwise fall back to the width-class layout. In right-to-left layouts (`I18nManager.isRTL`) the list pane sits on the right, so its width is the space *after* the fold (`container.x + container.width - (fold.x + fold.width)`), not `fold.x - container.x`.
- **Tabletop / laptop posture** (horizontal fold): content for viewing goes on top, controls go on the stable bottom half.
- **Grids:** prefer an even column count at unfolded widths, so the fold lands on a gutter.
- **Move only what's necessary** when the fold appears. Small adjustments, never a different app.
- **Hinge angle is for effects, never layout.** iOS streams `hinge.angle`, while Android's `TYPE_HINGE_ANGLE` sensor is coarse or absent on some devices. Lay out from posture and fold bounds.
- **Width class alone can't tell you the arrangement.** A flip phone in flex mode is compact yet split by its hinge. Expose "single pane / side by side / split by hinge" separately from the width class.

---

## §6 Safe areas

**Insets are asymmetric now.** On iPhone Duo, the system bar strip sits on one side only, and in Split View it sits on each app's *outer* edge, so it can be on the left. Android caption bars and cutouts are one-sided too.

```tsx
const insets = useSafeAreaInsets();

// ❌ Mirrors one side onto the other
<View style={{ paddingHorizontal: insets.left }} />
const contentWidth = width - insets.left * 2;

// ✅ Each side on its own
<View style={{ paddingLeft: insets.left, paddingRight: insets.right }} />
const contentWidth = width - insets.left - insets.right;
```

**Sizing for the safe area isn't enough. You have to centre inside it too.**

```ts
function insetRect(rect: Rect, insets: EdgeInsets): Rect {
  return {
    x: rect.x + insets.left,
    y: rect.y + insets.top,
    width: rect.width - insets.left - insets.right,
    height: rect.height - insets.top - insets.bottom,
  };
}
// Centre dialogs in insetRect(window, insets), not in the whole window.
```

- Foreground and interactive content goes inside the safe area. Background art may extend past it.
- Use `react-native-safe-area-context`. RN core's `SafeAreaView` is deprecated and iOS-only.
- Test with the app on **both** sides of Split View.

---

## §7 iOS and iPhone Duo

- **Only native bars move to the side.** On the iPhone Duo outer display, and on the inner display in landscape, the system moves toolbars and tab bars into a vertical strip, but only bars it manages.
  - JS-drawn tab bars and JS headers (`@react-navigation/stack`) stay where you drew them. Which tab bars are JS-drawn depends on the React Navigation version: in v7, `createBottomTabNavigator` is JS-drawn; in v8 (pre-release) it is native by default, and `implementation: 'custom'` brings back the JS tabs. The audit script resolves the version from the nearest `package.json`.
  - Native tabs (`createNativeBottomTabNavigator`, `react-native-bottom-tabs`, Expo Router `NativeTabs`) take part. So do `native-stack` headers.
  - Custom React views inside native headers (`headerRight`) are custom views, which the system keeps horizontal.
  - Check the release status of each option in [STATUS.md](STATUS.md).
- **Vertical bars need the iOS 27.1 SDK.** Builds without the iOS 27 SDK run boxed beside the status bar and camera.
- **iOS 27 SDK builds require the UIScene lifecycle.** Without a scene delegate (`UIApplicationSceneManifest` in `Info.plist`), the app crashes at launch. Check which React Native template version ships it ([STATUS.md](STATUS.md)) before upgrading Xcode.
- **Orientation locks won't protect your layout** on the iPhone Duo inner display, and `UIRequiresFullScreen` doesn't stop resizing.
- **New windows (scenes) can only open on the inner display.** Handle failure of a scene request.
- Any front-camera request gets Apple's Virtual Front Camera, which switches inner ↔ outer automatically.

---

## §8 Overlays

- **System components avoid the fold on iPhone Duo** (Apple's HIG lists alerts, context menus, sheets, popovers and split views). React Native's `Alert` is backed by `UIAlertController`, so it is a system alert.
- **Unverified:** whether RN `Modal` with `presentationStyle: 'pageSheet'` or `'formSheet'`, or a React Navigation native-stack modal presentation, avoids the fold. Don't assume it. Check each one on the Xcode 27.1 iPhone Duo simulator, with the fold open and the sheet at its largest, before relying on it.
- **Overlays drawn in JS don't.** That covers bottom sheets, custom dialogs, toasts and popovers. When a separating fold exists, place them wholly on one side of it: trailing side in book posture, bottom half in tabletop. Don't centre them across it.
- Account for the keyboard and the safe area when choosing the side (§6).

---

## §9 Testing

**Make the display injectable**, so tests can change it. Put window size, safe-area insets and fold features behind a context or store you control, rather than reading `Dimensions` or a native module directly in components.

```tsx
const display = createTestDisplay(DEVICES.phone);
render(<AccountsScreen />, { wrapper: display.Provider });
fireEvent.changeText(screen.getByTestId('detail-input'), 'still here');

act(() => display.change(DEVICES.foldableUnfoldedBook));
expect(screen.getByTestId('detail-input')).toHaveDisplayValue('still here');
expect(mountCount('AccountDetail')).toBe(1);
```

Device presets worth covering (dp/pt; confirm against [STATUS.md](STATUS.md)):

| Preset | Window | Fold |
|---|---|---|
| Phone | 411 × 914 | none |
| Foldable cover | ~443 wide | none |
| Unfolded, medium (e.g. Galaxy Z Fold5) | 690 × 829 | vertical, flat |
| Unfolded, expanded (e.g. Pixel 9 Pro Fold) | 852 × 883 | vertical, flat → half-opened |
| Tabletop | landscape unfolded | horizontal, half-opened |
| iPhone Duo outer / inner | 466 × 678 / 951 × 669 | inner: vertical band ~40pt |
| Desktop window | 1280 × 800, 1920 × 1080 | none |

- Write a cycle test: phone → unfolded → book → tabletop → desktop → phone, asserting that state survives.
- **Android emulator:** use the foldable AVDs (Pixel Fold, Pixel 9 Pro Fold) and the resizable emulator. Script postures with `adb shell cmd device_state print-states` and `adb shell cmd device_state state <id>`.
- **iOS:** use the iPhone Duo simulator in Xcode 27.1's Device Hub. It has buttons to open, close, rotate and fold. For Split View, drag the app by its home indicator to one side, then the other.
- Emulators don't reproduce real hinge timing. Test the event-ordering logic (§5) in unit tests.
