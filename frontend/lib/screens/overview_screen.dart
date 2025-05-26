import 'package:flutter/material.dart';
import 'package:frontend/utils/global_utils.dart';
import 'package:frontend/utils/web_utils.dart';
import 'package:frontend/models/ddl_item.dart';
import 'package:frontend/models/deadline_type.dart'; // Add this import
import 'dart:core';
import 'package:graphic/graphic.dart' as graphic;

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
        // Filter out archived tasks and habits, similar to TaskScreen
        final filteredItems =
            ddlItems.where((item) => item.type != DeadlineType.HABIT).toList();
        _updateTaskData(filteredItems);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('无法连接到服务器')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('获取任务数据失败: $e')));
      }
    }
  }

  void _updateTaskData(List<DDLItem> items) {
    setState(() {
      _taskData.clear();
      completedCount = 0;
      uncompletedCount = 0;
      overdueCount = 0;
      timeSlots.updateAll((_, __) => 0); // Reset time slots

      final now = DateTime.now();

      for (var item in items) {
        final endTime = GlobalUtils.safeParseDateTime(item.endTime);

        if (item.isCompleted) {
          completedCount++;
          if (item.completeTime.isNotEmpty) {
            _countTimeSlot(item.completeTime);
          }
        } else {
          if (endTime != GlobalUtils.timeNull && endTime.isBefore(now)) {
            overdueCount++;
            _countTimeSlot(item.endTime); // For overdue, use endTime
          } else {
            uncompletedCount++;
            // For uncompleted (and not overdue), we might not count them in time slots
            // or use endTime if a specific behavior is desired.
            // Based on Kotlin, only completed and overdue are counted for time slots.
          }
        }

        // _taskData can be populated if still needed for other UI parts
        // For simplicity, focusing on counts and time slots as per request
        _taskData.add({
          'title': item.name,
          'note': item.note,
          'endTime': item.endTime,
          // 'progress' is no longer calculated or used directly for status
        });
      }
    });
  }

  // _countTaskStatus is removed as its logic is integrated into _updateTaskData

  void _countTimeSlot(String timeString) {
    final time = GlobalUtils.safeParseDateTime(timeString);
    if (time == GlobalUtils.timeNull) return;

    final hour = time.hour;
    String slot;

    if (hour >= 0 && hour < 6) {
      slot = '凌晨';
    } else if (hour < 9) {
      slot = '早晨'; // use the same key as your map
    } else if (hour < 12) {
      slot = '上午';
    } else if (hour < 14) {
      slot = '中午';
    } else if (hour < 18) {
      slot = '下午';
    } else if (hour < 21) {
      slot = '夜晚'; // match your initial key
    } else {
      slot = '深夜';
    }

    timeSlots[slot] = (timeSlots[slot] ?? 0) + 1;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Row(
          // mainAxisSize: MainAxisSize.min, // Allow Row to expand
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(child: _buildTaskStatusCard()),
            const SizedBox(width: 40),
            Expanded(child: _buildTimeSlotCard()),
          ],
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
            _buildCustomPieChart(),
          ],
        ),
      ),
    );
  }

  /// 生成饼图需要的数据
  List<Map<String, dynamic>> _computePieData() {
    // 三种状态总数
    final total = completedCount + uncompletedCount + overdueCount;

    // 如果总数为 0，返回一个表示无数据的占位数据
    if (total == 0) {
      return [
        {'status': '无数据', 'value': 1.0, 'color': Colors.grey[300]!},
      ];
    }

    // 否则计算占比（value 在 0.0～1.0 之间）
    return [
      {'status': '已完成', 'value': completedCount / total, 'color': Colors.green},
      {
        'status': '未完成',
        'value': uncompletedCount / total,
        'color': Colors.orange,
      },
      {'status': '已逾期', 'value': overdueCount / total, 'color': Colors.red},
    ];
  }

  Widget _buildCustomPieChart() {
    final data = _computePieData();
    final total = completedCount + uncompletedCount + overdueCount;

    return SizedBox(
      width: 150,
      height: 150,
      child: graphic.Chart(
        data: data,
        variables: {
          'status': graphic.Variable(
            accessor: (Map map) => map['status'] as String,
          ),
          'value': graphic.Variable(accessor: (Map map) => map['value'] as num),
        },
        transforms: [graphic.Proportion(variable: 'value', as: 'percent')],
        marks: [
          graphic.IntervalMark(
            position: graphic.Varset('percent') / graphic.Varset('status'),
            color: graphic.ColorEncode(
              variable: 'status',
              values: data.map((e) => e['color'] as Color).toList(),
              updaters: {
                'group': {true: (attributes) => attributes..withOpacity(0.5)},
              },
            ),
            modifiers: [graphic.StackModifier()],
            label: graphic.LabelEncode(
              encoder: (tuple) {
                // 当 total 为 0 时，不显示标签
                if (total == 0) {
                  return graphic.Label('');
                }
                return graphic.Label(
                  tuple['status'].toString(),
                  graphic.LabelStyle(textStyle: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
        ],
        coord: graphic.PolarCoord(transposed: true, dimCount: 1),
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
