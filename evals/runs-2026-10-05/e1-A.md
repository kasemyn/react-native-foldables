# Review: AccountsScreen.tsx (foldables, resizable windows, iPhone Duo)

I ran the skill's `audit.sh` (3 should-fix hits) and then read the file for what grep can't see. Findings are most severe first. Line numbers refer to `AccountsScreen.tsx`. RULES § references point to the react-native-foldables skill.

## Blocking

**1. Lines 25-38: the element tree swaps with width, so typed input and navigation state are lost (RULES §3).**
- Wide returns a `View` containing `FlatList` and `AccountDetail`. Compact returns a `Stack.Navigator`. These are different trees, so React unmounts one and mounts the other whenever `isWide` flips.
- On fold, unfold or window resize, `AccountDetail`'s `note` state (the "Payment reference" `TextInput`, line 12 and line 16) is destroyed. The user loses what they typed. Scroll position and focus are lost too.
- The navigator's screen list also changes with width, which the rules forbid.
- Today the swap rarely fires, but only because of finding 2. Once you fix finding 2, this one becomes live.
- Fix: render one tree in every layout and change only styles.
  - Keep list and detail in the same `View`. Set `flexDirection: showsBothPanes ? 'row' : 'column'`, plus `flex: 1`.
  - In compact mode, hide the inactive pane but keep it mounted: `position: 'absolute'`, `opacity: 0`, `pointerEvents: 'none'`, `accessibilityElementsHidden`, `importantForAccessibility="no-hide-descendants"`. Don't return `null`.
  - If you need a push-style drill-down in compact mode, drive it from `selected` state inside the same tree. Don't switch to a different navigator type.
- Prove the fix with a mount-count test that cycles phone, unfolded, desktop, phone (RULES §9). Assert `AccountDetail` mounts once and the typed text survives.

## Should fix

**2. Lines 7-8: the size is read once at import time, so the layout never reacts to fold or resize (RULES §1-2).**
- `const { width } = Dimensions.get('window')` at module scope is stale after the first fold, unfold, split-screen change or desktop-window drag. `isWide` is frozen at whatever the window was when the bundle loaded.
- An app launched folded (about 443dp) stays single pane after unfolding. An app launched in a wide window stays two pane after shrinking.
- Fix: delete both constants. Read a width class inside the component with `useWindowWidthClass()` (RULES §2, which takes the width from a root `onLayout`). Then set `const showsBothPanes = widthClass !== 'compact'`.
- This re-renders only when the class changes, not on every pixel of a drag.
- Mount `WindowWidthClassProvider` once at the app root.

**3. Line 8: `Platform.isPad` is a device check, not a window check (RULES §1).**
- An iPad in Split View can be narrower than an unfolded foldable.
- iOS 27 makes iPhone apps resizable (iPhone Mirroring and iPhone apps on iPad), and the iPhone Duo inner display is about 951pt wide.
- `Platform.isPad` forces two panes on an iPad even in a 320pt Split View slot. It never gives two panes on an iPhone Duo inner display or a wide Android foldable.
- Fix: remove it. The width class is the only input.
- The `840` threshold is the right "expanded" boundary, but a single magic number is the wrong shape. Use `classifyWindowWidth`.
- Medium (600-839) windows, such as a Galaxy Z Fold5 unfolded at about 690dp, currently count as single pane. Decide deliberately whether medium gets two panes. Measure the real devices (STATUS.md has the dp table).

**4. Line 27: `paddingHorizontal: insets.left` mirrors one inset onto both sides (RULES §6).**
- Insets are asymmetric now. On the iPhone Duo the system strip sits on one side. The simulator measured about `right: 84`, and in Split View it sits on the app's outer edge, which can be the left. Android caption bars and cutouts are one-sided too.
- This code gives the right side the left inset. On Duo, content can run under the strip on the right while the left gets padding it doesn't need.
- Fix: `paddingLeft: insets.left, paddingRight: insets.right`.
- You also ignore `insets.top` and `insets.bottom`, so on Duo (`bottom: 34` when closed) and under Android caption bars the foreground content can sit under system UI. Apply all four insets, or wrap the screen in a `react-native-safe-area-context` `SafeAreaView` / edges handling.
- The compact branch is not inset at all by this component, so check that the navigator handles it.

