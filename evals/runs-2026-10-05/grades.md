# Grades (blind X/Y)

## E1
X: tree swap 2 (ranked #3 High, behind two Critical items; counted as "among the most severe"); module Dimensions 1; isPad 1; insets left/right 1; width-class/re-render 1 ("bucket into size classes... re-renders on every window change"); one-tree fix 1 (leniently: "keep one navigation tree... detail as sibling", vague). Penalties 0. Total 7. Note: asserts iPhone Duo has a hinge (questionable).
Y: tree swap 2 (Blocking #1); module 1; isPad 1; insets 1; width class 1 (re-renders only on class change); one-tree fix 1 (single View, flexDirection, hidden pane kept mounted). Penalties 0. Total 7.
Preferred: Y - ranks the tree swap first and gives a concrete one-tree fix; X is vaguer there.

## E2
X: density cause 2; fixed line with density, keeps all existing 1; DisplayMetricsHolder staleness warning 1; folding handled by declared values 1. Penalties 0. Total 5.
Y: density cause 2; fixed line keeps existing plus density 1; stale metrics/text scale warning 0 (only says to use useWindowDimensions and confirm re-render at new density); folding handled 1. Penalties 0. Total 4.
Preferred: X - tighter, includes DisplayMetricsHolder caveat.

## E3
X: same tree 2; width class (600, expanded/compact) 1; hidden pane mounted + pointerEvents/a11y hidden 1; per-side insets 1; back handling 1 (BackHandler on Android, onBackToList prop; iOS relies on affordance). Penalties 0. Total 6.
Y: same tree 0 (wide renders split, narrow renders list-only, and pushes a separate route); width 1 (useWindowDimensions, 600); hidden pane 0; insets 0; back 1 (narrow push, native back works). Penalties 0. Total 2.
Preferred: X.

## E4
X: native bars vs JS 0; native tabs named 0; iOS 27.1 SDK 0; UIScene 0; headerRight/simulator 1 (suggests Duo simulator if available; does not note horizontal headerRight). Penalties 0. Total 1. Says it lacks knowledge of Duo and gives generic advice.
Y: JS tabs won't move to vertical bar 2; names createNativeBottomTabNavigator/unstable, react-native-bottom-tabs, NativeTabs 1; iOS 27.1 SDK 1; SceneDelegate/UIScene 1; headerRight stays horizontal + simulator 1. Penalties 0 (v8 correctly pre-release). Total 6.
Preferred: Y.

## E5
X: window coords + measureInWindow 2; min pane width 0; RTL 0; measure only while hinge exists 0 (measures on every layout); hinge width spacer 1. Penalties 0. Total 3.
Y: window coords + measureInWindow 2; min pane 240dp with fallback 1; RTL 0; measures only if hinge 1; hinge width marginLeft/spacer 1. Penalties 0. Total 5.
Preferred: Y.

| question | X total | Y total | max | preferred |
|---|---|---|---|---|
| E1 | 7 | 7 | 7 | Y |
| E2 | 5 | 4 | 5 | X |
| E3 | 6 | 2 | 6 | X |
| E4 | 1 | 6 | 6 | Y |
| E5 | 3 | 5 | 6 | Y |
| Total | 22 | 24 | 30 | - |
