---
name: react-native-foldables
description: Build and audit React Native apps for screens that change shape — Android foldables and flip phones, resizable and desktop windows (tablets, phones on a monitor, iPad Split View, iPhone Mirroring) and Apple's iPhone Duo. Use when writing or reviewing layout, navigation, safe-area, AndroidManifest or Info.plist code in a React Native or Expo app, when a user mentions foldables, hinges, fold posture, size classes, desktop windowing, multi-window, Split View or iPhone Duo, or asks "does my app work on a foldable?".
---

# React Native on foldables, resizable windows and iPhone Duo

One rule underneath everything: **branch on the window you're given, never on the device you think you're on.** Your app doesn't own the screen. It gets a window, and the window changes size, splits around a hinge, and moves between displays while the app runs.

## Quick start

```tsx
// ❌ Device, orientation and a size read once at import time
const { width } = Dimensions.get('window');
const isTablet = Platform.isPad || width > 600;

// ✅ A width class read inside the component, re-rendering only when the class changes
const widthClass = useWindowWidthClass(); // see RULES.md §2 for the tested hook (examples/windowWidthClass.tsx)
const showsBothPanes = widthClass !== 'compact';
```

## Workflow: writing or changing code

Before touching layout, navigation, safe areas, overlays or native config, read the matching section of [RULES.md](RULES.md):

| You're touching | Read |
|---|---|
| Breakpoints, "is this a tablet?", orientation | §1 Layout from the window |
| `useWindowDimensions`, resize performance | §2 Subscriptions |
| One pane ↔ two panes, lost input or scroll | §3 Keep state across layout changes |
| `AndroidManifest.xml`, Expo config plugins | §4 Android manifest |
| Hinges, fold posture, split position | §5 Folds and hinges |
| `useSafeAreaInsets`, centring, padding | §6 Safe areas |
| Tab bars, headers, `Info.plist`, Xcode/SDK upgrades | §7 iOS and iPhone Duo |
| Sheets, modals, toasts | §8 Overlays |
| Tests, emulators, simulators | §9 Testing |

The §2 hook is real code in [examples/](examples/), with Jest tests that also check RULES.md hasn't drifted from it. Run them with `npx jest --config skills/react-native-foldables/examples/jest.config.js` from a repo with React Native's Jest tooling. The audit script has a regression suite too: `bash scripts/test-audit.sh` runs it against the scenarios in `scripts/fixtures/`. Both are dev-only: the skill works by reading the markdown.

Version-sensitive facts (SDK betas, library releases, which packages exist) are in [STATUS.md](STATUS.md). Check its "as of" date, and re-verify anything older than a couple of months before relying on it.

## Workflow: auditing an app

1. Run the static checks from the app's root:
   `bash <skill-dir>/scripts/audit.sh [app-root]`
   The script prints `SEVERITY path:line — problem — fix`, and exits 1 if anything is `BLOCKING`.
2. Review what grep can't see. For each item, read the code, don't pattern-match:
   - [ ] Width-conditional **element trees** (`wide ? <A/> : <B/>`) on screens with input, scroll or focus (RULES §3)
   - [ ] Hinge or fold rectangles used without converting to the container's coordinates (RULES §5)
   - [ ] Interactive controls or centred hero content that can land on the fold (RULES §5)
   - [ ] Overlays drawn in JS (bottom sheets, dialogs, toasts) with no hinge awareness (RULES §8)
   - [ ] RN `Modal` `pageSheet`/`formSheet` or native-stack modals: not verified to avoid the iPhone Duo fold, so say "verify on the simulator" (RULES §8)
   - [ ] Centring done in the full window instead of inside the safe area (RULES §6)
   - [ ] JS-drawn tab bars or headers in an app that ships on iOS (RULES §7)
3. Report findings grouped by severity, one per line:

```md
**Blocking**: hidden, unreachable, crashes or loses user data on fold, unfold, resize or display move
- android/app/src/main/AndroidManifest.xml:17 — configChanges lacks smallestScreenSize — Activity recreated on unfold; add it
**Should fix**: works but wrong (layout on the hinge, stale size, mirrored insets)
- src/screens/Checkout.tsx:42 — paddingHorizontal: insets.left — mirrors one side; use paddingLeft/paddingRight
**Nice to have**: polish, performance, future-proofing
- src/hooks/useLayout.ts:8 — useWindowDimensions in a widely used hook — re-renders on every size change; select a width class
```

If a file is clean, say so in one line. Don't invent findings to fill a section.

## What not to say or write

These are wrong, or out of date: "folding destroys the React tree on the stock template" (it hasn't since about RN 0.68, apart from density changes and Expo SDK ≤ 54) · "an unfolded foldable is `medium`" (depends on the model; measure it) · "`screenOrientation` is ignored" (only on large screens) · "add `density` and you're done" (see RULES §4) · any fold or hinge API in React Native core (there isn't one) · any iPhone Duo API name not in Apple's docs.