**5. Lines 27-31: nothing keeps the panes off the hinge on foldables and iPhone Duo (RULES §5).**
- The two-pane layout has no `flex` or width on the list or the detail, so the split point falls wherever content sizing puts it. In book posture it can land on the fold band. On Duo the band is about 40pt wide, and the `TextInput` or list rows can sit on it.
- React Native core has no fold API (RULES §5), so this needs a native module (STATUS.md lists the packages) or a deliberate design choice.
- Minimum fix: give the panes explicit proportions, for example list `flex: 1` and detail `flex: 2`, with a gutter, and test on the foldable emulator and Duo simulator.
- Proper fix: take the fold bounds, convert them from window to container coordinates with `measureInWindow`, and split on the fold when both sides keep about 240dp. Otherwise fall back to the width-class layout. Keep controls out of the band.

## Nice to have

**6. Lines 34-37: `AccountListScreen` and `AccountDetailScreen` are not defined or imported in this file.**
- This is a compile or runtime error as written, or they live elsewhere that I can't see.
- Even if they exist, `AccountDetailScreen` has no way to receive `selected`. In compact mode, the selection from the wide layout does not carry over.
- Becomes moot once finding 1 is fixed with one tree.

**7. Line 11-19: `AccountDetail`'s `note` state is shared across accounts.**
- Selecting a different account (line 28) doesn't remount `AccountDetail`, so the typed reference carries over to the new account.
- That is probably wrong for a payment reference, and separate from the fold issue.
- Don't fix it by changing `key` on width (RULES §3 forbids that). If you want per-account notes, key on `account.id` or keep notes in a map keyed by account. That is a deliberate data decision.

**8. Line 28: list basics.**
- The `FlatList` has no `keyExtractor`.
- Rows are bare `<Text onPress>`, with no `accessibilityRole` and no minimum touch target.
- The list has no `flex: 1` or `style` and the root `View` has no `flex: 1`, so in a tall resizable window the layout won't fill it.
- Fix: add `flex: 1` to the root and the panes, a `keyExtractor`, and `Pressable` rows with 48dp minimum height.

**9. Native-stack and the Duo vertical bars (RULES §7).**
- `createNativeStackNavigator` headers take part in the iPhone Duo vertical-bar layout, which is good.
- Custom views in `headerRight` stay horizontal, and react-native-screens has open Duo issues (STATUS.md).
- Vertical bars also need the iOS 27.1 SDK, so verify the build SDK and the UIScene lifecycle (`UIApplicationSceneManifest`) in `Info.plist`.
- Nothing to change in this file, but check it on the simulator.

## Not covered by this file
- `AndroidManifest.xml` (`configChanges` including `smallestScreenSize`, `screenSize`, `screenLayout`, `density`) and `Info.plist` need reviewing separately. Without them, an Activity recreate on unfold drops React state regardless of the fixes above.
- No overlays, sheets or modals appear in this file, so §8 doesn't apply here.

## Suggested shape after the fixes

```tsx
export function AccountsScreen() {
  const widthClass = useWindowWidthClass();
  const insets = useSafeAreaInsets();
  const [selected, setSelected] = useState<Account>(ACCOUNTS[0]);
  const showsBothPanes = widthClass !== 'compact';

  return (
    <View
      style={{
        flex: 1,
        flexDirection: showsBothPanes ? 'row' : 'column',
        paddingLeft: insets.left,
        paddingRight: insets.right,
        paddingTop: insets.top,
        paddingBottom: insets.bottom,
      }}
    >
      {/* list pane and detail pane stay mounted in every layout;
          hide the inactive one offscreen in compact (RULES §3) */}
    </View>
  );
}
```
