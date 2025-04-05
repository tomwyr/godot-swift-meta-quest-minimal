**Run Godot XR applications with Swift on Meta Quest devices.**

https://github.com/user-attachments/assets/e7a73b70-2fd4-4078-a364-546cbe9c7891

## About

This guide streamlines the process of creating a minimal functionality project that is able to run Swift code with Godot on the Meta Quest by combining the steps of setting up a few different tools and configurations that are required, which can be time consuming, especially when doing it for the first time.

The documentation includes only a basic setup of such project. For more detailed information, as well as the most up-to-date documentation of all tools used, head to the following resources:
- [Godot Engine](https://godotengine.org/)
- [SwiftGodot](https://github.com/migueldeicaza/SwiftGodot/)
- [Swift Android SDK](https://github.com/finagolfin/swift-android-sdk/)
- [Enable Developer Mode](https://developers.meta.com/horizon/documentation/native/android/mobile-device-setup/)

**Troubleshooting**

In the event of running into any issues, please consult the resources above for the most up-to-date documentation and/or create GitHub Issue describing the specific problem.

## Project setup

The following guide describes all steps necessary to integrate Swift code with Godot and deploy it to the Meta Quest.

### Setup Swift toolchain

Install the Swift open-source toolchain:
```bash
wget -P ~/Downloads https://download.swift.org/swift-6.0.3-release/xcode/swift-6.0.3-RELEASE/swift-6.0.3-RELEASE-osx.pkg
installer -target CurrentUserHomeDirectory -pkg ~/Downloads/swift-6.0.3-RELEASE-osx.pkg
```

> [!note]
> After installation, the `swift` binary should be located at `~/Library/Developer/Toolchains/swift-6.0.3-RELEASE.xctoolchain/usr/bin/swift`

Install Android SDK bundle using the OSS Swift:
```bash
SWIFT_OSS_DIR=~/Library/Developer/Toolchains/swift-6.0.3-RELEASE.xctoolchain/usr/bin
$SWIFT_OSS_DIR/swift sdk install https://github.com/finagolfin/swift-android-sdk/releases/download/6.0.3/swift-6.0.3-RELEASE-android-24-0.1.artifactbundle.tar.gz
```

### Setup Godot project

Install the Godot game engine:
```bash
wget -P ~/Downloads https://github.com/godotengine/godot-builds/releases/download/4.3-stable/Godot_v4.3-stable_macos.universal.zip
unzip ~/Downloads/Godot_v4.3-stable_macos.universal.zip
```

> [!note]  
> When selecting a different version, check compatibility between the engine and the `SwiftGodot` library.

**Configure project**

Create a new Godot project and install the necessary plugins from AssetLib:
- Godot OpenXR Vendors

Configure the project to run as an XR application:
- Activate Godot XR Tools under *Project > Project Settings... > Plugins*
- Add Android builds support via *Project > Install Android Build Template... > Install*
- Enable OpenXR and Shaders under *Project > Project Settings... > General > XR*

Add Android build configuration under *Project > Export...*:
- Create new preset *Add... > Android*
- Check *Use Gradle Build*
- Under *XR Features* set *XR Mode* to *OpenXR* and check *Enable Meta Plugin*

> [!note]
> If the build configuration window displays *Target platform requires 'ETC2/ASTC' texture compression* error, press the *Fix Import* button.

**Create scene**

Create a new scene with XR camera node and XR initialization script attached to the root node:

![Pasted image 20250404222153](https://github.com/user-attachments/assets/79558c90-b5fc-4b3c-900a-c302b574c204)

```gdscript
extends Node3D

var interface: XRInterface

func _ready() -> void:
	interface = XRServer.find_interface("OpenXR")
	if interface and interface.is_initialized():
		get_viewport().use_xr = true
```

### Setup Swift project

Create `swift` directory in the project root and add `Package.swift` configuration:
```swift
// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "GodotSwiftXr",
  platforms: [.macOS("14")],
  products: [
    .library(name: "GodotSwiftXr", type: .dynamic, targets: ["GodotSwiftXr"])
  ],
  dependencies: [
    .package(url: "https://github.com/migueldeicaza/SwiftGodot", branch: "main")
  ],
  targets: [
    .target(
      name: "GodotSwiftXr",
      dependencies: ["SwiftGodot"],
      swiftSettings: [.unsafeFlags(["-suppress-warnings"])]
    )
  ]
)
```

Create and export a simple node class that'll be exposed to Godot:

*Sources/SwiftLabel3D.swift*
```swift
import SwiftGodot

@Godot
class SwiftLabel3D: Label3D, @unchecked Sendable {
  override func _ready() {
    text = "Hello from Swift"
  }
}
```

*Sources/Entrypoint.swift*
```swift
import SwiftGodot

#initSwiftExtension(
  cdecl: "swift_entry_point",
  types: [SwiftLabel3D.self]
)
```

### Build Swift project

Build the Swift project and move the compiled binaries to correct the location to expose them to Godot:

**macOS**

Compiling for macOS produces libraries necessary to see and use Swift-based nodes in the Godot editor.

```
# Build Swift project for macOS
swift build

# Copy libraries to the bin directory
cp .build/arm64-apple-macosx/debug/{libGodotSwiftXr.dylib,libSwiftGodot.dylib} bin
```

**Android**

Compiling for Android produces libraries necessary to use Swift-based nodes by the Meta Quest in runtime.

```
# Build Swift project for Android
SWIFT_OSS_DIR=~/Library/Developer/Toolchains/swift-6.0.3-RELEASE.xctoolchain/usr/bin
$SWIFT_OSS_DIR/swift --swift-sdk aarch64-unknown-linux-android24

# Copy libraries to the bin directory
cp .build/aarch64-unknown-linux-android24/debug/{libGodotSwiftXr.so,libSwiftGodot.so} bin
```

**Swift Android dependencies**

Including the Swift core libraries cross-compiled to Android is necessary for using Swift dependency modules in runtime.

```
# Download Swift Android SDK
wget -O ~/Downloads/swift-android-sdk.tar.gz https://github.com/finagolfin/swift-android-sdk/releases/download/6.0.3/swift-6.0.3-RELEASE-android-24-0.1.artifactbundle.tar.gz

# Extract the archive
tar -xzvf ~/Downloads/swift-android-sdk.tar.gz -C ~/Downloads

# Alias the shared libraries directory path
ANDROID_LIBS_DIR=~/Downloads/swift-6.0.3-RELEASE-android-24-0.1.artifactbundle/swift-6.0.3-release-android-24-sdk/android-27c-sysroot/usr/lib/aarch64-linux-android
cp 

# Copy the libs to the Swift project
$ANDROID_LIBS_DIR/{libswiftAndroid.so,libswift_Builtin_float.so,libswift_math.so,libswiftSwiftOnoneSupport.so,libswiftCore.so,libswift_Concurrency.so,libswift_StringProcessing.so,libswift_RegexParser.so,libdispatch.so,libBlocksRuntime.so,libc++_shared.so} bin
```

### Configure Godot Swift extension

Setup the GDExtension by placing `GodotSwiftXr.gdextension` file in the root directory:
```
[configuration]
entry_symbol = "swift_entry_point"
compatibility_minimum = 4.3

[libraries]
macos.debug = "res://swift/bin/libGodotSwiftXr.dylib"
android.debug.arm64 = "res://swift/bin/libGodotSwiftXr.so"

[dependencies]
macos.debug = {"res://swift/bin/libSwiftGodot.dylib" : ""}
android.debug.arm64 = {
  "res://swift/bin/libSwiftGodot.so" : "",
  "res://swift/bin/libswiftAndroid.so" : "",
  "res://swift/bin/libswift_Builtin_float.so": "",
  "res://swift/bin/libswift_math.so": "",
  "res://swift/bin/libswiftSwiftOnoneSupport.so": "",
  "res://swift/bin/libswiftCore.so": "",
  "res://swift/bin/libswift_Concurrency.so": "",
  "res://swift/bin/libswift_StringProcessing.so": "",
  "res://swift/bin/libswift_RegexParser.so": "",
  "res://swift/bin/libdispatch.so": "",
  "res://swift/bin/libBlocksRuntime.so": "",
  "res://swift/bin/libc++_shared.so": ""
}
```

> [!warning]
> The GDExtension configuration includes only Android libraries that are essential for the project. Depending on Swift modules being used, additional libraries may be required in runtime in order for the application to work properly.
> 
> If that's the case, loading the compiled project library will fail during the application launch, preventing any Swift code execution. Checking which libraries are missing can be done by investigating the device logs and checking for logs similar to these:
> 
> 	Can't open dynamic library: swift/bin/libGodotSwiftXr.so. Error: dlopen failed: library "libswiftAndroid.so" not found: ... .
> 	Can't open GDExtension dynamic library: 'res://GodotSwiftXr.gdextension'.

### Run project on the device

Connect a Meta Quest headset with developer mode enabled and run the project using the *Remote Deploy* button:

![Pasted image 20250404212951](https://github.com/user-attachments/assets/9f3291fb-8fad-4bb5-85c8-573ece73c0e8)

Wait for Gradle to build the Android bundle and verify that the application has properly rendered the Swift node:

<img width="632" alt="Screenshot 2025-04-05 at 19 24 50" src="https://github.com/user-attachments/assets/ffd83ba7-9a27-4913-b441-1118319debc3" />

## Contributions

Contributions are welcome. If you have suggestions, improvements, or bug fixes, feel free to open an issue or submit a pull request.
