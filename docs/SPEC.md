# Forknote: Food & Symptom Log

**App Store title:** `Forknote: Food & Symptom Log` (28/30)
**Subtitle:** `Meals, flares. Pay once.` (24/30)
**Bundle id:** `com.asvirts.steady`
**Pro product:** `com.asvirts.steady.pro` — non-consumable, Family Sharing, $8.99 once
**Platforms:** iPhone and iPad, iOS 26+

The working name was Steady. App Store search already returns several apps by that name, including **Steady: GLP-1 Tracker**, which logs meals, symptoms, and a clinician report. Forknote is the public name. The project folder and bundle id stay on `steady`.

Forknote is the pay-once alternative to mySymptoms ($59.99/year). The thing to beat is logging speed and one plain sentence.

> Forknote is a personal log. It is not a medical device.

---

## 1. Product principles

1. **Open on Add a meal.** No splash, no account, no dashboard.
2. **Repeat the last meal in one tap.** Same foods, time set to now, note left blank. Undo is available for a few seconds.
3. **A symptom is two taps:** the name, then a strength from 1 to 5. Time defaults to now.
4. **Foods are whatever the person types,** plus recents. No food database, no barcode lookup, no Open Food Facts.
5. **One sentence.** The pattern screen does not chart, rank a diet, or tell anyone what to stop eating.
6. **Private by design.** SwiftData on device. No analytics SDK. Privacy label: **Data Not Collected**.

The sentence says a food **shows up alongside** a symptom. It never says "causes", "diagnoses", or "avoid".

---

## 2. Free vs Forknote Pro

| Feature | Free | Pro ($8.99 once) |
|---|---|---|
| Unlimited meals and symptoms | Yes | Yes |
| Repeat last meal, recents, edit, delete | Yes | Yes |
| Pattern sentence | Last 7 days | Full log |
| Symptom list | Starter list | Add, rename, remove |
| Plain PDF of meals, symptoms, and sentences | — | Yes |
| Lock Screen control to log a meal | — | Yes |
| Restore Purchases | Yes | Yes |

StoreKit 2 product `com.asvirts.steady.pro`, Family Sharing on. Restore Purchases is on the paywall and in Settings. The paywall opens from a Pro action. It does not open on launch.

The Lock Screen control is part of the app extension. Tapping it opens Forknote. Pro lands on Add a meal. Otherwise the paywall opens, with Restore Purchases.

---

## 3. Logging

A meal is a few food names, a time, and an optional note. The food field splits on commas and new lines. "Greek Yogurt" and "greek yogurt" are the same food. The spelling used most often is the one that shows up in the sentence.

The starter symptoms are Pain, Bloating, Nausea, Headache, Fatigue, Rash, Reflux, and Brain fog. They are labels for a personal log, not a catalog of conditions. Pro can add, rename, and remove names. Renaming updates earlier logs of that name. The list always keeps at least one name.

iPhone is the primary layout. iPad uses the same screens in a readable column, all orientations, and ⌘N focuses Add a meal.

---

## 4. Pattern math

`PatternMath` in `ForknoteCore` is the only place a sentence is built. The PDF uses those same sentences.

**Range.** Free uses the last 7 calendar days, including today. Pro uses the whole log through the end of today. A meal up to 24 hours before the range can still fall inside a symptom's lookback. It does not count as an exposure.

**Days.** A symptom day is a calendar day with at least one log of that symptom. Strength is stored and printed. It does not filter the sentence. A quiet day is a calendar day in range with at least one meal and no log of that symptom. Days with neither are ignored.

**Food identity.** Trimmed, internal whitespace collapsed, compared case-insensitively. No stemming and no ingredient grouping.

**Windows.**

- **2 hours:** a meal of that food with `eatenAt` from 2 hours before the symptom through the symptom time, inclusive. On a quiet day, the same length of window ends at the median clock time of that symptom.
- **24 hours:** a meal of that food in the 24 hours before the symptom. On a quiet day, any meal of that food on that calendar day.

When both windows qualify, the sentence uses the 2-hour window.

**A food stays quiet unless all of these are true:**

| Rule | Value |
|---|---|
| Exposures (meals in range that contain the food) | at least 5 |
| Everyday food | eaten on 70% or more of meal days (`foodDays * 10 >= mealDays * 7`) |
| Symptom days and quiet days | at least 3 of each, so a 7-day log can still speak |
| Symptom days where the food shows up in the window | at least 3, and at least half of the symptom days |
| Gap | symptom-day rate is more than the quiet-day rate by at least 30 points |

Everyday is checked before the gap. A food on 7 of 10 meal days stays quiet even when it is also on every pain day. A food on 6 of those 10 days is not everyday and can surface. Fewer than 5 meals stays hidden even when every one of them sits before a symptom.

The thresholds use integer cross-multiplication so 7 of 10 and a 30-point gap are exact.

**The sentence**

`Oats shows up alongside pain in 6 of your last 6 pain days, across 6 meals, within 2 hours.`

The 24-hour sentence omits "within 2 hours". "Across N meals" is the exposure count. The screen shows the single strongest sentence. The PDF lists every food that qualifies, strongest first, one window each.

Empty state: "Nothing stands out alongside your symptoms yet."

---

## 5. PDF

Pro exports one plain PDF: meals (newest first), symptoms with strength, and the sentences. The page says it is a personal log and not a medical device. Notes are included as the person wrote them.

---

## 6. Tech

| Area | Choice |
|---|---|
| UI | SwiftUI, iOS 26, iPhone and iPad |
| Language | Swift 6, strict concurrency |
| Storage | SwiftData, on device |
| Purchases | StoreKit 2 |
| Project | XcodeGen `project.yml` |
| Tests | Swift Testing in `Packages/ForknoteKit` |
| Control | WidgetKit `ControlWidget` + App Intent, App Group flag |

No account. No analytics. No ads. No network API.

---

## 7. Tests that lock the math

- Everyday cheese on 7 of 10 meal days stays quiet while lamb, only on the pain days, can surface.
- Four shrimp meals clustered before symptoms stay hidden.
- Oats before pain, with daily rice and two shrimp meals, surfaces as one 2-hour sentence. Rice and shrimp do not.
- Tea eaten exactly 2 hours before a symptom uses the 2-hour sentence. Juice one minute earlier uses the 24-hour sentence.
- A cluster older than 7 days is absent from the free range and present in the full log.
- Five oats meals inside the last 7 days can produce a sentence.
- Two quiet days are not enough to compare.
