import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';

export const Tab = createBottomTabNavigator();
const A = () => <Tab.Navigator implementation="custom" />;
