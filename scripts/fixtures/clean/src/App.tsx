import { useWindowDimensions } from 'react-native';

export function App() {
  const { width } = useWindowDimensions();
  return width > 600 ? null : null;
}
