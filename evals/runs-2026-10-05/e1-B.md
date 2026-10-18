# Review: AccountsScreen.tsx on foldables, resizable windows and iPhone Duo

Most severe first. Line numbers refer to the file as given.

## 1. Window size is read once at module load (lines 7-8) - Critical
```ts
const { width } = Dimensions.get('window');
const isWide = width >= 840 || Platform.isPad;
```
This runs once, when the JS bundle is evaluated. It never updates when:
- a foldable is opened or closed (the inner and outer displays have different widths),
- the user resizes a desktop window, Android freeform window, or an iPad Split View / Slide Over pane,
- a phone is rotated,
- an iPhone Duo-style device is spanned across both screens,
- the app is moved to an external display.

The layout stays frozen at whatever width the app started with. It will show a cramped two-pane layout in a narrow window, or a stretched single column on an unfolded device.

Fix: read the size inside the component with a hook, and drop the module-level constants.
```ts
const { width } = useWindowDimensions();
const isWide = width >= 600; // see #2
```
`useWindowDimensions` re-renders on every window change. Debounce or bucket it into size classes (compact below 600, medium 600-839, expanded 840 and up) so you only re-render when a bucket changes.

## 2. `Platform.isPad` forces the wide layout (line 8) - Critical
`Platform.isPad` is a device-type check, not a window check. An iPad in Split View or Slide Over, or a narrow Stage Manager window, can be around 320-400pt wide. This code still renders list and detail side by side in that space. The reverse also applies: a large non-iPad window, such as a phone mirrored to a desktop or an unfolded Android foldable, never gets the wide layout unless it passes the 840 check.

Fix: remove `Platform.isPad` and decide on window width alone. The 840 threshold is also high. An unfolded Pixel Fold or Galaxy Z Fold is about 600-700dp wide, so it falls into the single-column branch. Use 600dp as the two-pane breakpoint, which matches Material window size classes.

## 3. Switching layouts remounts the tree and drops state (lines 25-38) - High
The component returns either a plain `View` or a `Stack.Navigator`. Once #1 is fixed, a fold, unfold or resize swaps one for the other. React unmounts the whole subtree, which causes these problems:
- The navigation stack is lost, so the user returns to the list.
- `AccountDetail`'s `note` state (line 12) is lost. A half-typed payment reference vanishes on fold or unfold. This is a data-loss bug in a payments flow.
- The keyboard may dismiss mid-typing.
- `selected` (line 23) lives in `AccountsScreen`, so it survives. The navigator's own state does not, so the two can disagree.

Fix: keep one navigation tree for both layouts and change only how it is presented. Examples are a custom split layout where the list is always mounted and the detail is a sibling on wide windows, or a navigator whose list screen is always rendered. Also lift draft state (`note`) above the layout switch, for example into a store or the parent keyed by account id, so it survives a re-layout.

## 4. Undefined components and no data flow to the stack screens (lines 35-36) - High
`AccountListScreen` and `AccountDetailScreen` are not defined or imported in this file. The compact branch cannot compile or run as written. Neither screen receives `selected`, `setSelected` or `ACCOUNTS`, so selection state is not shared between the two layouts. After a transition (#3) the selected account can be wrong. Also, `Stack` is created at module level but the navigator is rendered inside a component that may itself be nested in another `NavigationContainer`. Check that this does not create a second container or a duplicate header.

Fix: define or import both screens, and pass the account via route params (an id, not the object) or shared state.

## 5. Safe areas and cutouts handled only on the left (line 27) - High
`paddingHorizontal: insets.left` applies the left inset to both sides, and ignores `insets.right`, top and bottom. It will be wrong when:
- the device is in landscape with the notch or camera cutout on the right,
- a foldable or desktop window has a different inset on each side,
- the window is not at the screen's origin (Split View, freeform, a mirrored window), where insets should be near zero.

Insets from `react-native-safe-area-context` are relative to the window. Make sure the app is wrapped in `SafeAreaProvider` and uses the hook values per side:
```ts
paddingLeft: insets.left, paddingRight: insets.right
```
Better, wrap with `SafeAreaView edges={['left','right']}` or let the native stack header handle the top.

## 6. iPhone Duo (spanned mode and the hinge) - Medium
The iPhone Duo and Surface Duo class of devices have two panes separated by a hinge or gap when spanned. Nothing in this file accounts for it:
- The 840 threshold is crossed when spanned, so the two-pane layout shows. The list and detail split falls wherever the content flows, not along the hinge. A `flex` split could place content under the hinge.
- Android foldables expose the hinge as a `FoldingFeature` through Jetpack WindowManager. React Native does not surface it by default. You need a native module or a community library to get the fold bounds and posture (flat, half-opened or tabletop).

Fix: if you want hinge-aware layout, get the fold bounds and make the list pane exactly one side of the hinge and the detail pane the other. If you do not need that, at least avoid placing interactive content, such as the `TextInput`, across the hinge. I am not sure how the Duo exposes its hinge to React Native, so verify this on a device or emulator before relying on it.

## 7. List pane has no layout constraints (lines 27-30) - Medium
The row container has no `flex` on either child. The `FlatList` and `AccountDetail` take their natural widths. On wide windows the list can grow to fill the row and squeeze the detail pane to nothing, or the reverse.

Fix:
```tsx
<FlatList style={{ flex: 1, maxWidth: 360 }} ... />
<View style={{ flex: 2 }}><AccountDetail .../></View>
```
Also wrap the root in a `flex: 1` view, since the current root has no height and does not fill the window.

## 8. Rows are not pressable in a robust way, and have no `keyExtractor` (line 28) - Low
- `Text onPress` has a tiny hit target, no pressed feedback and no accessibility role. Use `Pressable` with `accessibilityRole="button"` and a minimum 44-48dp target. This matters more with mouse and keyboard on desktop windows, where hover and focus states are expected.
- `FlatList` has no `keyExtractor`. Provide `keyExtractor={a => a.id}` unless `Account` has a `key` field.
- `renderItem` is an inline function, so it is recreated on every render. Hoist it or wrap it in `useCallback`.
- Highlight the selected row. Currently the user has no visual cue which account is open.

## 9. Keyboard and input handling in the detail pane (lines 14-17) - Low
`AccountDetail` has no `ScrollView` and no `KeyboardAvoidingView`. With a split-screen or small freeform window, the soft keyboard can cover the `TextInput`. It also has no `key={account.id}` at the call site (line 29), so switching accounts keeps the old `note` text and attaches it to the new account. That is a correctness bug on a payment reference field. Use `<AccountDetail key={selected.id} ... />` or reset state when the account changes.

## 10. Manifest and Info.plist (not visible here, but needed) - Check
None of the fixes above work unless the app is allowed to resize:
- Android: `android:resizeableActivity="true"`, and do not lock `android:screenOrientation`. Include `screenSize|smallestScreenSize|screenLayout|orientation` in `android:configChanges` so the activity is not recreated on fold and resize. Without that, the activity restarts and state is lost.
- iOS: set `UIRequiresFullScreen` to false, and support all orientations on iPad so Split View and Stage Manager are enabled.

## Suggested order of work
1. Replace the module constants with `useWindowDimensions` and remove `Platform.isPad` (#1, #2).
2. Stop the remount on layout switch and preserve draft state (#3, #9).
3. Fix the missing screens and shared selection (#4).
4. Fix insets and flex constraints (#5, #7).
5. Add hinge-aware layout if the Duo and foldable postures are in scope (#6).
6. Polish the list rows and accessibility (#8), and check the manifest and plist (#10).
