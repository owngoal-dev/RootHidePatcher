<img src="derootifier-2-modified.png" alt="Logo" width="70" height="70">

# RootHidePatcher

Convert supported jailbreak tweak packages to RootHide packages. Requires iOS 15 or later and a working RootHide environment for conversion. Not every package is compatible; the existing conversion script checks package architecture and rejects known unsupported packages.

## Conversion

Import a `.deb` from the file picker or open it in Patcher from another app. Choose one method:

| Method | Existing script argument | Behavior |
| --- | --- | --- |
| Direct Conversion | Empty | Convert simple tweaks, including eligible rootful packages. |
| Rootless Compatibility (default) | `AutoPatches` | Apply the Rootless Compat Layer integration. |
| Dynamic Patches | `DynamicPatches` | Require the matching dynamic patch package. |

The result stays available with the complete script output. Successful packages can be opened in an installed supported package manager or exported through the system share sheet. Failed conversions retain the selected file and method for retry. Logs can be selected, copied, and shared.

Output naming and storage remain unchanged: `/var/mobile/RootHidePatcher/<name>.deb` inside the RootHide environment. `patch.sh`, `repackDeb`, and the vendored process runner retain the original conversion, signing, dependency, and cleanup behavior.

## Interface

The interface follows the native utility-app conventions in [platformize-app-ios](https://github.com/owngoal-dev/platformize-app-ios) and OwnGoal Studio's existing apps: grouped forms, system navigation, semantic colors, Dynamic Type, and named accessibility controls. English and Simplified Chinese are included, with light and dark appearances and a bounded reading width on iPad.

This is an interface rewrite of the existing app, not a migration to the template's daemon or multi-bootstrap packaging architecture. The RootHide backend, bundle identifier, minimum OS, existing app icon, and GPL license remain in place. The old animated-gradient dependency has been removed.

## Build and test

Build the device application without signing:

```sh
xcodebuild -project RootHidePatcher.xcodeproj -scheme RootHidePatcher \
  -configuration Release -destination 'generic/platform=iOS' \
  -derivedDataPath /private/tmp/roothide-patcher-device CODE_SIGNING_ALLOWED=NO build
```

Run the regression tests on an available simulator (substitute its name):

```sh
xcodebuild -project RootHidePatcher.xcodeproj -scheme RootHidePatcher \
  -destination 'platform=iOS Simulator,name=iPhone 17e' \
  -derivedDataPath /private/tmp/roothide-patcher-tests CODE_SIGNING_ALLOWED=NO test
```

The tests cover the three script arguments, output filenames, source preservation, same-name replacement, same-path import, failed imports, and the simulator's refusal to perform a real conversion. The simulator supports interface preview and file import only. Actual package conversion and opening the result in another package manager require a RootHide device; a successful simulator test does not verify those operations.

The existing Theos `Makefile` remains the packaging entry point. `build.command` is a legacy Derootifier script and does not name the current project.

## License

RootHidePatcher retains its [GNU GPL v3 license](LICENSE).

[AuxiliaryExecute](https://github.com/Lakr233/AuxiliaryExecute/blob/main/LICENSE) is MIT licensed. The build copies both source license notices into the app for the About → Licenses screen.
