// package.json: "@react-navigation/bottom-tabs": "^7.19.2", "react-native": "0.87.1"
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { HomeScreen, PaymentsScreen, SettingsScreen } from './screens';

const Tab = createBottomTabNavigator();

export function AppTabs() {
  return (
    <Tab.Navigator screenOptions={{ headerRight: () => <ProfileButton /> }}>
      <Tab.Screen name="Home" component={HomeScreen} />
      <Tab.Screen name="Payments" component={PaymentsScreen} options={{ tabBarBadge: 2 }} />
      <Tab.Screen name="Settings" component={SettingsScreen} />
    </Tab.Navigator>
  );
}
