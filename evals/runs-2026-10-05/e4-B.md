# Will AppTabs behave on the iPhone Duo?

**Short answer:** probably yes for the basics, but I can't confirm it from the file alone. I'm answering from general knowledge, not from device docs, so a few points need checking on a simulator or device.

## Caveats on what I know
- I don't have reliable specs for an Apple "iPhone Duo": posture API, hinge/fold geometry, or how iOS reports the two panels. Don't treat anything below as Duo-specific fact. Get the actual window and size-class behaviour from Apple's docs or a device or simulator.
- I also can't vouch for RN 0.87.1 specifics. Check its changelog for anything on window or dimension handling.
- This is general advice for any screen that changes size or shape (foldable, Split View, resizable window).

## Bug in the file
`ProfileButton` is used in `screenOptions.headerRight` but never imported. That's a ReferenceError at render, independent of any device. Add the import.

## What I'd expect to work
- `@react-navigation/bottom-tabs` 7.x reads window and safe-area frame via hooks, so it re-lays out when the window size changes. A basic bottom tab bar with 3 tabs and a badge should resize fine.
- The default tab bar handles the bottom safe-area inset. That matters for the home indicator.

## What to check or change
1. **Don't cache dimensions.** If any screen or style uses `Dimensions.get('window')` at module scope or in `StyleSheet.create`, it goes stale on fold or unfold. Use `useWindowDimensions()`.
2. **Wide or unfolded layout.** Unfolded, the bottom bar spans a very wide window and looks stretched. In v7 you can set `tabBarPosition` (`'left'` or `'right'`, with `tabBarVariant`), and choose it from window width via `useWindowDimensions`. Consider a sidebar above a width breakpoint. Verify the exact option names against the v7 docs.
3. **Hinge or seam.** If the device has a physical gap or crease and content is drawn across it, tab labels or touch targets could land on it. Determine from Apple's docs whether the OS exposes the seam. If it does, keep tabs off it. If it doesn't, the OS probably treats it as one continuous window and there's nothing to do.
4. **Header.** `headerRight` is fine, but check that it isn't clipped or stretched in the wide layout.
5. **Orientation and window locks.** Make sure Info.plist doesn't lock the app to portrait or opt out of multitasking or resizable-window support. Either would defeat adapting.
6. **State on resize.** Resizing can remount screens if you switch navigators or layout trees based on width. Switch the layout, not the navigator, so tab state survives.

## Suggested next steps
- Fix the `ProfileButton` import.
- Run on the iOS simulator in the narrowest and widest window sizes you can get. If a Duo or foldable simulator exists in your Xcode, use that. Watch tab bar placement, badge, and header.
- Grep for `Dimensions.get`.
- Then decide whether the wide layout needs a side tab bar.
