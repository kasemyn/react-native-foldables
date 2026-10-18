import { createContext, useContext, useState, useSyncExternalStore, type ReactNode } from 'react';
import { Dimensions, View, type LayoutChangeEvent } from 'react-native';

export type WindowWidthClass = 'compact' | 'medium' | 'expanded' | 'large' | 'extraLarge';

export function classifyWindowWidth(widthDp: number): WindowWidthClass {
  if (widthDp >= 1600) return 'extraLarge';
  if (widthDp >= 1200) return 'large';
  if (widthDp >= 840) return 'expanded';
  if (widthDp >= 600) return 'medium';
  return 'compact';
}

function createWindowWidthStore(initialWidthDp: number) {
  let widthDp = initialWidthDp;
  const listeners = new Set<() => void>();
  return {
    getWidthClass: () => classifyWindowWidth(widthDp),
    subscribe(listener: () => void) {
      listeners.add(listener);
      return () => listeners.delete(listener);
    },
    setWidth(nextWidthDp: number) {
      widthDp = nextWidthDp;
      listeners.forEach(listener => listener());
    },
  };
}

const WindowWidthStoreContext = createContext<ReturnType<typeof createWindowWidthStore> | null>(null);

export function WindowWidthClassProvider({ children }: { children: ReactNode }) {
  const [store] = useState(() => createWindowWidthStore(Dimensions.get('window').width));
  const updateWidthFromRootLayout = (event: LayoutChangeEvent) =>
    store.setWidth(event.nativeEvent.layout.width);
  return (
    <WindowWidthStoreContext.Provider value={store}>
      <View testID="window-root" style={{ flex: 1 }} onLayout={updateWidthFromRootLayout}>
        {children}
      </View>
    </WindowWidthStoreContext.Provider>
  );
}

export function useWindowWidthClass(): WindowWidthClass {
  const store = useContext(WindowWidthStoreContext);
  if (!store) throw new Error('Wrap the app root in <WindowWidthClassProvider>');
  return useSyncExternalStore(store.subscribe, store.getWidthClass);
}
