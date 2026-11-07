# Forknote — Copy-Paste App Store Connect Metadata (v1.0.0)

Character counts below were checked against App Store Connect limits. Keywords do not repeat words already in the title or subtitle.

---

## 1. Core App Listing (en-US)

- **App Name (28 / 30):** `Forknote: Food & Symptom Log`
- **Subtitle (24 / 30):** `Meals, flares. Pay once.`
- **Primary Category:** Healthcare & Fitness
- **Secondary Category:** Lifestyle
- **Content Rights:** Does not contain, show, or access third-party content
- **Age Rating:** 4+. Answer None on every content question, including Medical or Treatment Information. Forknote stores what the person types. It does not provide medical or treatment information. Unrestricted Web Access: No.
- **Copyright:** `2026 Andrew Virts`
- **SKU:** `forknote-ios-001`
- **Bundle ID:** `com.asvirts.forknote`
- **Primary Language:** English (U.S.)

---

## 2. Required URLs

Live from the public repo `asvirts/forknote`, GitHub Pages, branch `main`, folder `/docs`:

- **Privacy Policy URL:** `https://asvirts.github.io/forknote/privacy.html`
- **Support URL:** `https://asvirts.github.io/forknote/support.html`
- **Marketing URL:** `https://asvirts.github.io/forknote/`
- **Terms of Use** (also linked in the app): `https://asvirts.github.io/forknote/terms.html`

The in-app constants live in `Packages/ForknoteKit/Sources/ForknoteCore/Config.swift`.

---

## 3. Keywords (100 / 100)

Apple indexes Forknote, Food, Symptom, Log, Meals, flares, Pay, and once from the title and subtitle. Paste this string with no spaces after the commas:

```text
diary,tracker,bloating,headache,pain,gut,ibs,nausea,journal,private,notes,rash,fatigue,reflux,energy
```

---

## 4. Promotional Text (134 / 170)

```text
Log meals and symptoms in a few taps. One sentence shows what shows up alongside how you feel. The log stays on your iPhone. Pay once.
```

---

## 5. Description

```text
Forknote opens on Add a meal.

Type a few food names, set the time, and add a note if you want one. Repeat the last meal in one tap. Log a symptom in two taps: a name, then a strength from 1 to 5. The time is now unless you change it.

ONE SENTENCE
The pattern screen is a single sentence about a food that shows up alongside a symptom in your own log. It compares symptom days with quiet days, in a 2-hour window and a 24-hour window. A food you eat on most days stays quiet. A food also stays hidden until it has shown up in several meals.

A PERSONAL LOG
Forknote is a personal log. It is not a medical device. The sentence describes your log. It does not tell you what is wrong or what to change.

FREE FOREVER
Unlimited meals and symptoms, and a pattern sentence for the last 7 days. No ads. No account. No subscription.

FORKNOTE PRO — $8.99 ONCE
Pattern sentences across the whole log, your own symptom names, a plain PDF of meals, symptoms, and those sentences, and a Lock Screen control that opens on a meal. Family Sharing included.

ON THIS DEVICE
Meals and symptoms stay on your iPhone or iPad. App Store privacy label: Data Not Collected.
```

---

## 6. What’s New (v1.0.0)

```text
First release. Log meals and symptoms on your iPhone or iPad, then read one sentence about what shows up alongside how you feel.
```

---

## 7. In-App Purchase (`com.asvirts.forknote.pro`)

- **Type:** Non-Consumable
- **Reference Name:** `Forknote Pro`
- **Product ID:** `com.asvirts.forknote.pro`
- **Price:** `$8.99 USD`
- **Family Sharing:** On
- **Display Name (12 / 30):** `Forknote Pro`
- **Description (52 / 55):** `Full history, your symptoms, a PDF, and Lock Screen.`
- **Review screenshot:** the paywall, with the price and Restore Purchases visible
- **Review note:** Open Settings, or the Pattern tab’s full-history row, and tap Unlock Forknote Pro.

Attach this product to version 1.0 before you submit the binary.

---

## 8. App Privacy

Question: “Do you or your third-party partners collect data from this app?”

Answer: **No, we do not collect data from this app.**

Why that answer matches the app:

- Meals, symptoms, and symptom names stay in the on-device SwiftData store.
- There is no account, analytics SDK, advertising SDK, or developer server.
- StoreKit tells the app only whether Forknote Pro is unlocked. Apple processes the payment.
- The PDF is created on the device and leaves only through the system share sheet.
- The App Group `group.com.asvirts.forknote` holds one on-device flag for the Lock Screen control.

`PrivacyInfo.xcprivacy` sets `NSPrivacyTracking` to false and lists no collected data types. `UserDefaults` is declared for app functionality (`CA92.1`) and for the product-interaction flag that records whether Pro is unlocked (`1C8F.1`).

---

## 9. App Review notes

```text
Forknote is a personal meal and symptom log. It is not a medical device. There is no account.

To review: open the app (it starts on Add a meal), save a meal, then open the Symptom tab and tap a name and a strength. The Pattern tab explains that a sentence needs more logged days. Settings includes Restore Purchases, Privacy Policy, Terms of Use, Support, and Delete All Local Data. The paywall also has Restore Purchases, Privacy Policy, and Terms of Use.

Forknote Pro is the non-consumable com.asvirts.forknote.pro at $8.99 with Family Sharing. It unlocks full-history sentences, a custom symptom list, the PDF, and the Lock Screen control. Free logging is unlimited.
```

---

## 10. Export compliance

`ITSAppUsesNonExemptEncryption` is false in the generated Info.plist. The app uses only standard HTTPS through the system (StoreKit and opening the privacy pages). Answer the upload question as using encryption that is exempt, or let the Info.plist key skip the question.
