# Eval: react-native-foldables skill, with vs without

Written 5 Oct 2026, before any run. Each prompt runs twice on Sonnet: **A = with the skill**, **B = without it**. Runs can't use the web, so we measure the skill rather than browsing. A separate Sonnet grader scores the answers blind, under shuffled labels, against the rubric below.

Score per prompt = sum of points earned − penalties. Max points are listed per prompt. One run per condition, so treat differences of 1–2 points as noise.

---

## E1: Review a screen (fixture `e1/AccountsScreen.tsx`)

**Prompt:** "Review `AccountsScreen.tsx` for problems on foldables, resizable windows and the iPhone Duo. List concrete findings with line references and fixes, most severe first."

| Points | Criterion |
|---|---|
| 2 | Identifies that `isWide ? <row/> : <Stack.Navigator/>` swaps element trees, so typed input (the payment reference) and state are lost on fold/unfold, and ranks it as the most severe or among the most severe |
| 1 | Module-scope `Dimensions.get` is stale after fold/resize |
| 1 | `Platform.isPad` is a device check, not a window check |
| 1 | `paddingHorizontal: insets.left` mirrors one inset; use left and right separately |
| 1 | Recommends a width-class-based subscription, or explains that `useWindowDimensions` re-renders on every size change (either counts) |
| 1 | Fix keeps one element tree and changes styles (or keeps the hidden pane mounted) |
| **Max 7** | |
| −1 each | Invents a React Native core API (e.g. a fold/hinge API in `react-native`), or a non-existent package presented as real |

## E2: Restart on external monitor (fixture `e2/AndroidManifest.xml`)

**Prompt:** "Users on Pixel phones say our React Native app restarts and loses their place when they drag it onto an external monitor. Folding the phone is fine. Here's our AndroidManifest. What's wrong and how do we fix it?"

| Points | Criterion |
|---|---|
| 2 | Identifies `density` missing from `configChanges` as the cause (different display density → Activity recreated) |
| 1 | Gives a correct fixed `configChanges` line that includes `density`, and doesn't drop existing values |
| 1 | Warns that handling `density` can leave RN's display metrics/text scale stale (DisplayMetricsHolder or equivalent), or suggests verifying text scale on the external display |
| 1 | Correctly treats folding as already handled by `screenSize`/`smallestScreenSize`/`screenLayout` (doesn't claim those are missing) |
| **Max 5** | |
| −1 each | Claims the stock config recreates on fold; tells them to rely on `screenOrientation`/`resizeableActivity="false"` as a fix; invents manifest attributes |

## E3: Build a two-pane layout (fixture `e3/InvoicesNavigator.tsx`)

**Prompt:** "Turn this invoices flow into a list/detail layout that shows both panes side by side on unfolded foldables, tablets and the iPhone Duo inner display, and one pane on phones. Write the code."

| Points | Criterion |
|---|---|
| 2 | Same element tree in both modes; switching modes doesn't unmount the detail (no `wide ? <A/> : <B/>` swap and no navigator swap) |
| 1 | Branches on window width/size class (not device, idiom or orientation), with breakpoints at or near 600/840 |
| 1 | Hidden pane stays mounted and is hidden from touches and accessibility (or explicitly keeps state another valid way) |
| 1 | Reads safe-area insets per side (no mirrored insets) |
| 1 | Handles back/selection correctly in single-pane mode (back from detail returns to list) |
| **Max 6** | |
| −1 each | Uses a non-existent package or RN core API for folds/hinges as if it existed; claims RN core reports the hinge |

## E4: Tab bar on iPhone Duo (fixture `e4/AppTabs.tsx`)

**Prompt:** "Will this tab bar behave correctly on the iPhone Duo? We're on React Navigation 7 and RN 0.87.1. What do we need to change, if anything?"

| Points | Criterion |
|---|---|
| 2 | Says JS-drawn `createBottomTabNavigator` won't move to the Duo's vertical side bar; only native bars do |
| 1 | Names at least one real native-tabs option correctly: `createNativeBottomTabNavigator` from `@react-navigation/bottom-tabs/unstable`, `react-native-bottom-tabs`, or Expo Router `NativeTabs` |
| 1 | Mentions the iOS 27.1 SDK / Xcode 27.1 requirement for vertical bars |
| 1 | Flags the UIScene lifecycle requirement for iOS 27-SDK builds (RN 0.87 template lacks a SceneDelegate; 0.88 adds it) |
| 1 | Notes `headerRight` custom content may stay horizontal, or tests on the iPhone Duo simulator |
| **Max 6** | |
| −1 each | Claims React Navigation v8 is released, or that `createBottomTabNavigator` is already native in v7; invents Duo APIs |

## E5: Snap the divider to the hinge (fixture `e5/SplitLayout.tsx`)

**Prompt:** "On a Pixel Fold the divider between our list and detail lands about 80dp to the right of the fold. Why, and how do we fix it?"

| Points | Criterion |
|---|---|
| 2 | Hinge bounds are in window coordinates, and the container is offset by the 80dp rail. Converts with `measureInWindow` (or subtracts the container's window x) |
| 1 | Guards against a pane getting too narrow (minimum pane width), falling back otherwise |
| 1 | Handles RTL (list on the right) |
| 1 | Only measures while a hinge exists, or otherwise avoids per-frame measurement during resizes |
| 1 | Accounts for the hinge's width (the detail starts after `hinge.x + hinge.width`) |
| **Max 6** | |
| −1 each | Hardcodes 80 instead of measuring, as the final fix; invents APIs |

---

**Total max: 30.**
