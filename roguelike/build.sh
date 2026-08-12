#!/bin/bash
# Unified build selector for the Roguelike.
#
#   ./build.sh pc       -> desktop HashLink build  (roguelike.hl)
#   ./build.sh android  -> Android APK             (android/app/build/outputs/apk/debug/app-debug.apk)
#
# Requirements:
#   - haxe >= 4.3 (with the `hashlink` haxelib: haxelib install hashlink)
#   - Android: JDK 17, Android SDK/NDK, Gradle 8.13+ (see android/README or README.md)
set -e
cd "$(dirname "$0")"

export JAVA_HOME="${JAVA_HOME:-$HOME/opt/jdk-17.0.20+8}"
export ANDROID_HOME="${ANDROID_HOME:-$HOME/opt/android-sdk}"
export PATH="$JAVA_HOME/bin:$HOME/opt/haxe-4.3.7/haxe_20250509143529_e0b355c:$PATH"
GRADLE="${GRADLE:-$HOME/opt/gradle-8.14.3/bin/gradle}"

MODE="${1:-pc}"
case "$MODE" in
  pc)
    haxe compileGame.hxml
    echo "OK: roguelike.hl  (run with: hl roguelike.hl)"
    ;;
  android)
    haxe android.hxml
    (cd android && "$GRADLE" --no-daemon -p . :app:assembleDebug)
    echo "OK: android/app/build/outputs/apk/debug/app-debug.apk"
    ;;
  *)
    echo "Usage: ./build.sh [pc|android]"
    exit 1
    ;;
esac
