#!/usr/bin/env bash
# Static checks for React Native apps on foldables, resizable windows and iPhone Duo.
# Prints "SEVERITY path:line — problem — fix" and exits 1 when anything is BLOCKING.
# Heuristic by design: every hit needs a human (or agent) to read the code. See RULES.md.

set -u
set -f

APP_ROOT="${1:-.}"
cd "$APP_ROOT" || { echo "audit.sh: cannot cd into $APP_ROOT" >&2; exit 2; }

EXCLUDED_DIRS=(node_modules Pods build dist lib .git .expo .next coverage vendor)
SOURCE_EXTENSIONS=(ts tsx js jsx)
blocking_count=0
finding_count=0

grep_exclude_args() {
  local dir
  for dir in "${EXCLUDED_DIRS[@]}"; do printf -- '--exclude-dir=%s\n' "$dir"; done
}

grep_include_source_args() {
  local extension
  for extension in "${SOURCE_EXTENSIONS[@]}"; do printf -- '--include=*.%s\n' "$extension"; done
}

report() {
  local severity="$1" location="$2" problem="$3" fix="$4"
  printf '%-12s %s — %s — %s\n' "$severity" "$location" "$problem" "$fix"
  finding_count=$((finding_count + 1))
  if [ "$severity" = "BLOCKING" ]; then blocking_count=$((blocking_count + 1)); fi
}

source_match_locations() {
  local pattern="$1" exclude_args include_args
  exclude_args=$(grep_exclude_args)
  include_args=$(grep_include_source_args)
  # shellcheck disable=SC2086
  grep -rnoE $exclude_args $include_args -e "$pattern" . 2>/dev/null | cut -d: -f1,2 | uniq | sed 's#^\./##'
}

report_source_matches() {
  local severity="$1" pattern="$2" problem="$3" fix="$4" location
  while IFS= read -r location; do
    [ -n "$location" ] && report "$severity" "$location" "$problem" "$fix"
  done < <(source_match_locations "$pattern")
}

find_files_named() {
  local file_name="$1" exclude_expression=() dir
  for dir in "${EXCLUDED_DIRS[@]}"; do exclude_expression+=(-not -path "*/$dir/*"); done
  find . -name "$file_name" "${exclude_expression[@]}" 2>/dev/null | sed 's#^\./##'
}

check_layout_sources() {
  report_source_matches "SHOULD-FIX" '^(export[[:space:]]+)?(const|let|var)[[:space:]].*Dimensions\.get\(' \
    "Dimensions.get at module scope" "stale after fold/resize; read a width class inside the component (RULES §1–2)"
  report_source_matches "SHOULD-FIX" 'Platform\.isPad|\.isTablet\(\)|userInterfaceIdiom' \
    "device/idiom check" "branch on the window's width class, not the device (RULES §1)"
  report_source_matches "SHOULD-FIX" "(orientation|Orientation)[[:space:]]*===?[[:space:]]*['\"](landscape|portrait)['\"]" \
    "orientation-based branch" "orientation isn't room; use width/height classes (RULES §1)"
  report_source_matches "SHOULD-FIX" 'lockAsync\(|lockPlatformAsync\(' \
    "orientation lock" "ignored on large screens and the iPhone Duo inner display; don't depend on it (RULES §4, §7)"
  report_source_matches "SHOULD-FIX" '(SCREEN|WINDOW|DEVICE)_(WIDTH|HEIGHT|W|H)[[:space:]]*=' \
    "screen-size constant" "the window changes at runtime; read it where you use it (RULES §1)"
}

check_safe_area_sources() {
  report_source_matches "SHOULD-FIX" '(padding|margin)Horizontal:[[:space:]]*insets\.(left|right)' \
    "one inset mirrored to both sides" "use paddingLeft: insets.left, paddingRight: insets.right (RULES §6)"
  report_source_matches "SHOULD-FIX" 'insets\.(left|right)[[:space:]]*\*[[:space:]]*2|2[[:space:]]*\*[[:space:]]*insets\.(left|right)' \
    "inset doubled" "insets are asymmetric; subtract left and right separately (RULES §6)"
  report_source_matches "NICE-TO-HAVE" "SafeAreaView[[:space:]]*\}?[[:space:]]*from[[:space:]]*['\"]react-native['\"]|import[[:space:]]*\{[^}]*SafeAreaView[^}]*\}[[:space:]]*from[[:space:]]*['\"]react-native['\"]" \
    "RN core SafeAreaView" "deprecated and iOS-only; use react-native-safe-area-context (RULES §6)"
}

