import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { InvoiceListScreen } from './InvoiceListScreen';
import { InvoiceDetailScreen } from './InvoiceDetailScreen';

const Stack = createNativeStackNavigator();

export function InvoicesNavigator() {
  return (
    <Stack.Navigator>
      <Stack.Screen name="InvoiceList" component={InvoiceListScreen} />
      <Stack.Screen name="InvoiceDetail" component={InvoiceDetailScreen} />
    </Stack.Navigator>
  );
}
