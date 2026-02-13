# flutter_repository

# notify_me

A new Flutter project.

## Getting Started

Notify Me:

A Flutter application that allows users to schedule custom notifications to launch other installed Android apps.

Overview: 

Notify Me is a lightweight and intuitive mobile application that enables users to:
- Select any app installed on their Android device
- Write a custom reminder message
- Schedule a specific date and time for a notification
- When the scheduled time is reached, the system displays a local notification. Tapping the notification automatically launches the selected application.

This project was built as a Minimum Viable Product (MVP) to demonstrate how to integrate precise local notifications in Flutter, including deep linking to external applications.

Features:
- Installed Apps Listing
Displays all installed applications on the device (requires QUERY_ALL_PACKAGES permission).

- Custom Reminders
Define a personalized message and choose the exact time (hour and minute for the notification).

- Exact Alarm Scheduling
Uses SCHEDULE_EXACT_ALARM to ensure notifications are triggered precisely, even under battery optimization policies.

- Daily Recurring Notifications
Automatically repeats notifications every day at the selected time.

- Launch External Apps
Opens the selected application via its package name when the notification is tapped.

- Local Persistence
Reminders are stored using SQLite, allowing future management and scalability.

Architecture Highlights
This project demonstrates:
- Time zone–aware notification scheduling
- Exact alarms integration on Android
- Local database persistence with SQLite
- Interaction with installed apps via package names
- Clean and simple MVP architecture

Tech Stack:
- Flutter
- Dart
- SQLite

Permissions:
The app requires the following Android permissions:
- QUERY_ALL_PACKAGES — to list installed applications
- SCHEDULE_EXACT_ALARM — to trigger precise scheduled notifications
Make sure to grant these permissions when prompted.

