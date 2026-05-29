import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/session_manager.dart';
import '../models/scroll_session.dart';

enum Timeframe { today, week, month }

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  Timeframe _timeframe = Timeframe.week;

  @override
  Widget build(BuildContext context) {
    final sm = context.watch<SessionManager>();
    final filtered = _filteredSessions(sm.sessions);
    final totalTime = filtered.fold(0, (s, e) => s + e.duration);
    final count = filtered.length;
    final avg = count > 0 ? totalTime ~/ count : 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeframe picker
            SegmentedButton<Timeframe>(
              segments: const [
                ButtonSegment(value: Timeframe.today, label: Text('Today')),
                ButtonSegment(value: Timeframe.week, label: Text('Week')),
                ButtonSegment(value: Timeframe.month, label: Text('Month')),
              ],
              selected: {_timeframe},
              onSelectionChanged: (s) => setState(() => _timeframe = s.first),
            ),
            const SizedBox(height: 20),

            // Metric cards
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Total Time',
                    value: _fmt(totalTime),
                    icon: Icons.access_time_filled,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'Sessions',
                    value: '$count',
                    icon: Icons.layers,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _MetricCard(
              title: 'Average Duration',
              value: _fmt(avg),
              icon: Icons.bar_chart,
              color: Colors.orange,
            ),
            const SizedBox(height: 24),

            // Bar chart
            if (filtered.isNotEmpty) ...[
              const Text('Daily Breakdown',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _DailyChart(sessions: filtered),
              const SizedBox(height: 24),
            ],

            // Insights
            const Text('Session Insights',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _InsightRow(
                    icon: Icons.track_changes,
                    label: 'Longest Session',
                    value: filtered.isEmpty
                        ? 'N/A'
                        : filtered
                            .reduce((a, b) => a.duration > b.duration ? a : b)
                            .formattedDuration,
                    color: Colors.red,
                  ),
                  const Divider(height: 20),
                  _InsightRow(
                    icon: Icons.bolt,
                    label: 'Busiest Day',
                    value: _busiestDay(filtered),
                    color: Colors.orange,
                  ),
                  const Divider(height: 20),
                  _InsightRow(
                    icon: Icons.check_circle,
                    label: 'Most Active Time',
                    value: _mostActiveTime(filtered),
                    color: Colors.green,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tips
            const Text('Tips for Better Habits',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            const _TipCard(
              icon: Icons.notifications_active,
              title: 'Enable Break Reminders',
              description: 'Set reminders every 15 minutes to take eye breaks',
            ),
            const SizedBox(height: 10),
            const _TipCard(
              icon: Icons.nightlight_round,
              title: 'Set Time Limits',
              description: 'Try to keep sessions under 30 minutes',
            ),
            const SizedBox(height: 10),
            const _TipCard(
              icon: Icons.favorite,
              title: 'Track Progress',
              description: 'Review your reports weekly to see improvements',
            ),
          ],
        ),
      ),
    );
  }

  List<ScrollSession> _filteredSessions(List<ScrollSession> all) {
    final now = DateTime.now();
    return all.where((s) {
      switch (_timeframe) {
        case Timeframe.today:
          return s.startTime.year == now.year &&
              s.startTime.month == now.month &&
              s.startTime.day == now.day;
        case Timeframe.week:
          return s.startTime.isAfter(now.subtract(const Duration(days: 7)));
        case Timeframe.month:
          return s.startTime.isAfter(now.subtract(const Duration(days: 30)));
      }
    }).toList();
  }

  String _fmt(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m';
    return '0m';
  }

  String _busiestDay(List<ScrollSession> sessions) {
    if (sessions.isEmpty) return 'N/A';
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final counts = <int, int>{};
    for (final s in sessions) {
      final d = s.startTime.weekday - 1;
      counts[d] = (counts[d] ?? 0) + 1;
    }
    final best = counts.entries.reduce((a, b) => a.value > b.value ? a : b);
    return days[best.key];
  }

  String _mostActiveTime(List<ScrollSession> sessions) {
    if (sessions.isEmpty) return 'N/A';
    final counts = <int, int>{};
    for (final s in sessions) {
      final h = s.startTime.hour;
      counts[h] = (counts[h] ?? 0) + 1;
    }
    final best = counts.entries.reduce((a, b) => a.value > b.value ? a : b);
    final h = best.key;
    final ampm = h < 12 ? 'AM' : 'PM';
    final display = h % 12 == 0 ? 12 : h % 12;
    return '$display:00 $ampm';
  }
}

class _DailyChart extends StatelessWidget {
  final List<ScrollSession> sessions;
  const _DailyChart({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final dailyMinutes = <String, int>{};
    for (final s in sessions) {
      final key =
          '${s.startTime.month}/${s.startTime.day}';
      dailyMinutes[key] = (dailyMinutes[key] ?? 0) + s.duration ~/ 60;
    }

    final sorted = dailyMinutes.entries.toList()
      ..sort((a, b) {
        final ap = a.key.split('/').map(int.parse).toList();
        final bp = b.key.split('/').map(int.parse).toList();
        if (ap[0] != bp[0]) return ap[0].compareTo(bp[0]);
        return ap[1].compareTo(bp[1]);
      });

    final entries = sorted.length > 7
        ? sorted.sublist(sorted.length - 7)
        : sorted;

    final bars = entries
        .asMap()
        .entries
        .map((e) => BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.value.toDouble(),
                  gradient: const LinearGradient(
                    colors: [Colors.blue, Colors.purple],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ))
        .toList();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: BarChart(
        BarChartData(
          barGroups: bars,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= entries.length) return const SizedBox();
                  return Text(entries[i].key,
                      style: const TextStyle(fontSize: 10, color: Colors.grey));
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(title,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InsightRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
            child: Text(label, style: const TextStyle(fontSize: 14))),
        Text(value,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}

class _TipCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _TipCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(description,
                    style:
                        const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
