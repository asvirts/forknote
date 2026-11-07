# Forknote — App Store submission checklist (v1.0.0)

Copy for App Store Connect is in [APP_STORE_METADATA.md](./APP_STORE_METADATA.md). The public pages are `docs/index.html`, `privacy.html`, `support.html`, and `terms.html`.

This checklist stops before you tap Submit. Screenshots, the App Store Connect record, the App Group in the developer portal, and the signed upload are still manual.

---

## 1. Public Privacy Policy and Support pages

App Store Connect needs live HTTPS URLs before you can submit.

```sh
# From /Users/asvirts/Documents/Apps/steady
gh repo create asvirts/forknote --public --source=. --remote=origin --push
gh api -X POST repos/asvirts/forknote/pages \
  -f "build_type=legacy" \
  -f "source[branch]=main" \
  -f "source[path]=/docs"
```

Confirm these load in a browser:

- https://asvirts.github.io/forknote/
- https://asvirts.github.io/forknote/privacy.html
- https://asvirts.github.io/forknote/support.html
- https://asvirts.github.io/forknote/terms.html

Pages can take a minute after the API call. If the API rejects the request, turn Pages on by hand: repo **Settings → Pages → Deploy from branch `main` / `docs`**.

---

## 2. Apple Developer identifiers

Team `H4ND8LAYMT` is already set in `project.yml`.

1. Register the App Group `group.com.asvirts.steady`.
2. App ID `com.asvirts.steady`: App Groups (that group) and In-App Purchase.
3. App ID `com.asvirts.steady.widgets`: App Groups (that group).
4. There is no iCloud container and no push capability. Do not add them.

---

## 3. App Store Connect record

1. New app, iOS, name `Forknote: Food & Symptom Log`, bundle ID `com.asvirts.steady`, SKU `forknote-ios-001`, primary language English (U.S.).
2. Paste the fields from [APP_STORE_METADATA.md](./APP_STORE_METADATA.md): subtitle, categories, keywords, promotional text, description, URLs, copyright, What’s New.
3. App Privacy: **Data Not Collected**. Publish the answers.
4. Age rating: None on every question, including Medical or Treatment Information. The app does not provide medical content. Expected result: 4+.
5. Create the non-consumable:
   - Product ID `com.asvirts.steady.pro`
   - Reference name `Forknote Pro`
   - Family Sharing on
   - Price $8.99
   - Display name `Forknote Pro`
   - Description `Full history, your symptoms, a PDF, and Lock Screen.`
6. Upload a screenshot of the paywall as the IAP review image.
7. On the version 1.0 page, attach `Forknote Pro` under In-App Purchases before you submit the binary.

---

## 4. Screenshots you still need to capture

Do not ship generated mockups as the store screenshots. Capture the running app:

- iPhone 6.9-inch: Add a meal, a saved meal with Repeat last meal, the symptom strength step, the pattern sentence, and the paywall.
- iPad 13-inch: the same meal screen, since iPad is a supported destination.

The pattern sentence only appears after the log meets the rules in `docs/SPEC.md` (at least 5 meals of that food, 3 symptom days, and 3 quiet days, and the food is not an everyday food). A short log should show the empty sentence instead.

---

## 5. Build, archive, and upload

```sh
xcodegen generate
swift test --package-path Packages/ForknoteKit
xcodebuild -project Forknote.xcodeproj \
  -scheme Forknote \
  -destination 'generic/platform=iOS' \
  -archivePath .build/Forknote.xcarchive \
  archive
```

Upload the archive with Xcode Organizer or `xcodebuild -exportArchive`. Version is `1.0.0` (build 1). Signing uses team `H4ND8LAYMT`.

---

## 6. Review and submit

- Review notes are in [APP_STORE_METADATA.md](./APP_STORE_METADATA.md). There is no demo account.
- Confirm Restore Purchases is on the paywall and in Settings.
- Confirm Privacy Policy, Terms of Use, Support, and Delete All Local Data are in Settings.
- Export compliance is already set with `ITSAppUsesNonExemptEncryption` = false.
- Submit for review only after the privacy and support URLs load and the IAP is attached to the version.
