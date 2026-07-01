
A fully-featured Flutter task management app built with Clean Architecture and BLoC state management. Manage your daily tasks, track progress with charts, filter and search, and switch between light and dark themes — all persisted locally with SQLite.

---

## Screenshots

<img width="327" height="720" alt="screenshot_2026-07-01-11-16-08-71_cabb84fae1194660d798c41c10701979_720" src="https://github.com/user-attachments/assets/1b98e4a3-ed7a-495c-a152-8cc938880da5" />
<img width="327" height="720" alt="screenshot_2026-07-01-11-16-13-71_cabb84fae1194660d798c41c10701979_720" src="https://github.com/user-attachments/assets/7771ee0b-bd5a-4893-81f8-ee5003078638" />
<img width="327" height="720" alt="screenshot_2026-07-01-11-16-15-97_cabb84fae1194660d798c41c10701979_720" src="https://github.com/user-attachments/assets/1945b898-ead6-43ad-942c-c7bf66af3706" />
<img width="327" height="720" alt="screenshot_2026-07-01-11-16-23-14_cabb84fae1194660d798c41c10701979_720" src="https://github.com/user-attachments/assets/c694cbb4-538f-44a9-8c36-45fa54753f10" />

---

## Features

### Splash Screen
- Animated 3-second intro with navy-purple gradient background
- App icon with spring-bounce entrance and rotating glow ring
- Feature tiles (Manage Tasks · Track Progress · Reminders & Notifications)
- Animated progress bar counting to 85% before transitioning to the app

### Home (Dashboard)
- Personalized greeting (morning / afternoon / evening)
- Circular progress ring showing today's task completion
- Stat chips for Total, Pending, and Overdue counts — tap any chip to jump to the Tasks tab with filters pre-applied
- "Due Today" and grouped "Upcoming" task sections
- Theme toggle button in the header

### Tasks
- Full task list with debounced live search (350 ms)
- Filter chips: All / Pending / Done + per-category filters
- Drag-and-drop reordering (disabled when filters are active)
- Swipe-to-delete with a **5-second undo** snackbar
- Filters are persisted across sessions

### Add / Edit Task
- Title (required), description, category picker
- Due date and reminder date/time pickers
- Slides up from the bottom with a smooth transition

### Stats
- Overall completion ring (Completed / Pending / Overdue)
- Weekly bar chart — tasks completed per day for the last 7 days
- Category breakdown pie chart with percentages

### Settings
- Theme mode selector: System / Light / Dark
- Preference saved instantly and applied without restart

---

## Architecture

The project follows **Clean Architecture** with a strict three-layer separation:

```
lib/
├── core/               # DI, routing, services, theme, utilities
├── data/               # Models, local data sources, repository implementations
├── domain/             # Entities, repository interfaces, use cases
└── presentation/       # Pages, BLoC/Cubits, reusable widgets
```

- **Domain layer** is pure Dart — zero Flutter or persistence imports
- **Data layer** converts `TaskModel` (DB rows) ↔ `Task` (domain entity)
- **Presentation layer** talks only to use cases via the BLoC, never directly to repositories
- **Dependency injection** is handled by a manual service locator (`AppDependencies`) — no external DI package needed

---

## State Management

### `TaskBloc`
Central state machine for all task operations.

| Events | Description |
|---|---|
| `TasksLoaded` | Initial load from SQLite |
| `TaskAdded` / `TaskUpdated` | Create or edit a task |
| `TaskCompletionToggled` | Mark done / undone |
| `TaskSoftDeleted` / `TaskDeleteUndone` / `TaskDeleteCommitted` | Soft-delete with 5-second undo |
| `TasksReordered` | Drag-and-drop reorder, persisted atomically |
| `FilterCategoryChanged` / `FilterStatusChanged` / `FilterDueDateChanged` | Filter changes, persisted immediately |
| `SearchQueryChanged` / `FiltersCleared` | Search and reset |

### `ThemeCubit`
Manages `ThemeMode` (light / dark / system). Seeded before `runApp()` to prevent any white-flash on cold start.

---

## Tech Stack & Packages

| Package | Version | Purpose |
|---|---|---|
| `flutter_bloc` | ^8.1.3 | BLoC + Cubit state management |
| `equatable` | ^2.0.5 | Value equality for states and entities |
| `sqflite` | ^2.3.0 | SQLite local database for tasks |
| `path` | ^1.8.3 | File path utilities for SQLite |
| `shared_preferences` | ^2.2.3 | Key-value storage for theme and filter settings |
| `fl_chart` | ^0.68.0 | Bar chart and pie chart on the Stats screen |
| `intl` | ^0.19.0 | Date formatting |
| `cupertino_icons` | ^1.0.6 | iOS-style icons |

