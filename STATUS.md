# Status: version-sensitive facts

**As of 5 October 2026.** Everything here changes with releases. Re-verify anything older than about two months, and update the date when you do.

## React Native and Expo

| Fact | Source |
|---|---|
| The RN community template's `configChanges` is `keyboard\|keyboardHidden\|orientation\|screenLayout\|screenSize\|smallestScreenSize\|uiMode`. It has no `density` or `navigation`, and has handled folding since about 0.68. | [template manifest](https://raw.githubusercontent.com/react-native-community/template/0.87-stable/template/android/app/src/main/AndroidManifest.xml) |
| Expo bare template: no `smallestScreenSize` up to SDK 54, added in SDK 55, and never `density`. | [Expo template](https://raw.githubusercontent.com/expo/expo/sdk-57/templates/expo-template-bare-minimum/android/app/src/main/AndroidManifest.xml) |
| `DisplayMetricsHolder` isn't updated after a density change (wrong text scale on a display with a different density). Open, and fix PRs are pending. | [react-native #57183](https://github.com/react/react-native/issues/57183) |
| The RN 0.87 template has no SceneDelegate, so it crashes at launch when built with the iOS 27 SDK. The 0.88 template adds it. | [template #251](https://github.com/react-native-community/template/pull/251) |
| The RN core team is moving RNTester's JS tab bar to a native `UITabBarController` for iPhone Duo. | [react-native #58664](https://github.com/react/react-native/pull/58664) |
| Expo SDK 58 (beta) adopts the iOS 27 scene lifecycle. `requireFullScreen` no longer prevents resizing. | [Expo SDK 58 beta](https://expo.dev/changelog/sdk-58-beta) |
| Expo dev builds break the iPhone Duo vertical status bar (release builds are fine). | [expo #50934](https://github.com/expo/expo/issues/50934) |

## Navigation

| Fact | Source |
|---|---|
| React Navigation v7 has `createNativeBottomTabNavigator` in `@react-navigation/bottom-tabs/unstable`. Its API may change in a minor release. | [docs](https://reactnavigation.org/docs/native-bottom-tab-navigator) |
| React Navigation v8 is **pre-release**. In v8, `createBottomTabNavigator` is native by default, and `implementation: 'custom'` brings back JS tabs. Left/right tab positions are custom-only. | [v8 upgrade guide](https://reactnavigation.org/docs/8.x/upgrading-from-7.x) |
| `react-native-bottom-tabs` (Callstack) is actively maintained. | [npm](https://www.npmjs.com/package/react-native-bottom-tabs) |
| Expo Router `NativeTabs`: `unstable-native-tabs` in SDK 54–57, stable in SDK 58 (beta). | [docs](https://docs.expo.dev/router/advanced/native-tabs/) |
| react-native-screens has open iPhone Duo PRs: Pressables in moved headers get cancelled (#4758), the back button floats (#4770), and a `preferredVerticalBarBehavior` opt-out (#4768). | [react-native-screens PRs](https://github.com/software-mansion/react-native-screens/pulls) |

## Fold and hinge packages (none are in RN core)

These exist on npm. None is an endorsement, so check maintenance and platform coverage before you adopt one.

- `react-native-reserved-regions` (App&Flow): iOS 27.1 reserved regions + Jetpack WindowManager
- `@jusev/react-native-fold`
- `react-native-fold-kit`
- `react-native-nitro-hinge`
- `@cawrestler/react-native-duo` (preview)
- `react-native-duo` 0.0.1 (placeholder only)
- Microsoft's `react-native-dualscreeninfo` / `react-native-twopaneview` (Surface Duo): unmaintained since 2023

## Android platform

| Fact | Source |
|---|---|
| Large (1200) and extra-large (1600) width classes are stable in `androidx.window` 1.5.0. | [release notes](https://developer.android.com/jetpack/androidx/releases/window) |
| From targetSdk 36, orientation, resizability and aspect-ratio restrictions are ignored on displays with smallest width ≥ 600dp. Games are exempt. The opt-out property `android.window.PROPERTY_COMPAT_ALLOW_RESTRICTED_RESIZABILITY` is removed at targetSdk 37. | [Android 16](https://developer.android.com/about/versions/16/behavior-changes-16) · [Android 17](https://developer.android.com/blog/posts/prepare-your-app-for-the-resizability-and-orientation-changes-in-android-17) |
| Connected-display desktop windowing went generally available in Android 16 QPR3 (March 2026): Pixel 8/9/10, Galaxy S26, Fold7, Flip7, Tab S11. | [Android Developers Blog](https://android-developers.googleblog.com/2026/03/android-devices-extend-seamlessly-to.html) |
| `WindowInfoTracker.getCurrentWindowLayoutInfo()` (WindowManager 1.5) returns a synchronous fold snapshot. | [FoldingFeature](https://developer.android.com/reference/androidx/window/layout/FoldingFeature) |

### Unfolded widths (inner display)

| Device | Portrait / landscape (dp) | Class | Confidence |
|---|---|---|---|
| Pixel Fold | 701 / 841 | medium / expanded | Android Studio device definition |
| Pixel 9 Pro Fold, Pixel 10 Pro Fold | ~852 / 883 | expanded | AVD config (2076×2152 @ 390dpi) |
| Galaxy Z Fold5 | ~690 / 829 | medium | spec ÷ assumed 420dpi |
| Galaxy Z Fold7 | conflicting | ? | measure it (Samsung Remote Test Lab) |
| Galaxy Z Fold8 (4:3 inner) | ~933 wide | likely expanded | spec ÷ assumed 420dpi |

## iPhone Duo (iOS 27.1)

| Fact | Source |
|---|---|
| Announced 9 Sept 2026. Ships 23 Oct 2026 on iOS 27.1. | [Apple Newsroom](https://www.apple.com/newsroom/2026/09/apple-unveils-iphone-duo/) |
| Xcode 27.1 is beta. App Store Connect accepts 27.1-SDK builds for TestFlight only. | [Apple Developer News](https://developer.apple.com/news/) |
| Approximate points: outer 466 × 678, inner 951 × 669 (Apple's screenshot sizes ÷ 3). Apple doesn't state them as points. | [screenshot specs](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications) |
| Measured on the simulator: vertical strip ~84pt (safe-area `right: 84`, `bottom: 34` when closed), fold band ~40pt wide. Single sources, so measure yourself. | [simulator write-up](https://blakecrosley.com/blog/xcode-27-1-beta-iphone-duo-simulator) · [tlon-apps #6612](https://github.com/tloncorp/tlon-apps/pull/6612) |
| Fold and hinge APIs (public docs, beta): `reservedRegions(kind: .division / .occlusion)`, `onHingeChange` / `UIHingeInteraction` (`UIHinge.Status` includes `.unknown`; `angle` is in radians with no guaranteed rate), `ArrangementView` / `UIArrangementViewController`. | [Preparing your app for iPhone Duo](https://developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo) |
| Apple's docs disagree on whether an inactive (flat) fold region is returned, so check `isActive`. | tech talk 111463 vs `ReservedRegion` docs |
| System components (alerts, context menus, sheets, popovers, split views) avoid the fold per Apple's HIG. **Unverified:** RN `Modal` `pageSheet`/`formSheet` and React Navigation native-stack modals. Check on the Xcode 27.1 iPhone Duo simulator. | [HIG: Designing for iPhone Duo](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo) |
| Design guidance: [HIG: Designing for iPhone Duo](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo) · tech talks 111461–111466 | Apple |
