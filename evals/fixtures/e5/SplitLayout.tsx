import { View } from 'react-native';
import { useFoldingFeature } from './nativeFold'; // our own native module: returns { hinge: { x, y, width, height } | null }
import { NavigationRail } from './NavigationRail'; // 80dp wide, always on the left

export function AppShell({ list, detail }) {
  const { hinge } = useFoldingFeature();
  const listWidth = hinge ? hinge.x : 360;

  return (
    <View style={{ flex: 1, flexDirection: 'row' }}>
      <NavigationRail />
      <View style={{ flex: 1, flexDirection: 'row' }}>
        <View style={{ width: listWidth }}>{list}</View>
        <View style={{ flex: 1 }}>{detail}</View>
      </View>
    </View>
  );
}
