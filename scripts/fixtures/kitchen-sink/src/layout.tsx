import { Dimensions, Platform, SafeAreaView } from 'react-native';
import DeviceInfo from 'react-native-device-info';
import { createStackNavigator } from '@react-navigation/stack';
import * as ScreenOrientation from 'expo-screen-orientation';

const { width } = Dimensions.get('window');
export const SCREEN_WIDTH = width;

export function Layout({ insets, orientation }) {
  const { height } = Dimensions.get('window');
  const isLarge = Platform.isPad || DeviceInfo.isTablet();
  const isLandscape = orientation === 'landscape';
  ScreenOrientation.lockAsync(1);
  const style = { paddingHorizontal: insets.left };
  const inner = width - insets.left * 2;
  return null;
}
