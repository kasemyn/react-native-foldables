# Why the divider is ~80dp right of the fold

**Cause: coordinate-space mismatch.** Hinge bounds from `FoldingFeature` (via our `useFoldingFeature` native module) are in **window coordinates** (RULES §5). But `listWidth = hinge.x` is used as a width *inside a container* that does not start at the window origin: it sits to the right of `NavigationRail`, which is 80dp wide. The list pane therefore starts at x = 80 and ends at 80 + hinge.x, so the divider lands 80dp past the fold. That matches what you see.

(Assuming the module reports dp. If it reports raw pixels you'd see a much bigger error, so check that too.)

## Fix

Convert the hinge into the container's coordinates with `measureInWindow` on the pane container, and only measure while a hinge exists (so non-foldables pay nothing). Treat the fold as a band: it has width, so keep content out of it.

```tsx
import { useCallback, useRef, useState } from 'react';
import { View } from 'react-native';
import { useFoldingFeature } from './nativeFold';
import { NavigationRail } from './NavigationRail';

const DEFAULT_LIST_WIDTH_DP = 360;
const MIN_PANE_WIDTH_DP = 240;

export function AppShell({ list, detail }) {
  const { hinge } = useFoldingFeature();
  const paneContainerRef = useRef<View>(null);
  const [containerWindowOffsetX, setContainerWindowOffsetX] = useState<number | null>(null);
  const [containerWidth, setContainerWidth] = useState(0);

  const measurePaneContainer = useCallback(() => {
    if (!hinge) return;
    paneContainerRef.current?.measureInWindow((x, _y, width) => {
      setContainerWindowOffsetX(x);
      setContainerWidth(width);
    });
  }, [hinge]);

  const listWidth = computeListWidth(hinge, containerWindowOffsetX, containerWidth);

  return (
    <View style={{ flex: 1, flexDirection: 'row' }}>
      <NavigationRail />
      <View
        ref={paneContainerRef}
        onLayout={measurePaneContainer}
        style={{ flex: 1, flexDirection: 'row' }}
      >
        <View style={{ width: listWidth }}>{list}</View>
        <View style={{ flex: 1 }}>{detail}</View>
      </View>
    </View>
  );
}

function computeListWidth(hinge, containerWindowOffsetX, containerWidth) {
  if (!hinge || containerWindowOffsetX === null) return DEFAULT_LIST_WIDTH_DP;
  const listWidth = hinge.x - containerWindowOffsetX;
  const detailWidth = containerWidth - listWidth - hinge.width;
  const bothPanesUsable = listWidth >= MIN_PANE_WIDTH_DP && detailWidth >= MIN_PANE_WIDTH_DP;
  return bothPanesUsable ? listWidth : DEFAULT_LIST_WIDTH_DP;
}
```

Notes:
- The detail pane should also start after the hinge band. Add `marginLeft: hinge.width` to the detail view (or a spacer of `hinge.width`) when split, so it doesn't sit under the fold.
- Only split on the fold for a vertical fold in book posture (use `classifyFoldPosture`: `halfOpened` or `isSeparating`, `orientation === 'vertical'`), and only when both panes keep about 240dp. Otherwise fall back to the width-class layout.
- Fold events and window resizes arrive as separate streams in either order. Hold the hinge report until the measured window size matches the size it was computed for (with a short timeout fallback), otherwise you'll get one frame with the hinge outside the window.
- Edge-to-edge offsets on Android make this easy to get wrong, so test on the Pixel Fold emulator (unfolded ~701 x 841dp, medium/expanded) in both postures and with the rail visible.
- Don't hardcode 80 for the rail: measuring the container is what keeps this correct if the rail width changes.
