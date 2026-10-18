## Why it's ~80dp off

`hinge.x` from Jetpack WindowManager's `FoldingFeature.bounds` is in **window coordinates**: 0 is the left edge of the window, not the left edge of the pane container.

In `AppShell`, the list sits inside a container that starts *after* the 80dp `NavigationRail`. So you set `listWidth = hinge.x`, but the list begins at x = 80. The list's right edge, and so the divider, lands at `80 + hinge.x`, which is 80dp right of the fold.

The rail is the only thing between the window edge and the list, and it is exactly 80dp wide. That matches the symptom.

## Fix

Subtract everything that sits to the left of the pane container from the hinge position. Don't hardcode 80. Measure the container's offset so the fix keeps working if the rail changes or the window isn't at the screen origin (split-screen, freeform).

```tsx
import { useState } from 'react';
import { View } from 'react-native';

export function AppShell({ list, detail }) {
  const { hinge } = useFoldingFeature();
  const [paneContainerLeftInWindow, setPaneContainerLeftInWindow] = useState(0);

  const hingeLeftInPaneContainer = hinge ? hinge.x - paneContainerLeftInWindow : null;
  const listWidth = hingeLeftInPaneContainer ?? 360;
  const hingeWidth = hinge?.width ?? 0;

  return (
    <View style={{ flex: 1, flexDirection: 'row' }}>
      <NavigationRail />
      <View
        style={{ flex: 1, flexDirection: 'row' }}
        onLayout={(event) => {
          event.target.measureInWindow((x) => setPaneContainerLeftInWindow(x));
        }}
      >
        <View style={{ width: listWidth }}>{list}</View>
        <View style={{ width: hingeWidth }} />
        <View style={{ flex: 1 }}>{detail}</View>
      </View>
    </View>
  );
}
```

If the rail is a fixed 80dp and the window always starts at the screen origin, `hinge.x - RAIL_WIDTH_DP` also works. It is more brittle.

## Related things to check

- **Hinge width.** On a Pixel Fold the hinge reports a width of 0 in flat mode and is non-zero only for some devices or postures. The spacer above handles devices where the hinge is a real gap or occlusion. Otherwise the detail pane starts inside the hinge.
- **Units.** `FoldingFeature.bounds` is in **pixels**. Confirm `nativeFold` divides by `PixelRatio.get()` (density) before returning, otherwise the numbers are wrong by a density factor, not by a constant 80dp.
- **Orientation.** For a horizontal hinge (tabletop), the split is on `hinge.y` and the layout should be column, not row. Only use `x` when `hinge.width < hinge.height` or when the feature's orientation is VERTICAL.
- **Re-measure on changes.** `onLayout` fires on resize and posture changes, so the offset stays correct when the window moves or resizes.
- **Only split when it matters.** Use the hinge when `isSeparating` or `occlusionType === FULL`. When the fold is flat and not separating, a fixed-width or fractional list pane avoids a weird split.
