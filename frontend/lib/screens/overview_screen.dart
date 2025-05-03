import 'package:flutter/material.dart';
import 'package:frontend/utils/global_utils.dart';
import 'package:frontend/utils/web_utils.dart';
import 'package:frontend/models/ddl_item.dart';
import 'dart:core';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  final List<Map<String, dynamic>> _taskData = [];
  late WebUtils webUtils;

  // 任务状态统计
  int completedCount = 0;
  int uncompletedCount = 0;
  int overdueCount = 0;

  // 时间段统计
  final Map<String, int> timeSlots = {
    '凌晨': 0,
    '早晨': 0,
    '上午': 0,
    '中午': 0,
    '下午': 0,
    '夜晚': 0,
    '深夜': 0,
  };

  @override
  void initState() {
    super.initState();
    webUtils = WebUtils();
    _initializeConnection();
  }

  void _initializeConnection() async {
    try {
      final response = await webUtils.isWebAvailable();
      if (response) {
        final ddlItems = await webUtils.getAllDDLs();
        _updateTaskData(ddlItems);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('无法连接到服务器: $e')));
      }
    }
  }

  void _updateTaskData(List<DDLItem> items) {
    setState(() {
      _taskData.clear();
      completedCount = 0;
      uncompletedCount = 0;
      overdueCount = 0;
      timeSlots.updateAll((_, __) => 0);

      for (var item in items) {
        final now = DateTime.now();
        final startTime = GlobalUtils.safeParseDateTime(item.startTime);
        final endTime = GlobalUtils.safeParseDateTime(item.endTime);
        final progress =
            endTime.difference(now).inSeconds /
            endTime.difference(startTime).inSeconds;

        final task = {
          'title': item.name,
          'note': item.note,
          'endTime': item.endTime,
          'progress': progress,
        };
        _taskData.add(task);
        _countTaskStatus(task);
        _countTimeSlot(task['endTime'] as String);
      }
    });
  }

  void _countTaskStatus(Map<String, dynamic> task) {
    final endTime = DateTime.parse(task['endTime']);
    final now = DateTime.now();

    if (task['progress'] >= 1.0) {
      completedCount++;
    } else if (endTime.isBefore(now)) {
      overdueCount++;
    } else {
      uncompletedCount++;
    }
  }

  void _countTimeSlot(String timeString) {
    final time = DateTime.parse(timeString);
    final hour = time.hour;

    String slot = '凌晨';
    if (hour >= 6 && hour < 9) {
      slot = '早晨';
    } else if (hour >= 9 && hour < 12) {
      slot = '上午';
    } else if (hour >= 12 && hour < 14) {
      slot = '中午';
    } else if (hour >= 14 && hour < 18) {
      slot = '下午';
    } else if (hour >= 18 && hour < 21) {
      slot = '夜晚';
    } else if (hour >= 21) {
      slot = '深夜';
    }

    timeSlots[slot] = timeSlots[slot]! + 1;
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTaskStatusCard(),
              const SizedBox(width: 40),
              _buildTimeSlotCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskStatusCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusItem('已完成', completedCount, Colors.green),
                _buildStatusItem('未完成', uncompletedCount, Colors.orange),
                _buildStatusItem('已逾期', overdueCount, Colors.red),
              ],
            ),
            const SizedBox(width: 100),
            _buildCustomPieChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomPieChart() {
    final total = completedCount + uncompletedCount + overdueCount;
    return SizedBox(
      width: 150,
      height: 150,
      child: CustomPaint(
        painter: _PieChartPainter(
          completed: total == 0 ? 0 : completedCount / total,
          uncompleted: total == 0 ? 0 : uncompletedCount / total,
          overdue: total == 0 ? 0 : overdueCount / total,
        ),
      ),
    );
  }

  Widget _buildTimeSlotCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '任务完成时间段统计',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 100),
            _buildTimeSlotBars(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotBars() {
    final maxCount = timeSlots.values.fold(0, (a, b) => a > b ? a : b);
    return SizedBox(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children:
            timeSlots.entries.map((entry) {
              return _buildTimeBar(
                label: entry.key,
                value: entry.value,
                height: maxCount > 0 ? (entry.value / maxCount) * 150 : 0,
                color: _getTimeSlotColor(entry.key),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildTimeBar({
    required String label,
    required int value,
    required double height,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          child: Center(
            child: Text(
              '$value',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildStatusItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getTimeSlotColor(String timeSlot) {
    const colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.teal,
      Colors.amber,
    ];
    return colors[timeSlots.keys.toList().indexOf(timeSlot)];
  }
}

class _PieChartPainter extends CustomPainter {
  final double completed;
  final double uncompleted;
  final double overdue;

  _PieChartPainter({
    required this.completed,
    required this.uncompleted,
    required this.overdue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final center = Offset(radius, radius);
    var startAngle = -90.0 * (3.14 / 180);

    _drawArc(canvas, center, radius, startAngle, completed, Colors.green);
    startAngle += completed * 2 * 3.14;
    _drawArc(canvas, center, radius, startAngle, uncompleted, Colors.orange);
    startAngle += uncompleted * 2 * 3.14;
    _drawArc(canvas, center, radius, startAngle, overdue, Colors.red);
  }

  void _drawArc(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double sweep,
    Color color,
  ) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweep,
      true,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
