# Invoices list/detail layout

## Approach (and why the current navigator has to change)

The current `InvoicesNavigator` is a two-screen native stack. A stack can only ever show one screen, so it can't give you side by side. Swapping to a different tree on wide windows would also unmount the detail pane on every fold/unfold and lose typed text, scroll and focus. The foldables skill rules out both:

- **Decide from the window width class, not the device** (RULES §1). No `Platform.isPad`, `isTablet()`, orientation or module-scope `Dimensions.get`. This one rule covers unfolded foldables, tablets, desktop windows, and the iPhone Duo inner display (about 951pt wide, so `expanded`). The Duo outer display, phones and foldable cover screens are `compact` and get one pane.
- **Same element tree in every layout, only styles change** (RULES §3). Both panes are always mounted. In single-pane mode the hidden pane stays mounted offscreen (`position: absolute`, `opacity: 0`, `pointerEvents: 'none'`, hidden from accessibility), never `null`.
- **Never change a navigator type or screen list based on width** (RULES §3). So the list/detail switch is not done with `navigation.navigate` in one layout and a split in another. The stack becomes a single screen that owns the selection state.
- **Subscribe to the class, not raw pixels** (RULES §2). `useWindowWidthClass()` re-renders only when the class changes, not on every resize tick.

## 1. Width class hook (from RULES §2)

Copy the tested version from `skills/react-native-foldables/examples/windowWidthClass.tsx`. The snippet in RULES §2 is the same code. It exports `WindowWidthClassProvider`, `useWindowWidthClass` and `classifyWindowWidth`. Mount the provider once, at the app root, where it fills the window.

```tsx
// App root
import { WindowWidthClassProvider } from './windowWidthClass';

export function App() {
  return (
    <WindowWidthClassProvider>
      <NavigationContainer>{/* ... */}</NavigationContainer>
    </WindowWidthClassProvider>
  );
}
```

## 2. The navigator: one screen that owns the layout

```tsx
// InvoicesNavigator.tsx
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { InvoicesListDetailScreen } from './InvoicesListDetailScreen';

const Stack = createNativeStackNavigator();

export function InvoicesNavigator() {
  return (
    <Stack.Navigator>
      <Stack.Screen
        name="Invoices"
        component={InvoicesListDetailScreen}
        options={{ title: 'Invoices' }}
      />
    </Stack.Navigator>
  );
}
```

The navigator keeps a native-stack header (so system bars still take part on the iPhone Duo, RULES §7), but the list-to-detail transition is now local state, not a route.

## 3. List/detail screen

```tsx
// InvoicesListDetailScreen.tsx
import { useEffect, useState } from 'react';
import { BackHandler, Platform, StyleSheet, View, type ViewStyle } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useWindowWidthClass } from './windowWidthClass';
import { InvoiceListScreen } from './InvoiceListScreen';
import { InvoiceDetailScreen } from './InvoiceDetailScreen';

const LIST_PANE_WIDTH_WHEN_SIDE_BY_SIDE = 360;

export function InvoicesListDetailScreen() {
  const widthClass = useWindowWidthClass();
  const insets = useSafeAreaInsets();
  const showsBothPanes = widthClass !== 'compact';

  const [selectedInvoiceId, setSelectedInvoiceId] = useState<string | null>(null);
  const showsDetailOnly = !showsBothPanes && selectedInvoiceId !== null;

  useBackToListWhenDetailOnly({
    isDetailOnly: showsDetailOnly,
    backToList: () => setSelectedInvoiceId(null),
  });

  const listPaneStyle = getListPaneStyle({ showsBothPanes, showsDetailOnly });
  const detailPaneStyle = getDetailPaneStyle({ showsBothPanes, showsDetailOnly });
  const isListPaneHidden = showsDetailOnly;
  const isDetailPaneHidden = !showsBothPanes && !showsDetailOnly;

  return (
    <View
      style={[
        styles.root,
        { paddingLeft: insets.left, paddingRight: insets.right },
      ]}
    >
      <View
        style={listPaneStyle}
        pointerEvents={isListPaneHidden ? 'none' : 'auto'}
        accessibilityElementsHidden={isListPaneHidden}
        importantForAccessibility={isListPaneHidden ? 'no-hide-descendants' : 'auto'}
      >
        <InvoiceListScreen
          selectedInvoiceId={selectedInvoiceId}
          onSelectInvoice={setSelectedInvoiceId}
        />
      </View>
      <View
        style={detailPaneStyle}
        pointerEvents={isDetailPaneHidden ? 'none' : 'auto'}
        accessibilityElementsHidden={isDetailPaneHidden}
        importantForAccessibility={isDetailPaneHidden ? 'no-hide-descendants' : 'auto'}
      >
        <InvoiceDetailScreen
          invoiceId={selectedInvoiceId}
          onBackToList={showsDetailOnly ? () => setSelectedInvoiceId(null) : undefined}
        />
      </View>
    </View>
  );
}

function getListPaneStyle(layout: { showsBothPanes: boolean; showsDetailOnly: boolean }): ViewStyle {
  if (layout.showsBothPanes) {
    return { width: LIST_PANE_WIDTH_WHEN_SIDE_BY_SIDE };
  }
  return layout.showsDetailOnly ? styles.hiddenPane : styles.fullWidthPane;
}

function getDetailPaneStyle(layout: { showsBothPanes: boolean; showsDetailOnly: boolean }): ViewStyle {
  if (layout.showsBothPanes) {
    return styles.fullWidthPane;
  }
  return layout.showsDetailOnly ? styles.fullWidthPane : styles.hiddenPane;
}

function useBackToListWhenDetailOnly({
  isDetailOnly,
  backToList,
}: {
  isDetailOnly: boolean;
  backToList: () => void;
}) {
  useEffect(() => {
    if (Platform.OS !== 'android' || !isDetailOnly) return;
    const subscription = BackHandler.addEventListener('hardwareBackPress', () => {
      backToList();
      return true;
    });
    return () => subscription.remove();
  }, [isDetailOnly, backToList]);
}

const styles = StyleSheet.create({
  root: { flex: 1, flexDirection: 'row' },
  fullWidthPane: { flex: 1 },
  hiddenPane: {
    position: 'absolute',
    top: 0,
    bottom: 0,
    left: 0,
    right: 0,
    opacity: 0,
  },
});
```

