# AGENTS.md — Forknote (`/Users/asvirts/Documents/Apps/steady`)

Inherits portfolio-wide rules from [`../AGENTS.md`](../AGENTS.md).

---

## App Identity & Positioning Rules

- **Public name:** Forknote. The working name Steady is taken on the App Store (including Steady: GLP-1 Tracker, which also logs meals and symptoms).
- **App Store title:** `Forknote: Food & Symptom Log` (28 / 30)
- **Subtitle:** `Meals, flares. Pay once.` (24 / 30)
- **Bundle id:** `com.asvirts.steady`. **Pro product:** `com.asvirts.steady.pro`, non-consumable, Family Sharing, **$8.99** once.
- **Platforms:** iPhone and iPad, iOS 26+. No Mac or Watch target.
- **Copy:** This is a personal log. It is not a medical device. Say a food **shows up alongside** a symptom. Never say "causes", "diagnoses", or "avoid". Do not call a food a trigger in the interface.
- **Out of scope:** food database, barcode lookup, Open Food Facts, elimination-diet protocol, FODMAP catalog, chatbot, account, ads, analytics SDK.
- **Privacy label:** Data Not Collected.
- **Public pages:** `https://asvirts.github.io/forknote/` (privacy, support, and terms). The same URLs are `ForknoteConfig` constants. Do not point them at a private host.

---

## Commands

```sh
xcodegen generate
swift test --package-path Packages/ForknoteKit
xcodebuild -project Forknote.xcodeproj -scheme Forknote -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
swift scripts/generate_icon.swift Forknote/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png
```

---

## Architecture Guardrails

1. **Swift 6 strict concurrency** (`SWIFT_STRICT_CONCURRENCY: complete`). Pattern math stays in `ForknoteCore` as pure functions on value types. Do not move it into a SwiftData model.
2. **Foods are typed strings.** Match them with `NameKey` (trim, collapse whitespace, case-insensitive). Do not stem, translate, or group "milk" with "cheese".
3. **Pattern rules live in `PatternMath` and `docs/SPEC.md`.** Tests in `PatternMathTests` are the contract: everyday foods stay quiet, fewer than 5 exposures stay hidden, a food clustered before symptoms can surface.
4. **Free vs Pro.** Unlimited meals and symptoms, and pattern sentences for the last 7 days, stay free. Full history, the custom symptom list, the PDF, and the Lock Screen control are Pro. Restore Purchases stays on the paywall and in Settings.
5. **Local only.** SwiftData on device. No CloudKit and no account. The App Group `group.com.asvirts.steady` only shares the Lock Screen control flag.
