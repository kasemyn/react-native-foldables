import { Dimensions, FlatList, Platform, Text, TextInput, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { useState } from 'react';
import { ACCOUNTS, type Account } from './accounts';

const { width } = Dimensions.get('window');
const isWide = width >= 840 || Platform.isPad;
const Stack = createNativeStackNavigator();

function AccountDetail({ account }: { account: Account }) {
  const [note, setNote] = useState('');
  return (
    <View>
      <Text>{account.name}</Text>
      <TextInput value={note} onChangeText={setNote} placeholder="Payment reference" />
    </View>
  );
}

export function AccountsScreen() {
  const insets = useSafeAreaInsets();
  const [selected, setSelected] = useState<Account>(ACCOUNTS[0]);

  if (isWide) {
    return (
      <View style={{ flexDirection: 'row', paddingHorizontal: insets.left }}>
        <FlatList data={ACCOUNTS} renderItem={({ item }) => <Text onPress={() => setSelected(item)}>{item.name}</Text>} />
        <AccountDetail account={selected} />
      </View>
    );
  }
  return (
    <Stack.Navigator>
      <Stack.Screen name="List" component={AccountListScreen} />
      <Stack.Screen name="Detail" component={AccountDetailScreen} />
    </Stack.Navigator>
  );
}
