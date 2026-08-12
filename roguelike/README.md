# Roguelike (Haxe + Heaps)

A small roguelike built with [Haxe](https://haxe.org) and [Heaps.io](https://heaps.io),
running on **desktop (PC)** and **Android**. Movement is grid-based; reach the
`E` marker to reveal the artifact.

This is a cross-platform project: **one codebase**, two targets, with
platform-specific code cleanly isolated from the core game logic.

---

## Build system & target selection

A single unified selector builds either target:

```
./build.sh pc        # desktop build -> roguelike.hl
./build.sh android   # Android APK   -> android/app/build/outputs/apk/debug/app-debug.apk
```

It wraps two Haxe configs:

| File               | Target   | Output                    |
|--------------------|----------|---------------------------|
| `compileGame.hxml` | PC       | `roguelike.hl` (HashLink bytecode) |
| `android.hxml`     | Android  | `android/native/game.c` (AOT C, packaged by Gradle) |

> PC: run the game with `hl roguelike.hl`.
> Android: install with `adb install -r android/app/build/outputs/apk/debug/app-debug.apk`,
> launch with `adb shell am start -n org.haxe.roguelike/.MainActivity`.

### Prerequisites

- Haxe >= 4.3 with the `hashlink` haxelib: `haxelib install hashlink`
- Desktop: HashLink runtime + SDL3
- Android: JDK 17, Android SDK/NDK (`platforms;android-35/36`, NDK 28.x, cmake 3.22.1),
  Gradle 8.13+; and the HashLink source tree (see `android/gradle.properties` -> `hashlinkSrc`)

### VS Code

- **Tasks**: `Build` / `Build (debug)` (PC), `Build Android`, `Build and Run Android`,
  `Android Logcat`
- **Debug**: F5 -> "debug mode" (PC, HashLink debugger); "Android Native (LLDB)"
  profile for on-device native debugging

---

## Platform code separation

```
roguelike/
├── src/
│   ├── Main.hx                  # entry: hxd.App; wires the platform input (ONLY platform branch here)
│   ├── core/
│   │   └── Roguelike.hx         # cross-platform game logic (map, player, walls, exit, camera)
│   └── input/
│       ├── InputController.hx   # interface: directionX/Y(), update(), helpText()
│       ├── KeyboardInput.hx     # desktop: arrows / WASD
│       └── TouchInput.hx        # Android: virtual on-screen D-pad (h2d.Interactive)
├── android.hxml                 # Android AOT build config
├── compileGame.hxml             # PC build config
├── android/                     # Android-only project (Gradle + CMake + Java)
│   └── app/src/main/
│       ├── jni/CMakeLists.txt   # builds HashLink runtime + SDL3 + game C
│       └── java/org/haxe/roguelike/MainActivity.java  # activity, immersive fullscreen, landscape
├── res/                         # embedded resources (haxeLogo.png)
└── build.sh                     # target selector
```

**Rules of the architecture:**

- **`src/core/`** has **zero** platform-specific code: no `hxd.Key`, no Android
  APIs. Movement is driven entirely by the injected `InputController`
  (`directionX()/directionY()`).
- **`src/input/`** holds one controller per platform, implementing the same
  interface. Desktop reads the keyboard; Android renders a virtual D-pad and
  exposes button state as a direction.
- **`src/Main.hx`** is the **only** place that branches on the platform
  (`Sys.systemName() == "Android"`) to select the controller — so the whole
  game runs as one binary on both targets.
- **`android/`** contains everything Android-specific (Gradle, NDK/CMake,
  Java activity), so Android development happens in its own module without
  touching the cross-platform code.

### How to add a new platform

1. Implement `input.InputController` for the platform (e.g. `GamepadInput`).
2. Select it in `Main.init()`.
3. Add a build config (hxml) and, if needed, a platform build folder.

---

## Android build details

The Android APK is produced by the **HashLink AOT pipeline**:

```
haxe android.hxml         -> android/native/game.c  (game compiled to C, resources embedded)
NDK CMake + Gradle        -> APK (libhl + fmt/sdl/ui/uv hdlls + SDL3 + game)
```

- Targets **Android 15 (API 35)** and **Android 16 (API 36)**: `compileSdk 36`,
  `targetSdk 36`, `minSdk 24`.
- ABIs: `arm64-v8a`, `armeabi-v7a`, `x86_64`.
- The app boots **immersive fullscreen, landscape**, at the device's native
  resolution (`MainActivity`).
- Resources (`res/`) are **embedded** into the binary via `hxd.Res.initEmbed()`,
  so no runtime filesystem/asset step is needed.
- The first native build downloads and compiles third-party deps (SDL3,
  libpng, libjpeg-turbo, libvorbis, libuv) for each ABI - it takes a while;
  later builds are fast.

### Android input: touch D-pad

On Android, `TouchInput` draws a virtual D-pad (4 buttons) at the bottom-right
corner. **Hold** a button to keep moving in that direction, like holding a key.
The D-pad scales with the screen (`min(width/1024, height/768)`) so it stays
usable on any resolution, and the buttons are sized as large touch targets.

On desktop you can preview the on-screen D-pad (e.g. for layout tweaks) with
`FORCE_TOUCH=1 hl roguelike.hl`.

### Install & test

```
adb install -r android/app/build/outputs/apk/debug/app-debug.apk
adb shell am start -n org.haxe.roguelike/.MainActivity
adb logcat -s SDL            # game trace() output (routed via SDL)
```

### Debugging

- **Haxe logic**: debug on PC (F5 -> "debug mode", HashLink debugger).
- **On-device**: `trace()` output appears in logcat; native C debugging via the
  "Android Native (LLDB)" profile (requires `lldb-mi` from an older NDK or the
  Android Native Debug extension).
- The HashLink remote debugger (`hl --debug`) is **not** available on Android
  (the game is AOT-compiled; HashLink has no JIT for ARM).

---
