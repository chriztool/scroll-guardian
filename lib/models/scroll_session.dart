import 'dart:convert';

class ScrollSession {
  final String id;
  final int duration; // seconds
  final DateTime startTime;
  final DateTime endTime;

  ScrollSession({
    required this.id,
    required this.duration,
    required this.startTime,
    required this.endTime,
  });

  String get formattedDuration {
    final m = duration ~/ 60;
    final s = duration % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String get formattedDate {
    final d = startTime;
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour < 12 ? 'AM' : 'PM';
    final min = d.minute.toString().padLeft(2, '0');
    return '${months[d.month - 1]} ${d.day}, ${d.year} $hour:$min $ampm';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'duration': duration,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
  };

  factory ScrollSession.fromJson(Map<String, dynamic> json) => ScrollSession(
    id: json['id'],
    duration: json['duration'],
    startTime: DateTime.parse(json['startTime']),
    endTime: DateTime.parse(json['endTime']),
  );

  static List<ScrollSession> listFromJson(String raw) {
    final list = jsonDecode(raw) as List;
    return list.map((e) => ScrollSession.fromJson(e)).toList();
  }

  static String listToJson(List<ScrollSession> sessions) =>
      jsonEncode(sessions.map((s) => s.toJson()).toList());
}
