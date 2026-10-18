## Short answer

No, not as written. On the iPhone Duo this tab bar won't move to the side, and your iOS 27 builds will crash at launch on RN 0.87.1 until you add a scene delegate.

Facts below are from the foldables skill's STATUS.md, as of 5 Oct 2026. iPhone Duo ships 23 Oct 2026 on iOS 27.1.

## Findings

**1. Blocking: the app crashes at launch with the iOS 27 SDK (RULES §7, STATUS)**
- The RN 0.87 template has no SceneDelegate. Builds with the iOS 27 SDK crash at launch without a scene delegate (`UIApplicationSceneManifest` in `Info.plist`).
- The 0.88 template adds it (react-native-community/template #251).
- Check this before you upgrade Xcode. Either port the scene lifecycle setup from the 0.88 template into your iOS project, or move to 0.88.
- Vertical bars also need the iOS 27.1 SDK. Builds made without the iOS 27 SDK run boxed beside the status bar and camera.
- Xcode 27.1 is beta, and App Store Connect only takes 27.1-SDK builds for TestFlight.

**2. Should fix: `createBottomTabNavigator` in React Navigation v7 is a JS-drawn tab bar (RULES §7)**
- On the iPhone Duo outer display, and on the inner display in landscape, the system only moves bars it manages into a vertical strip.
- A JS-drawn tab bar stays where you drew it, at the bottom. It will not take part in the vertical strip.
- Your `package.json` pins `@react-navigation/bottom-tabs ^7.19.2`. In v7 this navigator is JS-drawn.
- The bar is still reachable and usable. It just doesn't adopt the Duo layout, and it may sit in the area the system uses for its strip.
- Measured simulator values, from single sources so check them yourself: the vertical strip is about 84pt, with safe-area `right: 84` and `bottom: 34` when closed. Check that the bar stays inside the safe area.

Options:
- **Switch to native tabs.** In v7 that is `createNativeBottomTabNavigator` from `@react-navigation/bottom-tabs/unstable`. Its API may change in a minor release, so pin the version. Alternatives are `react-native-bottom-tabs` (Callstack, actively maintained) or Expo Router `NativeTabs` if you use Expo Router.
- **Wait for v8.** It is pre-release. There `createBottomTabNavigator` is native by default, and `implementation: 'custom'` brings back JS tabs. Don't plan a release around a pre-release version.
- **Keep the JS tabs** and accept that they won't move. Check the safe-area handling on the simulator.

Switching to native tabs has these effects on your code:
- Native tabs have their own options. Check that `tabBarBadge` and the header behaviour carry over.
- `native-stack` headers take part in the vertical layout, so JS headers (`@react-navigation/stack`) do not.

**3. Should fix: `headerRight: () => <ProfileButton />` is a custom view (RULES §7)**
- Custom React views inside native headers are custom views, which the system keeps horizontal.
- With the default JS header from bottom-tabs, it stays where you drew it.
- If you move to native tabs or native-stack headers, `ProfileButton` stays horizontal. This is expected, but react-native-screens has open iPhone Duo PRs for headers: Pressables in moved headers get cancelled (#4758), the back button floats (#4770), and a `preferredVerticalBarBehavior` opt-out (#4768). Test `ProfileButton` taps on the simulator.

## What I could not verify

- How a JS tab bar looks on the Duo inner display in each posture. Open the Xcode 27.1 Device Hub iPhone Duo simulator and test closed, open, rotated and folded.
- Whether any modals you present from these tabs avoid the fold. RN `Modal` `pageSheet`/`formSheet` and native-stack modals are unverified. RN `Alert` is a system alert, so it is fine.
- Expo dev builds break the Duo vertical status bar (expo #50934). Test on a release build if you use Expo.

## What to do, in order

1. Fix the scene lifecycle (the 0.87 crash).
2. Decide on native tabs or JS tabs, based on how much of the Duo layout you need.
3. Test on the Duo simulator with the fold open, closed and rotated.
