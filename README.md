# DayDraft

A unified **Notes & Daily Planner** app built with Flutter. Write rich-text notes and plan your day with prioritised tasks — all stored locally on your device.

---

## Features

### Notes
- Create, edit, and delete notes with a **rich-text editor** (bold, italic, headings, lists, and more powered by Flutter Quill)
- Pin important notes to keep them at the top
- Notes are sorted by last-updated time
- Confirmation prompt before deleting any note

### Daily Planner
- **Interactive calendar** — switch between week and month views
- Add tasks for **today or any future date** — past dates are blocked
- Set an **optional time** for each task
- Three **priority levels**: Low (green), Medium (orange), High (red) — each with a distinct colour-coded card
- Enable a **local notification reminder** for tasks that have a time set
- Tasks are sorted by time, with completed tasks moved to the bottom
- Tap anywhere on a task card to **mark as done / incomplete** (confirmation dialog required)
- Tasks from **past days are locked** — they cannot be marked as done or incomplete
- The **+ Add Task button is hidden** on past dates
- Delete individual tasks with a confirmation dialog

---

## Tech Stack

| Layer | Library / Tool |
|---|---|
| Framework | [Flutter](https://flutter.dev) (Dart SDK ≥ 3.5) |
| State Management | [flutter_riverpod 2.x](https://riverpod.dev) |
| Local Database | [sqflite](https://pub.dev/packages/sqflite) |
| Rich Text Editor | [flutter_quill](https://pub.dev/packages/flutter_quill) |
| Notifications | [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) |
| Calendar UI | [table_calendar](https://pub.dev/packages/table_calendar) |
| Timezones | [timezone](https://pub.dev/packages/timezone) |
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
│   ├── notes/
│   │   ├── models/            # Note data model
│   │   ├── providers/         # Notes Riverpod providers & notifier
│   │   ├── screens/           # Notes list screen, Note editor screen
│   │   └── widgets/           # Note card widget
│   └── planner/
│       ├── models/            # Task data model (priority enum, toMap/fromMap)
│       ├── providers/         # Tasks Riverpod providers & notifier
│       ├── screens/           # Planner screen, Task editor screen
│       └── widgets/           # Task tile widget, Priority badge
└── shared/
    ├── services/
    │   ├── db_service.dart            # SQLite singleton (notes + tasks CRUD)
    │   └── notification_service.dart  # Local notification scheduling
    └── widgets/
        └── empty_state.dart           # Reusable empty-state placeholder
```

---

## Database Schema

### `notes`
| Column | Type | Description |
|---|---|---|
| `id` | INTEGER PK | Auto-increment |
| `title` | TEXT | Note title |
| `richContentJson` | TEXT | Quill delta JSON |
| `isPinned` | INTEGER | 0 or 1 |
| `createdAt` | TEXT | ISO 8601 |
| `updatedAt` | TEXT | ISO 8601 |

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

- Tasks can only be created for **today or future dates** — scheduling past dates is not allowed.
- Tasks belonging to **a past date cannot be toggled** done/incomplete.
- The **Add Task FAB** is hidden when a past date is selected on the calendar.
- Saving a task is **guarded against multiple taps** — the Save button disables itself while the operation is in progress.
- Marking a task as done or incomplete requires **explicit confirmation** via a dialog.
- A reminder notification is only scheduled when **both a time and reminder toggle** are set.
