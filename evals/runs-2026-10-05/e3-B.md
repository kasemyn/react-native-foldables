# Invoices list/detail: two panes when wide, one pane on phones

## Approach

- Decide by **window width**, not device type. Use `useWindowDimensions()` with a 600dp breakpoint (Material "medium" width class). Don't use `Platform`, `isTablet` or device model checks. Unfolded foldables, tablets, iPad Split View and the iPhone Duo inner display are all just "window is at least 600dp wide". The same device can cross the breakpoint at runtime when you fold, unfold, rotate or resize the window.
- Keep the **selected invoice id in navigation state** (route params), not in component state. It then survives a fold or unfold, and deep links work the same on both layouts.
- Keep the existing stack. Wide: the list route renders both panes and tapping a row updates a param. Narrow: tapping a row pushes `InvoiceDetail`, as it does today.
- Handle the "unfolded while on the detail screen" case, so you never show a detail screen full-width next to nothing.

## Files

### `useIsWideWindow.ts`

```ts
import { useWindowDimensions } from 'react-native';

const WIDE_WINDOW_MIN_WIDTH_DP = 600;

export function useIsWideWindow() {
  const { width } = useWindowDimensions();
  return width >= WIDE_WINDOW_MIN_WIDTH_DP;
}
```

### `InvoicesNavigator.tsx`

```tsx
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { InvoiceListScreen } from './InvoiceListScreen';
import { InvoiceDetailScreen } from './InvoiceDetailScreen';

export type InvoicesStackParamList = {
  InvoiceList: { selectedInvoiceId?: string } | undefined;
  InvoiceDetail: { invoiceId: string };
};

const Stack = createNativeStackNavigator<InvoicesStackParamList>();

export function InvoicesNavigator() {
  return (
    <Stack.Navigator>
      <Stack.Screen name="InvoiceList" component={InvoiceListScreen} />
      <Stack.Screen name="InvoiceDetail" component={InvoiceDetailScreen} />
    </Stack.Navigator>
  );
}
```

### `InvoiceListScreen.tsx` (wrapper that picks the layout)

Assumes your current list UI and detail UI are (or can be extracted as) presentational components: `InvoiceList` takes `onSelectInvoice(id)` and optional `selectedInvoiceId`. `InvoiceDetail` takes `invoiceId`. Adapt the names to what you actually have.

```tsx
import { StyleSheet, Text, View } from 'react-native';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { InvoiceList } from './InvoiceList';
import { InvoiceDetail } from './InvoiceDetail';
import { useIsWideWindow } from './useIsWideWindow';
import type { InvoicesStackParamList } from './InvoicesNavigator';

type Props = NativeStackScreenProps<InvoicesStackParamList, 'InvoiceList'>;

export function InvoiceListScreen({ navigation, route }: Props) {
  const isWideWindow = useIsWideWindow();
  const selectedInvoiceId = route.params?.selectedInvoiceId;

  function selectInvoiceOnWideWindow(invoiceId: string) {
    navigation.setParams({ selectedInvoiceId: invoiceId });
  }

  function openInvoiceDetailOnNarrowWindow(invoiceId: string) {
    navigation.navigate('InvoiceDetail', { invoiceId });
  }

  if (!isWideWindow) {
    return <InvoiceList onSelectInvoice={openInvoiceDetailOnNarrowWindow} />;
  }

  return (
    <View style={styles.splitContainer}>
      <View style={styles.listPane}>
        <InvoiceList
          selectedInvoiceId={selectedInvoiceId}
          onSelectInvoice={selectInvoiceOnWideWindow}
        />
      </View>
      <View style={styles.detailPane}>
        {selectedInvoiceId ? (
          <InvoiceDetail invoiceId={selectedInvoiceId} />
        ) : (
          <View style={styles.emptyDetailPane}>
            <Text>Select an invoice</Text>
          </View>
        )}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  splitContainer: { flex: 1, flexDirection: 'row' },
  listPane: {
    flexBasis: 320,
    flexGrow: 0,
    flexShrink: 0,
    maxWidth: '40%',
    borderEndWidth: StyleSheet.hairlineWidth,
  },
  detailPane: { flex: 1 },
  emptyDetailPane: { flex: 1, alignItems: 'center', justifyContent: 'center' },
});
```

### `InvoiceDetailScreen.tsx` (the narrow-window route)

If the window becomes wide while this route is on top (the user unfolds mid-flow), pop back to the list with the id as the selection. The list then shows both panes.

```tsx
import { useEffect } from 'react';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { InvoiceDetail } from './InvoiceDetail';
import { useIsWideWindow } from './useIsWideWindow';
import type { InvoicesStackParamList } from './InvoicesNavigator';

type Props = NativeStackScreenProps<InvoicesStackParamList, 'InvoiceDetail'>;

export function InvoiceDetailScreen({ navigation, route }: Props) {
  const isWideWindow = useIsWideWindow();
  const { invoiceId } = route.params;

  useEffect(() => {
    if (!isWideWindow) return;
    navigation.popTo('InvoiceList', { selectedInvoiceId: invoiceId });
  }, [isWideWindow, invoiceId, navigation]);

  return <InvoiceDetail invoiceId={invoiceId} />;
}
```

`popTo` is React Navigation 7. On v6 use `navigation.navigate({ name: 'InvoiceList', params: { selectedInvoiceId: invoiceId }, merge: true })`, which also pops back to the existing list route.

Going the other way (wide to narrow with an invoice selected) shows the list and keeps the selection in params. That is acceptable. If you want to land on the detail instead, add a matching effect in the list screen that navigates to `InvoiceDetail` when `!isWideWindow && selectedInvoiceId`, and clear the param when you do.

## Platform config needed for this to work

- **Android**: the activity must be resizable and must not restart on fold or size changes.
  - Don't set `android:resizeableActivity="false"` (API 24+ defaults to true), and don't lock `screenOrientation`. Apps that do get letterboxed on foldables and tablets, so your breakpoint never triggers.
  - `MainActivity` in `AndroidManifest.xml` should include `screenSize|smallestScreenSize|screenLayout|orientation|keyboardHidden|density` in `android:configChanges`. The RN template already does this. Check you haven't removed any of them, or the activity restarts on fold and you lose JS state.
- **iOS** (iPad, and the iPhone Duo inner display or iPhone Mirroring windows): the app needs to support all orientations and multitasking.
  - In `Info.plist`, don't set `UIRequiresFullScreen`, and keep every orientation in `UISupportedInterfaceOrientations~ipad`.
  - `useWindowDimensions` reports the real window size, so Split View and Slide Over resizing flow through the same hook.

## Things deliberately not done

- No hinge or fold-posture APIs. A plain 320dp-list plus flex-detail split doesn't need them, and it works on tablets and desktop windows too. If design later wants the divider to line up with a physical hinge, or a tabletop or book posture, that needs a Jetpack WindowManager native module, and I'd treat that as a separate piece of work.
- No `Dimensions.get('window')` at module scope. It goes stale on fold, rotate and resize. Always use the hook.
- The `600` breakpoint lives in one hook. If other flows need the same decision, reuse `useIsWideWindow` instead of copying the number.

## How to test

- Android emulator: "Resizable (Experimental)" or "Pixel Fold". Toggle fold and unfold, and rotate.
- With an invoice open on the phone layout, unfold. You should land on the list with both panes and that invoice selected.
- iPad simulator: drag the Split View divider across the 600dp point.
- Rotate a large phone. Anything under 600dp wide in landscape stays single-pane; that is intended.