package_json_declaring_bottom_tabs_for_file() {
  local directory
  directory=$(dirname "$1")
  while true; do
    if grep -qs '"@react-navigation/bottom-tabs"' "$directory/package.json"; then
      echo "$directory/package.json"
      return
    fi
    [ "$directory" = "." ] && return
    directory=$(dirname "$directory")
  done
}

bottom_tabs_version_class_for_file() {
  local package_json major
  package_json=$(package_json_declaring_bottom_tabs_for_file "$1")
  [ -n "$package_json" ] || { echo unknown; return; }
  read -r major _ <<< "$(dependency_version_in "$package_json" @react-navigation/bottom-tabs)"
  if [ -z "${major:-}" ]; then echo unknown
  elif [ "$major" -ge 8 ]; then echo v8-or-later
  else echo v7-or-earlier
  fi
}

file_of_location() {
  printf '%s' "${1%%:*}"
}

check_bottom_tab_navigator_factory() {
  local location version_class
  while IFS= read -r location; do
    [ -n "$location" ] || continue
    version_class=$(bottom_tabs_version_class_for_file "$(file_of_location "$location")")
    case "$version_class" in
      v7-or-earlier)
        report "SHOULD-FIX" "$location" "JS-drawn bottom tabs (React Navigation v7)" \
          "won't move to the iPhone Duo vertical bar; consider native tabs on iOS (RULES §7, STATUS)" ;;
      unknown)
        report "SHOULD-FIX" "$location" "JS-drawn bottom tabs if on React Navigation v7 or earlier (version not resolved)" \
          "won't move to the iPhone Duo vertical bar; v8 draws native tabs by default, v7 needs native tabs on iOS (RULES §7, STATUS)" ;;
    esac
  done < <(source_match_locations 'createBottomTabNavigator[[:space:]]*[<(]')
}

check_bottom_tab_custom_implementation() {
  local location
  while IFS= read -r location; do
    [ -n "$location" ] || continue
    [ "$(bottom_tabs_version_class_for_file "$(file_of_location "$location")")" = "v8-or-later" ] || continue
    report "SHOULD-FIX" "$location" "bottom tabs with implementation 'custom' (React Navigation v8)" \
      "JS tabs won't move to the iPhone Duo vertical bar; drop the option to use native tabs (RULES §7, STATUS)"
  done < <(source_match_locations "implementation[[:space:]]*[:=][[:space:]]*\{?[[:space:]]*['\"]custom['\"]")
}

check_navigation_sources() {
  check_bottom_tab_navigator_factory
  check_bottom_tab_custom_implementation
  report_source_matches "NICE-TO-HAVE" "from[[:space:]]*['\"]@react-navigation/stack['\"]" \
    "JS stack headers" "won't take part in iPhone Duo vertical bars; native-stack does (RULES §7)"
}

check_performance_sources() {
  local exclude_args include_args usage_count
  exclude_args=$(grep_exclude_args)
  include_args=$(grep_include_source_args)
  # shellcheck disable=SC2086
  usage_count=$(grep -rlE $exclude_args $include_args -e 'useWindowDimensions\(' . 2>/dev/null | wc -l | tr -d ' ')
  if [ "${usage_count:-0}" -gt 3 ]; then
    report "NICE-TO-HAVE" "(${usage_count} files)" "useWindowDimensions in many files" \
      "re-renders on every size change during window drags; subscribe to a width class (RULES §2)"
  fi
}

activity_config_changes() {
  local manifest="$1"
  tr '\n' ' ' < "$manifest" | grep -oE '<activity[^>]*MainActivity[^>]*>' | grep -oE 'android:configChanges="[^"]*"' | head -1
}

check_android_manifest() {
  local manifest config_changes required_value
  while IFS= read -r manifest; do
    [ -z "$manifest" ] && continue
    case "$manifest" in *src/main/AndroidManifest.xml) ;; *) continue ;; esac
    config_changes=$(activity_config_changes "$manifest")
    if [ -z "$config_changes" ]; then
      report "BLOCKING" "$manifest" "MainActivity has no configChanges" \
        "every fold/resize recreates the Activity; add the list in RULES §4"
      continue
    fi
    for required_value in screenSize smallestScreenSize screenLayout orientation; do
      if ! printf '%s' "$config_changes" | grep -qE "[\"|]${required_value}[\"|]"; then
        report "BLOCKING" "$manifest" "configChanges lacks ${required_value}" \
          "fold/unfold or resize recreates the Activity and drops React state (RULES §4)"
      fi
    done
    if ! printf '%s' "$config_changes" | grep -qE '["|]density["|]'; then
      report "SHOULD-FIX" "$manifest" "configChanges lacks density" \
        "moving to a display with another density recreates the Activity; add it and re-init DisplayMetricsHolder (RULES §4)"
    fi
    if grep -nE 'android:screenOrientation=' "$manifest" >/dev/null; then
      report "NICE-TO-HAVE" "$manifest:$(grep -nE 'android:screenOrientation=' "$manifest" | head -1 | cut -d: -f1)" \
        "screenOrientation set" "ignored at smallest width ≥ 600dp from targetSdk 36; don't depend on it (RULES §4)"
    fi
  done < <(find_files_named AndroidManifest.xml)
}

