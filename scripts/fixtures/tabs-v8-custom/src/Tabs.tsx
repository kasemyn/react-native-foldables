import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';

const Tab = createBottomTabNavigator({ implementation: 'custom', screens: {} });
const A = () => <Tab.Navigator implementation="custom" />;
const B = () => <Tab.Navigator implementation={'custom'} />;
const C = () => <Tab.Navigator implementation="native" />;