Notes on the choices:

- The root tree is identical in all three states: one row `View` containing a list pane and a detail pane. Rotating, folding, or dragging a desktop window across the 600dp line only changes styles, so `InvoiceDetailScreen` keeps its input, scroll and focus. It never remounts.
- A hidden pane is `absolute` + `opacity: 0` + `pointerEvents: 'none'` + accessibility-hidden, as RULES §3 specifies, not `null`.
- `paddingLeft` and `paddingRight` use the insets separately (RULES §6). On the iPhone Duo and in Split View the system strip is on one side only, so never `paddingHorizontal: insets.left`.
- The `compact` check is the only branch. `medium`, `expanded`, `large` and `extraLarge` all show both panes. A fixed 360 list pane with a flexible detail works from 600dp upward. On the Pixel 9 Pro Fold the unfolded window is about 852dp, and on the Z Fold5 about 690dp (medium). Both get two panes, which is why the check is `!== 'compact'` and not `=== 'expanded'` (RULES §1 and STATUS: unfolded foldables straddle medium/expanded, so measure, don't assume).
- Hardware back on Android returns from detail to list in single-pane mode. The native-stack back gesture no longer applies, since there is only one route. If you need real back-stack deep links to a given invoice, keep `selectedInvoiceId` in a route param on the one screen instead of local state. Do not make a second route that exists only on compact.

## 4. Changes the two child screens need

I haven't seen `InvoiceListScreen` or `InvoiceDetailScreen`, so I'm assuming these props. Adjust them to what the screens do today:

- `InvoiceListScreen`: replace `navigation.navigate('InvoiceDetail', { id })` with `onSelectInvoice(id)`, and use `selectedInvoiceId` to highlight the selected row.
- `InvoiceDetailScreen`: take `invoiceId: string | null` as a prop instead of reading `route.params`. Render an empty state when it's `null` (shown on the right in side-by-side mode before anything is picked). When `onBackToList` is provided, render a back affordance.
- If either screen uses `useWindowDimensions`, `Dimensions.get` or a fixed root width, switch it to `useWindowWidthClass` or flex layout (RULES §1/§2). The list pane is now 360dp wide, not the full screen.
- If either screen draws a bottom sheet, dialog or toast in JS, it needs hinge awareness (RULES §8). Native `Alert` is fine.

## 5. Not covered here, and to check

- **The fold itself.** This layout is driven by width class only. On an unfolded book-posture foldable the hinge is near the middle, and on the iPhone Duo inner display there is a fold band of about 40pt (measured on the simulator, single source, so verify). With a fixed 360dp list pane, the divider between panes won't line up with the fold. Nothing interactive should sit on the band. RN core has no fold API (RULES §5). If you need panes split on the fold, you need a native module, such as one of the community packages in STATUS.md, and the "side by side / split by hinge" arrangement then needs to be exposed separately from the width class. I'd ship the width-class version first and then measure the real devices.
- **Android manifest** (RULES §4). Confirm `MainActivity` has `configChanges` including `smallestScreenSize|screenSize|screenLayout|orientation|density`, or unfolding recreates the Activity and drops the selection state. For Expo, add it with a config plugin.
- **iOS 27 SDK / iPhone Duo** (RULES §7). Builds need the iOS 27.1 SDK for the vertical bars, and the UIScene lifecycle. The native-stack header here is native, so it takes part. Orientation locks won't hold the Duo inner display in portrait.
- **Verify, don't assume** (RULES §9). Test the cycle phone, unfolded, desktop, phone, asserting the detail pane mounts once and typed text survives. Presets are Phone 411x914, Z Fold5 690x829, Pixel 9 Pro Fold 852x883, iPhone Duo outer 466x678 and inner 951x669, desktop 1280x800. In RNTL, inject the width through `WindowWidthClassProvider` or a test display you control, not by mocking `Dimensions`.