check_info_plists() {
  local plist
  while IFS= read -r plist; do
    [ -z "$plist" ] && continue
    case "$plist" in */Pods/*|*Tests*|*.xcassets/*) continue ;; esac
    grep -q 'CFBundleIdentifier' "$plist" || continue
    if ! grep -q 'UIApplicationSceneManifest' "$plist"; then
      report "BLOCKING" "$plist" "no UIApplicationSceneManifest" \
        "iOS 27-SDK builds without the UIScene lifecycle crash at launch (RULES §7, STATUS)"
    fi
    if grep -q '<key>UIRequiresFullScreen</key>' "$plist"; then
      report "NICE-TO-HAVE" "$plist" "UIRequiresFullScreen set" \
        "doesn't stop resizing on iOS 27 / iPhone Duo (RULES §7)"
    fi
  done < <(find_files_named Info.plist)
}

dependency_version_in() {
  local package_json="$1" package_name="$2"
  grep -E "\"${package_name}\"[[:space:]]*:" "$package_json" 2>/dev/null | head -1 \
    | sed -nE 's/.*"[^"]+"[[:space:]]*:[[:space:]]*"[\^~>=< v]*([0-9]+)(\.([0-9]+))?.*/\1 \3/p'
}

app_package_json_files() {
  local package_json directory
  while IFS= read -r package_json; do
    [ -n "$package_json" ] || continue
    directory=$(dirname "$package_json")
    if [ "$directory" = "." ] || [ -d "$directory/ios" ] || [ -d "$directory/android" ]; then
      echo "$package_json"
    fi
  done < <(find_files_named package.json)
}

check_package_json_versions() {
  local package_json="$1" major minor
  read -r major minor <<< "$(dependency_version_in "$package_json" react-native)"
  if [ -n "${major:-}" ] && [ "$major" -eq 0 ] && [ -n "${minor:-}" ] && [ "$minor" -lt 88 ] && [ -d "$(dirname "$package_json")/ios" ]; then
    report "SHOULD-FIX" "$package_json" "react-native 0.${minor}" \
      "templates before 0.88 lack a SceneDelegate; required for the iOS 27 SDK (STATUS)"
  fi
  read -r major minor <<< "$(dependency_version_in "$package_json" expo)"
  if [ -n "${major:-}" ] && [ "$major" -le 54 ]; then
    report "SHOULD-FIX" "$package_json" "expo SDK ${major}" \
      "its Android template lacks smallestScreenSize, so unfolding recreates the Activity; check the generated manifest (RULES §4)"
  fi
}

check_dependency_versions() {
  local package_json
  while IFS= read -r package_json; do
    [ -n "$package_json" ] && check_package_json_versions "$package_json"
  done < <(app_package_json_files)
}

check_expo_app_config() {
  local config_file
  for config_file in app.json app.config.js app.config.ts; do
    [ -f "$config_file" ] || continue
    if grep -nE '"?orientation"?[[:space:]]*:[[:space:]]*["'"'"'](portrait|landscape)' "$config_file" >/dev/null; then
      report "NICE-TO-HAVE" "$config_file:$(grep -nE '"?orientation"?[[:space:]]*:' "$config_file" | head -1 | cut -d: -f1)" \
        "orientation lock in Expo config" "won't hold on large screens or the iPhone Duo inner display (RULES §4, §7)"
    fi
  done
}

check_layout_sources
check_safe_area_sources
check_navigation_sources
check_performance_sources
check_android_manifest
check_info_plists
check_dependency_versions
check_expo_app_config

echo
echo "${finding_count} finding(s), ${blocking_count} blocking. Static checks only: review RULES.md for what grep can't see (element-tree swaps, hinge coordinates, JS overlays on the fold)."
[ "$blocking_count" -eq 0 ]
