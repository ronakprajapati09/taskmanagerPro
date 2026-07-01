# Task Manager Pro

A fully offline-first task management app built with Flutter. It demonstrates
clean architecture, BLoC state management, SQLite persistence, polished
animations, and careful edge-case handling.

---

## ✨ Features

### Core
- **Task CRUD** — add, edit, delete and complete tasks, persisted in SQLite.
- **Categories & filtering** — Work, Personal, Urgent, Shopping, Other. Filter
  by category, status (all / pending / done) and due date (today / upcoming /
  overdue). **All active filters persist between sessions.**
- **Drag & drop reordering** — reorder tasks via a drag handle; the new order is
  written to the database immediately (atomic transaction).
- **Offline-first** — the app is 100% functional with no network. All data
  access goes through a Repository, never raw DB calls in widgets.

### UI / UX
- **Bottom navigation bar** with four screens: **Home**, **Tasks**, **Stats**,
  **Settings**.
- **Animated expandable FAB** — a custom `AnimationController`-driven FAB that
  expands into staggered category quick-add buttons, rotates `+ → ×`, dims the
  background, gives haptic feedback, and closes on tap-outside.
- **Swipe-to-delete with undo countdown** — swiping a task shows a snackbar with
  a **visible countdown ring + number**. The row is removed optimistically and
  is only deleted from the database after the 5-second window expires. **Undo
  restores the exact task with all fields at its original position.**
- **Progress ring** — a `CustomPainter` ring on Home animates from 0 to the
  percentage of **today's** tasks completed (safe at 0 tasks).
- **Statistics screen with graphs** — overall completion ring, a **weekly bar
  chart** of tasks completed per day, and a **category breakdown pie chart**
  (powered by `fl_chart`).
- **Dark / Light / System theme** — the saved theme is loaded **before
  `runApp()`**, so the first frame already paints correctly (no white flash on
  cold start). Toggle from Home or pick a mode in Settings; the choice persists.
- **Custom page transitions** — no `MaterialPageRoute`; all routes use custom
  slide-up + fade / fade-scale transitions.

### Bonus
- **Local notifications** — task reminders via `flutter_local_notifications`
  with per-task unique IDs, runtime permission handling, and automatic
  cancellation when a task is completed or deleted.
- **Search with debounce** — 350ms debounced, case-insensitive search across
  title and description; the query persists with the other filters.
- **Repository unit tests** — the data/repository layer is covered with
  `mocktail`-based unit tests (CRUD, reorder, error path, model round-trip).

---

## 🏛 Architecture

The project follows **Clean Architecture** with three layers and a thin core.

```
lib/
├── core/
│   ├── di/                 # Manual service locator (AppDependencies)
│   ├── router/             # Custom page transitions
│   ├── services/           # NotificationService
│   ├── theme/              # Light & dark ThemeData
│   └── utils/              # Date helpers
├── data/
│   ├── datasources/        # SQLite helper + local data source (raw DB here only)
│   ├── models/             # TaskModel (DB <-> entity mapping)
│   └── repositories/       # Repository implementations
├── domain/
│   ├── entities/           # Pure Dart entities (Task, TaskCategory, TaskFilter)
│   ├── repositories/       # Repository interfaces
│   └── usecases/           # Single-action use cases
└── presentation/
    ├── bloc/               # TaskBloc + ThemeCubit
    ├── pages/              # Home, Tasks, Stats, Settings, Add/Edit, RootShell
    └── widgets/            # ProgressRing, AnimatedFab, TaskTile, etc.
```

**Data flow:**

```
Widget → BLoC/Cubit → UseCase → Repository (interface)
                                   → Repository Impl → DataSource → SQLite
```

- Domain entities are **pure Dart** — no persistence or Flutter annotations.
- The data layer owns all mapping (`TaskModel`) and the only raw SQLite calls.
- Widgets never touch the database directly.

### Why BLoC?
BLoC was chosen over Riverpod for **explicit, testable, event-driven state**.
Task operations (add, toggle, reorder, soft-delete, undo, filter changes) map
cleanly to events, and the deferred undo-delete timer lives inside the bloc,
keeping the authoritative state in one place. `setState` is used only for local
form/animation state (text fields, FAB open/close, countdown), never for
business logic.

### Why SQLite (sqflite)?
Tasks are relational records with ordering and queryable fields, so SQLite is a
natural fit and keeps writes off the UI isolate. `SharedPreferences` is used
**only** for small settings (theme + filters), exactly as recommended.

### Edge cases handled
- **100+ tasks** — `ListView.builder` / `ReorderableListView.builder` with
  stable `ValueKey(task.id)` and `const` widgets where possible.
- **Empty / error / loading states** — distinct UI for no tasks, no filter
  matches, no search results, loading, and a retryable error state.
- **0 tasks today** — progress ring renders 0% without dividing by zero.
- **Thread safety** — all DB access is async; reorder uses a single batched
  transaction.
- **Undo correctness** — DB delete is deferred; undo restores the full task at
  its original index.
- **No white flash** — theme is read before the first frame.

---

## 🔀 Trade-offs

- **Manual service locator** instead of `get_it`/`injectable` to keep the
  dependency graph explicit and dependency count low.
- **Reordering is disabled while filters/search are active** — index mapping
  between a filtered view and the full list is ambiguous, so reordering is
  offered only on the unfiltered list (drag handle hidden otherwise).
- **Weekly chart** counts a task as "completed on a day" using its `updatedAt`
  timestamp, a reasonable proxy without adding a separate completion-history
  table.
- **Inexact alarm scheduling** is used for reminders to avoid requiring the
  `SCHEDULE_EXACT_ALARM` permission; reminders fire approximately on time.

---

## 🚀 Setup

Requires Flutter 3.3+ (developed on Flutter 3.41 / Dart 3.11).

```bash
git clone <your-repo-url>
cd todolisttask
flutter pub get
flutter run
```

> On Android, the app targets `minSdk 21` and enables core-library desugaring
> (required by `flutter_local_notifications`). On first launch, open
> **Settings → Enable reminders** to grant notification permission (Android 13+
> / iOS).

### Quality checks

```bash
flutter analyze   # static analysis — no issues
flutter test      # repository + model unit tests
```

---

## 🧪 Manual cold-boot test

1. Create 3 tasks, mark one done.
2. Reorder them and apply a category/status filter.
3. Switch the theme.
4. Fully kill the app and reopen it.
5. Tasks, completion state, order, filters and theme are all restored.

---

## 📦 Key packages

| Package | Purpose |
|---|---|
| `flutter_bloc` / `bloc` | State management |
| `equatable` | Value equality for states/entities |
| `sqflite` + `path` | Local SQLite persistence |
| `shared_preferences` | Theme & filter settings |
| `fl_chart` | Weekly bar chart & category pie chart |
| `flutter_local_notifications` + `timezone` | Task reminders |
| `intl` | Date formatting |
| `mocktail` / `bloc_test` | Unit testing |
