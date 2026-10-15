# Personal OS — Flutter app

A personal productivity/discipline app: daily time-blocked schedule, book
tracking, health/journal/vision logging, learning & music session logs,
and local reminders — backed by a custom PHP API.

Built from `flutter_spec.md`, iterating screen by screen with real backend
responses used to correct assumptions along the way (see "Backend notes"
below). Base app language is **English** (UI labels/copy); content that
comes straight from the API (vision text, quotes, block/practice names
you typed yourself) is shown as-is, since that's your data, not app chrome.

---

## Tech stack

- **Flutter** (Android target; iOS untested)
- **State management:** `flutter_riverpod` (`StateNotifierProvider` /
  `FutureProvider`, mostly `.autoDispose`)
- **Navigation:** `go_router` for the auth/shell split, plain
  `Navigator.push` for modal-style detail screens (book detail) and
  `showModalBottomSheet` for forms/edit sheets
- **HTTP:** `http` package via a single centralized `ApiClient`
- **Auth storage:** `flutter_secure_storage` (JWT bearer token)
- **Notifications:** `flutter_local_notifications` + `timezone`
- **Theme:** light theme (see Design decisions)

---

## Getting started

This has been developed file-by-file in a sandbox without the Flutter SDK
installed, so `android/`, `ios/`, and the Gradle wrapper were never
generated here. To run it:

```bash
# 1. Generate a fresh Flutter project shell
flutter create personal_os
cd personal_os

# 2. Drop this project's pubspec.yaml, lib/, and analysis_options.yaml
#    on top of the generated ones (keep the generated android/ and ios/)

# 3. Install dependencies
flutter pub get

# 4. Add to android/app/src/main/AndroidManifest.xml, inside <manifest>:
```
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
```
```bash
# 5. In android/app/build.gradle, enable core library desugaring
#    (required by flutter_local_notifications) — see "Gradle gotchas" below

# 6. Run
flutter run
```

### Gradle gotchas already hit & fixed once

- **`flutter_local_notifications` needs core library desugaring.** In
  `android/app/build.gradle`:
  ```groovy
  android {
    compileOptions {
      sourceCompatibility JavaVersion.VERSION_11
      targetCompatibility JavaVersion.VERSION_11
      coreLibraryDesugaringEnabled true
    }
    kotlinOptions { jvmTarget = '11' }
  }
  dependencies {
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'
  }
  ```
- **Avoid native "detect device timezone" plugins** (e.g.
  `flutter_timezone`) — one caused an "Inconsistent JVM Target
  Compatibility" Kotlin/Gradle build failure. Not needed anyway: this is a
  single-user app and the backend is fixed to `Africa/Porto-Novo`
  (UTC+1, no DST), so the timezone is hardcoded in
  `notification_service.dart` instead.

---

## Project structure

```
lib/
├── main.dart                     # Entry point, theming, go_router, notification init
├── core/
│   ├── api/                      # One file per resource: api_client, auth_api,
│   │                              # dashboard_api, schedule_api, books_api, health_api,
│   │                              # journal_api, vision_api, learning_api, music_api
│   ├── models/                   # Matching Dart models, defensive JSON parsing
│   ├── services/                 # auth_service (+ all API providers), storage_service,
│   │                              # notification_service
│   ├── theme/                    # app_theme.dart — colors, light ThemeData
│   └── utils/json_parsing.dart   # asInt() / asIntOrNull() — see "Backend notes"
├── features/
│   ├── auth/login_screen.dart
│   ├── dashboard/dashboard_screen.dart
│   ├── schedule/                 # Planning: 4-tab Scaffold (Today/Week/History/Edit)
│   │   ├── schedule_screen.dart
│   │   ├── providers/schedule_providers.dart
│   │   ├── widgets/block_card.dart
│   │   └── tabs/{today,week,history,edit}_tab.dart
│   ├── books/                    # phase accordion, filters, detail w/ confetti
│   ├── health/                   # 3 toggle buttons, POST-vs-PUT-on-exists logic
│   ├── journal/                  # Write (autosave) / Entries tabs
│   ├── vision/                   # My vision (autosave) / Goals tabs
│   ├── learning/                 # domain stats + session list (optimistic add/delete)
│   ├── music/                    # type stats + recent projects + session list
│   ├── more/more_screen.dart     # menu linking to the screens above
│   └── shell/main_shell.dart     # bottom nav (customized by hand — see note below)
└── shared/widgets/                # glass_card, status_badge, loading_skeleton, coming_soon
```

> **Note on `main_shell.dart`:** this file has been hand-edited directly
> (Dashboard renamed to Home, among other tweaks). I don't hold a copy of
> its current state — treat it as yours, not something I'll silently
> overwrite.

---

## Feature status

| Feature | Status |
|---|---|
| Auth (login, session restore, 401 → logout) | ✅ |
| Dashboard | ✅ (health chips interactive, blocks timeline, active-block card) |
| Planning (Today/Week/History/Edit) | ✅ |
| Books (phases, filters, detail, confetti) | ✅ |
| Health | ✅ |
| Journal | ✅ |
| Vision & Goals | ✅ |
| Learning | ✅ |
| Music | ✅ |
| Local notifications (block reminders) | ✅ (see limitations) |
| Spiritual | 🟡 model only (`core/models/spiritual_model.dart`) — API, providers, and screen not built yet |
| Notes | ❌ not started |
| Network (contacts) | ❌ not started |
| Monthly AI recap | ❌ not started |
| Stats | ❌ not started |

---

## Design decisions & known simplifications

- **Light theme**, not the originally-built dark "glassmorphism" look —
  switched after it read as cramped/low-effort. Cards are white with a
  soft shadow (`shared/widgets/glass_card.dart` — name kept for backward
  compatibility, it's not actually translucent/glass anymore).
- **Optimistic UI for Learning and Music**: adding/deleting a session
  updates the list immediately (temp id, reconciled with the server
  response, rolled back on failure) instead of waiting on the network
  round-trip first. **Not yet retrofitted** to Books, Vision, and Health —
  those still update only after the request resolves, which can feel
  slower/less "reactive." Worth a dedicated pass if it's noticeable.
  Schedule's Today tab is already effectively optimistic (status updates
  apply locally right after a successful call, no full refetch needed).
- **No offline support** — this matches the original spec explicitly
  ("Pas d'état offline"). Every screen hits the network directly, no local
  cache/sync queue. A real offline mode (local DB + sync) would be a much
  bigger, separate change.
- **`is_current` on schedule blocks is computed client-side**
  (`isBlockCurrentNow()` in `schedule_block_model.dart`), comparing the
  block's time range to the current wall-clock time — the backend doesn't
  reliably compute/return this field itself.
- **Domain/category values sent to the API stay in their original
  language** (e.g. Learning's `Programmation`/`Réseau`/`IA`/`Autre`) since
  the backend validates against those exact fixed strings — only the
  *display* labels are translated to English (`learningDomainLabel()`
  etc.). Same idea for book phases and statuses.
- **Notifications:**
  - Reminders fire 5 minutes before each block's start time.
  - Timezone hardcoded to `Africa/Porto-Novo` (see Gradle gotchas above).
  - Rescheduled (cancel-all + reschedule) every time the Dashboard loads
    fresh data — **not** a true midnight background trigger. A real
    midnight trigger needs a background-isolate scheduler
    (`android_alarm_manager_plus` / `workmanager`) with its own native
    setup; this "refresh on open" approximation covers opening the app at
    least once a day. Flag it if that's not good enough in practice.
  - A "Send test notification" action lives in **More** for quickly
    verifying permissions/channel setup without waiting for a real
    reminder.
  - On Android < 13 (like this project's main test device, a Galaxy
    S8/SM-G950U), there's no runtime permission prompt at all — that's
    normal OS behavior, not a bug.

---

## Backend notes

The backend is a custom PHP API (no framework) at
`https://test.greentechnos.com/api`. A few things learned by reading
actual controller/router code and real network responses, in case they
save time later:

