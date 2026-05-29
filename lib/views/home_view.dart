import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/session_manager.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final sm = context.watch<SessionManager>();
    final todaySessions = sm.sessions
        .where((s) => _isToday(s.startTime))
        .toList();
    final todayTotal = todaySessions.fold(0, (sum, s) => sum + s.duration);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Scroll Session',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  if (sm.isSessionActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Active',
                          style: TextStyle(color: Colors.green, fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  if (sm.isPaused)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Paused',
                          style: TextStyle(color: Colors.orange, fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // Timer circle
              Center(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.blue.withOpacity(0.1),
                        Colors.purple.withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        sm.formatTime(sm.sessionTime),
                        style: const TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text('Time Scrolled',
                          style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Break reminder info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.notifications, color: Colors.orange, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Break reminder every ${sm.breakReminderInterval} min',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
              if (!sm.isSessionActive && !sm.isPaused)
                _bigButton(
                  label: 'Start Session',
                  icon: Icons.play_arrow,
                  color: Colors.green,
                  onTap: sm.startSession,
                )
              else
                Row(
                  children: [
                    if (sm.isSessionActive)
                      Expanded(
                        child: _bigButton(
                          label: 'Pause',
                          icon: Icons.pause,
                          color: Colors.orange,
                          onTap: sm.pauseSession,
                        ),
                      ),
                    if (sm.isPaused)
                      Expanded(
                        child: _bigButton(
                          label: 'Resume',
                          icon: Icons.play_arrow,
                          color: Colors.green,
                          onTap: sm.resumeSession,
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _bigButton(
                        label: 'End',
                        icon: Icons.stop,
                        color: Colors.red,
                        onTap: sm.endSession,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 28),

              // Settings
              const Text('Settings',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Break Reminder Interval',
                          style: TextStyle(fontSize: 14)),
                    ),
                    DropdownButton<int>(
                      value: sm.breakReminderInterval,
                      underline: const SizedBox(),
                      items: [5, 10, 15, 20, 30]
                          .map((v) => DropdownMenuItem(
                              value: v, child: Text('$v min')))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) sm.setBreakInterval(v);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Today's stats
              const Text("Today's Stats",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Sessions',
                      value: '${todaySessions.length}',
                      icon: Icons.layers,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Total Time',
                      value: _formatTotalTime(todayTotal),
                      icon: Icons.access_time_filled,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bigButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white),
      label: Text(label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  String _formatTotalTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blue, size: 26),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
