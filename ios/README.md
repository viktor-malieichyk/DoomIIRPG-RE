# Doom II RPG on iPhone/iPad

The app runs in landscape on iOS 15 or later. It retains the original touchscreen
interface and SDL gamepad support, with additional on-screen action buttons.
Files > Hide touch buttons clears the overlay; Menu and Files remain available.
The original repository icon is used for the app. Data and saves remain local
unless you explicitly export them through Files.

## Import your game data from iCloud Drive

1. Put your original `Doom 2 RPG.ipa` in iCloud Drive.
2. Launch the port and choose **Import game data from Files / iCloud**.
3. Browse to iCloud Drive and select the original IPA. Wait for the confirmation,
   then choose **Play**. The app validates the archive and copies it locally so
   gameplay works offline. An IPA for the other game is rejected.

The import uses game resources from the original IPA; it does not install or run
its old executable. Game data is not shipped with the port.

## Save backup and restore

- Save through the game menu first. Select **Files > Export save to Files / iCloud**
  and choose iCloud Drive as the destination. This produces one `.rpgsave` backup.
- To restore, close and reopen the app. Before choosing Play, select **Import save
  backup**, pick the `.rpgsave`, and confirm replacing local saves. Then choose
  Play and Continue in the game.
- Each backup is tagged for this game. Restore rejects wrong-game backups, keeps
  the previous save directory in `Previous Saves …`, and removes stale world
  saves from the restored set. Backup/restore does not include the game IPA.
- Raw Windows saves can be copied into the app’s `Game/Doom2rpg.app` directory via
  Files before launching. Keep all files from the same save together.

This is manual import/export through the system Files picker, including iCloud
Drive. It does not require a paid iCloud app entitlement and does not perform
automatic cross-device synchronization.

## Build and install with a free Apple ID

Requirements: full Xcode with the iOS platform, CMake, Git, and macOS.

```sh
sh build-ios.sh device
```

The script downloads SDL2 at a pinned revision and writes
`dist/DoomIIRPG-ios-unsigned.ipa`. The package is unsigned and cannot be installed
until signed. To sign and run directly:

1. Open `build/ios-device-xcode/DoomIIRPG.xcodeproj` in Xcode.
2. Add your Apple ID in Xcode Settings > Accounts.
3. Select the DoomIIRPG target, enable automatic signing, and select your
   Personal Team. Use a unique bundle identifier if requested.
4. Connect your iPhone, enable Developer Mode if prompted, select the device,
   and run the DoomIIRPG scheme.

Once Xcode signing is set up, `DEVELOPMENT_TEAM=YOUR_TEAM_ID` and
`BUNDLE_ID=your.unique.id` can be supplied to the script for a development-signed
IPA. Free Personal Team profiles require renewal periodically; keep save backups
before deleting/reinstalling the app.
[Apple Personal Team limits](https://developer.apple.com/help/account/basics/about-your-developer-account).

For an Apple Silicon simulator:

```sh
sh build-ios.sh simulator
xcrun simctl install booted build/ios-simulator-xcode/Release-iphonesimulator/DoomIIRPG.app
xcrun simctl launch booted org.doomrpg.doom2
```

## Port details and verification

Rendering uses OpenGL ES 1.1 with an aspect-fit viewport and matching touch
coordinates. Device builds render at Retina resolution. Simulator builds disable
high DPI because the simulator’s ES1 implementation renders in software. Frames
run through the native iOS display link so UIKit remains responsive. Audio uses
the SDK’s OpenAL framework. The SDL2 window is attached to a UIKit scene.

`tests/ios_import_tests.c` checks original IPA data and rejects truncated/corrupt
archives. `tests/ios_save_tests.m` checks save round trips, cross-game rejection,
previous-save backup, stale-world removal, and path validation.

```sh
sh test-ios.sh '/path/to/Doom 2 RPG.ipa'
```

Device installation and actual signed-in iCloud transfer require validation on
your iPhone. No game assets or personal saves are included in published packages.
