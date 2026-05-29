import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/scroll_session.dart';

class SessionManager extends ChangeNotifier {
  bool isSessionActive = false;
  bool isPaused = false;
  int sessionTime = 0;
  List<ScrollSession> sessions = [];
  int breakReminderInterval = 15; // minutes

  Timer? _timer;
  Timer? _breakTimer;
  DateTime? _sessionStart;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const _sessionsKey = 'scrollGuardian_sessions';

  SessionManager() {
    _initNotifications();
    _loadSessions();
  }

  Future<void> _initNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _notifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  Future<void> _sendBreakReminder() async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'break_reminder',
        'Break Reminders',
        channelDescription: 'Reminders to take a break from scrolling',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _notifications.show(
      0,
      'Time for a Break!',
      'You\'ve been scrolling for $breakReminderInterval minutes. Rest your eyes!',
      details,
    );
  }

  void startSession() {
    if (isSessionActive) return;
    isSessionActive = true;
    isPaused = false;
    sessionTime = 0;
    _sessionStart = DateTime.now();
    _startTimers();
    notifyListeners();
  }

  void pauseSession() {
    if (!isSessionActive) return;
    isSessionActive = false;
    isPaused = true;
    _stopTimers();
    notifyListeners();
  }

  void resumeSession() {
    if (isSessionActive) return;
    isSessionActive = true;
    isPaused = false;
    _startTimers();
    notifyListeners();
  }

  void endSession() {
    if (!isSessionActive && !isPaused) return;
    _stopTimers();

    final session = ScrollSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      duration: sessionTime,
      startTime: _sessionStart ?? DateTime.now().subtract(Duration(seconds: sessionTime)),
      endTime: DateTime.now(),
    );

    sessions.insert(0, session);
    _saveSessions();

    isSessionActive = false;
    isPaused = false;
    sessionTime = 0;
    _sessionStart = null;
    notifyListeners();
  }

  void deleteSession(String id) {
    sessions.removeWhere((s) => s.id == id);
    _saveSessions();
    notifyListeners();
  }

  void setBreakInterval(int minutes) {
    breakReminderInterval = minutes;
    if (isSessionActive) {
      _breakTimer?.cancel();
      _startBreakTimer();
    }
    notifyListeners();
  }

  void _startTimers() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      sessionTime++;
      notifyListeners();
    });
    _startBreakTimer();
  }

  void _startBreakTimer() {
    _breakTimer = Timer.periodic(
      Duration(minutes: breakReminderInterval),
      (_) => _sendBreakReminder(),
    );
  }

  void _stopTimers() {
    _timer?.cancel();
    _breakTimer?.cancel();
  }

  String formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _saveSessions() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_sessionsKey, ScrollSession.listToJson(sessions));
  }

  Future<void> _loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionsKey);
    if (raw != null) {
      sessions = ScrollSession.listFromJson(raw);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _stopTimers();
    super.dispose();
  }
}