**Dev dependencies:**

| Package | Version | Purpose |
|---|---|---|
| `flutter_lints` | ^3.0.0 | Recommended lint rules |
| `bloc_test` | ^9.1.5 | BLoC unit testing helpers |
| `mocktail` | ^1.0.3 | Mock objects for repository tests |

---

## Data Layer

**Database:** SQLite via `sqflite` — single table `tasks` in `task_manager_pro.db`

| Column | Type | Notes |
|---|---|---|
| `id` | TEXT (PK) | UUID |
| `title` | TEXT | Required |
| `description` | TEXT | Optional |
| `category` | TEXT | work / personal / urgent / shopping / other |
| `isCompleted` | INTEGER | 0 or 1 |
| `dueDate` | INTEGER | Epoch ms, nullable |
| `reminderTime` | INTEGER | Epoch ms, nullable |
| `createdAt` | INTEGER | Epoch ms |
| `updatedAt` | INTEGER | Epoch ms |
| `sortOrder` | INTEGER | Indexed, used for drag-and-drop order |

**Settings** stored in `SharedPreferences`:
- `settings.themeMode` — `"light"` / `"dark"` / `"system"`
- `settings.filter.*` — active category, status, due-date filter, and search query

---

## Domain Layer

**Entities:**
- `Task` — immutable, `Equatable`, holds all task fields including `sortOrder`
- `TaskCategory` — enum: `work`, `personal`, `urgent`, `shopping`, `other` (each has label, icon, color)
- `TaskFilter` — immutable filter: category, `StatusFilter`, `DueDateFilter`, search query
- `StatusFilter` — `all` / `pending` / `done`
- `DueDateFilter` — `any` / `today` / `upcoming` / `overdue`

**Use Cases** (single-responsibility callable classes):
`GetTasks` · `AddTask` · `UpdateTask` · `DeleteTask` · `ReorderTasks` · `ToggleTaskCompletion`

---

## Reusable Widgets

| Widget | Description |
|---|---|
| `TaskTile` | Dismissible tile with animated checkbox, category chip, due date chip, reminder icon, drag handle |
| `ProgressRing` | Animated `CustomPainter` circular ring, tweens value over 900 ms |
| `AnimatedFab` | Expandable FAB — rotates `+` → `×`, sub-actions stagger in with haptic feedback |
| `AppCard` | Themed surface card with 18px rounded corners |
| `EmptyState` | Centered icon + message + optional action button |
| `UndoCountdownSnackbar` | Animated countdown ring + UNDO button |

---

## Project Structure

```
lib/
├── core/
│   ├── di/                  # AppDependencies service locator
│   ├── router/              # Custom page transitions (slideUp, fadeScale)
│   ├── services/            # NotificationService
│   ├── theme/               # AppTheme (Material 3, light + dark)
│   └── utils/               # AppDateUtils, formatting helpers
│
├── data/
│   ├── datasources/         # DatabaseHelper, TaskLocalDataSource
│   ├── models/              # TaskModel (DB ↔ entity mapper)
│   └── repositories/        # TaskRepositoryImpl, SettingsRepositoryImpl
│
├── domain/
│   ├── entities/            # Task, TaskCategory, TaskFilter, enums
│   ├── repositories/        # Abstract interfaces
│   └── usecases/            # GetTasks, AddTask, UpdateTask, …
│
└── presentation/
    ├── bloc/
    │   ├── task/            # TaskBloc, TaskEvent, TaskState
    │   └── theme/           # ThemeCubit
    ├── pages/               # SplashPage, HomePage, TasksPage, AddEditTaskPage,
    │                        # StatsPage, SettingsPage, RootShell
    └── widgets/             # TaskTile, ProgressRing, AnimatedFab, AppCard, …
```

---

## Getting Started

### Prerequisites
- Flutter `>=3.19.0` with Dart `>=3.3.0`
- Android Studio / VS Code with the Flutter plugin

### Run locally

```bash
# Clone the repo
git clone https://github.com/your-username/todolisttask.git
cd todolisttask

# Install dependencies
flutter pub get

# Run on a connected device or emulator
flutter run
```

### Build release APK

```bash
flutter build apk --release
```

---

## Notes

- **Reminders** — The reminder time is stored with every task. OS-level scheduling is currently a no-op because `flutter_local_notifications` v17+ requires Flutter 3.22+. To enable real notifications, upgrade Flutter and restore the notification service implementation.
- **No internet required** — everything runs fully offline using local SQLite storage.

---

## License

This project is for personal / educational use.
