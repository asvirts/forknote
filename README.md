# Forknote: Food & Symptom Log

**Meals, flares. Pay once.**

Forknote is a fast, local-first meal and symptom log for **iPhone and iPad** (iOS 26+). It opens on **Add a meal**. The last meal repeats in one tap. A symptom is a name and a strength, with the time set to now. The pattern screen is one sentence about what shows up alongside a symptom. Your log stays on the device.

Free to download. **Forknote Pro** ($8.99 once, Family Sharing) unlocks pattern sentences for the whole log, a custom symptom list, a plain PDF, and a Lock Screen control to log a meal. No ads, no account, no analytics.

The working name was Steady. That name is already used on the App Store, including Steady: GLP-1 Tracker, so the public name is Forknote. The project folder stays `steady`. The bundle id is `com.asvirts.forknote`.

See [docs/SPEC.md](docs/SPEC.md) for the screen flow and the pattern rules. App Store copy, URLs, and the submission checklist are in [docs/APP_STORE_METADATA.md](docs/APP_STORE_METADATA.md) and [docs/LAUNCH_CHECKLIST.md](docs/LAUNCH_CHECKLIST.md).

## Getting started

```sh
brew install xcodegen            # once
xcodegen generate                # generates Forknote.xcodeproj from project.yml
open Forknote.xcodeproj
```

To run on a device, set your Apple Developer Team in `project.yml` (`DEVELOPMENT_TEAM`) and register the App Group `group.com.asvirts.forknote`. The group lets the Lock Screen control tell the app it was opened from the control.

### Tests and build

```sh
swift test --package-path Packages/ForknoteKit
xcodebuild -project Forknote.xcodeproj -scheme Forknote -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

### App icon

```sh
swift scripts/generate_icon.swift Forknote/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png
```

## Layout

| Path | What |
|---|---|
| `Forknote/` | iPhone and iPad app |
| `ForknoteWidgets/` | Lock Screen / Control Center control that opens the meal screen |
| `Packages/ForknoteKit/` | `ForknoteCore` (pattern math, report text), `ForknoteStore` (SwiftData, StoreKit 2), `ForknoteIntents` |
| `project.yml` | XcodeGen spec |
| `docs/SPEC.md` | Product spec and pattern rules |

## Status

- [x] Meal and symptom logging, repeat last meal, recents
- [x] Pattern sentence with the exposure, everyday-food, and window rules
- [x] StoreKit 2 Forknote Pro, Restore Purchases on the paywall and in Settings
- [x] Plain PDF and Lock Screen meal control
- [x] `PrivacyInfo.xcprivacy` for Data Not Collected
- [x] Version 1.0.0, in-app Privacy Policy, Terms, Support, and Delete All Local Data
- [ ] App Store Connect record, screenshots, and the signed upload (see the launch checklist)
