# LifeTracker — Setup Guide

## Prerequisites
- Flutter SDK (3.19+): https://flutter.dev/docs/get-started/install
- Android Studio or VS Code with Flutter extension
- Android device (Samsung S23 FE) with USB debugging enabled

---

## Quick Start

### 1. Create the Flutter project scaffold

```bash
# Navigate to where you want the project
cd ~/projects

# Create a fresh Flutter project with the correct package name
flutter create --org com.lifetracker --project-name life_tracker life_tracker_tmp

# Copy the generated boilerplate files into this folder
cp -r life_tracker_tmp/android/app/src/main/res/mipmap-* life_tracker/android/app/src/main/res/
cp -r life_tracker_tmp/android/app/src/main/res/values/styles.xml life_tracker/android/app/src/main/res/values/ 2>/dev/null || true
cp    life_tracker_tmp/android/app/src/main/res/values/themes.xml  life_tracker/android/app/src/main/res/values/ 2>/dev/null || true
cp    life_tracker_tmp/android/local.properties                     life_tracker/android/ 2>/dev/null || true
rm -rf life_tracker_tmp
```

### 2. Install dependencies

```bash
cd life_tracker
flutter pub get
```

### 3. Run on device

```bash
flutter run
```

---

## First Launch Permissions

When the app first opens it will prompt for two permissions:

| Permission | Why |
|---|---|
| **All Files Access** (MANAGE_EXTERNAL_STORAGE) | Stores data at `/storage/emulated/0/LifeTracker/` so it survives reinstall |
| **Notifications** | For plan reminders |

If you miss them, go to **Settings → Permissions** inside the app.

On Samsung One UI: *Settings → Apps → LifeTracker → Permissions → Files and media → Allow access to all files*

---

## Data Storage

| Scenario | Storage location |
|---|---|
| Permission granted | `/storage/emulated/0/LifeTracker/` (public — survives reinstall) |
| Permission denied | `/sdcard/Android/data/com.lifetracker.app/files/LifeTracker/` (semi-persistent) |

All photos are copied into `LifeTracker/photos/` so you can also browse them in your gallery.

---

## Home Screen Widget

1. Long-press your home screen
2. Tap **Widgets**
3. Search for **LifeTracker**
4. Drag the widget (4×2) to your home screen

The widget shows your **next upcoming plan** with date and category.  
Tap it to open the app.  
The widget auto-refreshes every 30 min; force-refresh via **Settings → Refresh widgets**.

---

## Calendar

The **Calendar tab** (bottom nav) shows every entry that has a date on the calendar grid:

- **Blue dot** = Past Event on that day
- **Green dot** = Future Plan on that day
- **Orange dot** = Note on that day
- Tap any day → see all entries for that day listed below
- Tap **+ Past / + Plan / + Note** chips next to the day header to add directly for that date (date is pre-filled)
- A green strip at the top shows how many upcoming plans exist total
- Tap any card to open the detail/edit view

Future plans are automatically synced to the calendar — whenever you add or edit a plan with a date, it appears on the calendar immediately.

---

## App Features

### Three entry types
| Type | Use for |
|---|---|
| **Past Event** | Record workouts, meals, things you did |
| **Plan** | Future goals, appointments, to-dos with optional reminder |
| **Note** | Quick thoughts, lists, anything |

### Per entry
- Title + detailed notes
- Category (Fitness, Health, Nutrition, Work, Personal…)
- Date/time picker
- Notification reminder (Plans only)
- Multiple photos (camera or gallery)

### Home screen
- Tab bar: All / Past / Plans / Notes
- Search bar filters all fields
- Swipe card left → delete
- Plans tab shows overdue/upcoming/done summary
- FAB with quick-add buttons for each type

---

## Build Release APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
# Transfer to phone and install
```

---

## Troubleshooting

**Widget not updating?**
Go to Settings → Refresh Widgets inside the app.

**Notification not firing?**
On Samsung One UI, also enable: *Settings → Apps → LifeTracker → Battery → Unrestricted*

**Photos not showing?**
Check that the path in the entry still exists — if you moved the LifeTracker folder, update the path.

**Data after reinstall?**
Only works if "All Files Access" was granted and data is in `/storage/emulated/0/LifeTracker/`.
Re-install the app → open Settings → Grant permission → the data file is already there.
