# DayDraft

A **Daily Planner** app built with Flutter. Plan your day with prioritised tasks — all stored locally on your device.

---

## Features

### Daily Planner
- **Interactive calendar** — switch between week and month views, centered header with no clutter
- **Swipe left/right** on the task list to navigate between days — calendar selection stays in sync
- Add tasks for **today or any future date** — past dates are blocked in the date picker
- Set an **optional time** for each task
- Three **priority levels**: Low (green), Medium (orange), High (red) — each with a distinct colour-coded card
- Enable a **local notification reminder** for tasks that have a time set
- Tasks are sorted by time, with completed tasks moved to the bottom
- Tap anywhere on a task card to **mark as done / incomplete** (confirmation dialog required)
- Tasks from **past days are locked** — the checkbox is faded and toggling is disabled
- The **+ Add Task button is hidden** on past dates
- Delete individual tasks with a confirmation dialog — **reflects instantly** (optimistic update, no refresh needed)
- Duplicate saves are **prevented** — Save button disables itself while the operation is in progress

---

## Tech Stack

| Layer | Library / Tool |
|---|---|
| Framework | [Flutter](https://flutter.dev) (Dart SDK ≥ 3.5) |
| State Management | [flutter_riverpod 2.x](https://riverpod.dev) |
| Local Database | [sqflite](https://pub.dev/packages/sqflite) |
| Notifications | [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) |
| Calendar UI | [table_calendar](https://pub.dev/packages/table_calendar) |
| Timezones | [timezone](https://pub.dev/packages/timezone) |
| App Icon Generator | [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons) |
| Utilities | [intl](https://pub.dev/packages/intl), [uuid](https://pub.dev/packages/uuid), [path](https://pub.dev/packages/path) |

---

## Project Structure

```
lib/
├── main.dart                  # App entry point, initialises DB & notifications
├── app.dart                   # MaterialApp setup, theme, routing
├── core/
│   └── theme/
│       └── app_theme.dart     # Light and dark theme definitions
├── features/
│   └── planner/
│       ├── models/            # Task data model (priority enum, toMap/fromMap)
│       ├── providers/         # Tasks Riverpod providers & notifier (optimistic updates)
│       ├── screens/           # Planner screen (swipe + calendar), Task editor screen
│       └── widgets/           # Task tile widget, Priority badge
└── shared/
    ├── services/
    │   ├── db_service.dart            # SQLite singleton (tasks CRUD)
    │   └── notification_service.dart  # Local notification scheduling
    └── widgets/
        └── empty_state.dart           # Reusable empty-state placeholder

assets/
└── icon/
    ├── app_icon.png             # Full icon (1024×1024) — used for iOS & legacy Android
    └── app_icon_foreground.png  # Foreground layer with transparent padding — used for Android adaptive icons
```

---

## Database Schema

### `tasks`
| Column | Type | Description |
|---|---|---|
| `id` | INTEGER PK | Auto-increment |
| `title` | TEXT | Task title |
| `date` | TEXT | ISO 8601 date |
| `timeMins` | INTEGER | Minutes since midnight; -1 = no time |
| `priority` | TEXT | `low` / `medium` / `high` |
| `isDone` | INTEGER | 0 or 1 |
| `reminderEnabled` | INTEGER | 0 or 1 |
| `createdAt` | TEXT | ISO 8601 |

---

## Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.5.0
- Android Studio / Xcode (for emulators) or a physical device

### Run the app

```bash
# Clone the repository
git clone <your-repo-url>
cd noteTracker

# Install dependencies
flutter pub get

# Run on a connected device or emulator
flutter run
```

### Generate app icons (run once after adding/changing the icon image)

```bash
dart run flutter_launcher_icons
```

> Requires `assets/icon/app_icon.png` and `assets/icon/app_icon_foreground.png` to be present.

### Build a release APK (Android)

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Build split APKs (smaller download size)

```bash
flutter build apk --release --split-per-abi
```

---

## App Icon Setup (Android Adaptive Icons)

Android 8+ uses adaptive icons — a two-layer system where the OS applies a shape mask (circle, squircle, etc.). To avoid the icon appearing as a square inside a circle:

| File | Purpose | Size |
|---|---|---|
| `assets/icon/app_icon.png` | iOS & legacy Android fallback | 1024×1024 px |
| `assets/icon/app_icon_foreground.png` | Android adaptive foreground layer | 1024×1024 px, icon centered in ~60% of canvas with transparent padding |

The background color is configured in `pubspec.yaml` under `adaptive_icon_background`.

---

## Supported Platforms

| Platform | Status |
|---|---|
| Android | ✅ Supported |
| iOS | ✅ Supported |
| Windows | ✅ Supported |
| macOS | ✅ Supported |
| Linux | ✅ Supported |
| Web | ✅ Supported |

---

## Business Rules

- Tasks can only be created for **today or future dates** — the date picker blocks past dates.
- Tasks belonging to **a past date cannot be toggled** done/incomplete — the checkbox is locked.
- The **Add Task FAB** is hidden when a past date is selected on the calendar.
- Saving a task is **guarded against multiple taps** — the Save button disables itself and shows a spinner while saving.
- A task can **only be saved once** — navigates back to the planner immediately after saving.
- Marking a task as done or incomplete requires **explicit confirmation** via a dialog.
- Deleting a task is **instant** (optimistic update) — the card disappears immediately without needing a refresh.
- A reminder notification is only scheduled when **both a time and the reminder toggle** are set.
- The task list and calendar **stay in sync** when swiping between days.