- **Numeric aggregates sometimes come back as strings.** SQL
  `SUM()`/`COUNT()`-style fields (e.g. `GET /schedule/history`'s
  `done`/`partial`/`skipped`/`pending`) can arrive as `"1"` instead of `1`
  depending on the query. Every model that touches a plausibly-aggregated
  field parses through `asInt()`/`asIntOrNull()`
  (`core/utils/json_parsing.dart`) instead of a raw `as int` cast, which
  would throw on a string.
- **Don't trust controller docblock comments as the routing source of
  truth.** Early on I "corrected" `/schedule` → `/blocks` based on a
  comment in `BlockController.php` describing its own intended routes —
  but the actual `router.php` maps *both* the `schedule` and `blocks`
  resources to the same `TemplateController`. The comment described intent
  at some point in time, not the live routing table. Lesson: check
  `router.php` (or equivalent) directly before "fixing" an endpoint path.
- **Real table names** (from `phpMyAdmin`, database `greentp171`):
  `m_w_template_blocks` (per-day-of-week block definitions — `day_of_week`
  is a real column, so the Week tab's per-weekday model is correct),
  `m_w_template_logs` (daily status logs, FK → `m_w_template_blocks`),
  `m_w_week_templates`, `m_w_spiritual_logs`, `m_w_spiritual_practices`,
  `m_w_music_sessions`, `m_w_notes`, `m_w_projects`, `m_w_tasks`,
  `m_w_users`, `m_w_user_settings`.
- **Server timezone:** `Africa/Porto-Novo` (UTC+1, no DST) — see
  Notifications above.

---

## Next steps

Pick up in this rough order of remaining effort: finish **Spiritual**
(model exists, needs API/providers/screen — same toggle pattern as
Health, plus a "manage practices" settings view), then **Notes** and
**Network** (independent, simple CRUD screens), then **Recap** and
**Stats** last since they aggregate data from everything else already
built.