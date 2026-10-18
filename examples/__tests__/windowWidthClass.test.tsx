import { Text } from 'react-native';
import { fireEvent, render, screen } from '@testing-library/react-native';
import {
  classifyWindowWidth,
  useWindowWidthClass,
  WindowWidthClassProvider,
} from '../windowWidthClass';

function layoutEventWithWidth(widthDp: number) {
  return { nativeEvent: { layout: { x: 0, y: 0, width: widthDp, height: 800 } } };
}

async function renderWithCounter(initialWidthDp: number) {
  jest.spyOn(require('react-native').Dimensions, 'get').mockReturnValue({
    width: initialWidthDp,
    height: 800,
    scale: 1,
    fontScale: 1,
  });
  const renderCounter = { count: 0 };
  function WidthClassConsumer() {
    renderCounter.count += 1;
    return <Text testID="width-class">{useWindowWidthClass()}</Text>;
  }
  await render(
    <WindowWidthClassProvider>
      <WidthClassConsumer />
    </WindowWidthClassProvider>,
  );
  return renderCounter;
}

async function resizeRootViewTo(widthDp: number) {
  await fireEvent(screen.getByTestId('window-root'), 'layout', layoutEventWithWidth(widthDp));
}

afterEach(() => jest.restoreAllMocks());

describe('classifyWindowWidth', () => {
  it.each([
    [0, 'compact'],
    [599, 'compact'],
    [600, 'medium'],
    [839, 'medium'],
    [840, 'expanded'],
    [1199, 'expanded'],
    [1200, 'large'],
    [1599, 'large'],
    [1600, 'extraLarge'],
  ])('classifies %p dp as %s', (widthDp, expectedClass) => {
    expect(classifyWindowWidth(widthDp)).toBe(expectedClass);
  });
});

describe('useWindowWidthClass', () => {
  it('starts from the Dimensions width', async () => {
    await renderWithCounter(411);
    expect(screen.getByTestId('width-class')).toHaveTextContent('compact');
  });

  it('does not re-render while the root layout changes within one class', async () => {
    const renderCounter = await renderWithCounter(900);
    const rendersAfterMount = renderCounter.count;
    for (let widthDp = 900; widthDp <= 990; widthDp += 1) {
      await resizeRootViewTo(widthDp);
    }
    expect(renderCounter.count).toBe(rendersAfterMount);
  });

  it('re-renders when the root layout crosses a breakpoint', async () => {
    const renderCounter = await renderWithCounter(839);
    const rendersAfterMount = renderCounter.count;
    await resizeRootViewTo(840);
    expect(screen.getByTestId('width-class')).toHaveTextContent('expanded');
    expect(renderCounter.count).toBe(rendersAfterMount + 1);
  });

  it('re-renders once per class crossed during a 600 to 1200 drag', async () => {
    const renderCounter = await renderWithCounter(600);
    const rendersAfterMount = renderCounter.count;
    for (let widthDp = 600; widthDp <= 1200; widthDp += 10) {
      await resizeRootViewTo(widthDp);
    }
    expect(screen.getByTestId('width-class')).toHaveTextContent('large');
    expect(renderCounter.count - rendersAfterMount).toBe(2);
  });
});
