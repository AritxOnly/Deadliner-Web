import 'package:flutter/material.dart';
import 'package:frontend/models/deadline_type.dart';
import 'package:frontend/models/ddl_item.dart';
import 'package:frontend/models/habit_metadata.dart';
import 'package:frontend/models/deadline_frequency.dart';
import 'package:frontend/utils/web_utils.dart';
import 'package:frontend/utils/global_utils.dart';
import 'dart:convert';

class HabitScreen extends StatefulWidget {
  const HabitScreen({super.key});

  @override
  State<HabitScreen> createState() => _HabitScreenState();
}

class _HabitScreenState extends State<HabitScreen> {
  final List<Map<String, dynamic>> _habitData = [];
  late WebUtils webUtils;

  @override
  void initState() {
    super.initState();
    webUtils = WebUtils();
    _initializeConnection();
  }

  Future<void> _initializeConnection() async {
    try {
      final response = await webUtils.isWebAvailable();
      if (response) {
        final ddlItems = await webUtils.getAllDDLs();
        setState(() {
          _habitData.clear();

          for (var item in ddlItems) {
            if (item.type == DeadlineType.HABIT && !item.isArchived) {
              // 解析元数据
              HabitMetaData? metadata;
              try {
                if (item.note.isNotEmpty) {
                  final metadataJson = jsonDecode(item.note);
                  metadata = HabitMetaData(
                    completedDates: Set<String>.from(
                      metadataJson['completedDates'] ?? [],
                    ),
                    frequencyType: DeadlineFrequency.values.firstWhere(
                      (e) => e.toString() == metadataJson['frequencyType'],
                      orElse: () => DeadlineFrequency.DAILY,
                    ),
                    frequency: metadataJson['frequency'] ?? 1,
                    total: metadataJson['total'] ?? 30,
                    refreshDate: metadataJson['refreshDate'] ?? '',
                  );
                }
              } catch (e) {
                // 如果解析失败，使用默认值
                metadata = HabitMetaData(
                  completedDates: <String>{},
                  frequencyType: DeadlineFrequency.DAILY,
                  frequency: 1,
                  total: 30,
                  refreshDate: DateTime.now().toIso8601String().split('T')[0],
                );
              }

              if (metadata != null) {
                _habitData.add({
                  'id': item.id,
                  'title': item.name,
                  'startTime': item.startTime,
                  'endTime': item.endTime,
                  'metadata': metadata,
                });
              }
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('无法连接到服务器: $e')));
      }
    }
  }

  Future<void> _handleCheck(int index) async {
    try {
      final habitId = _habitData[index]['id'];
      final metadata = _habitData[index]['metadata'] as HabitMetaData;
      final today = DateTime.now().toIso8601String().split('T')[0];

      // 创建新的完成日期集合
      final newCompletedDates = Set<String>.from(metadata.completedDates);

      if (newCompletedDates.contains(today)) {
        // 如果今天已经完成，则取消完成
        newCompletedDates.remove(today);
      } else {
        // 如果今天未完成，则标记为完成
        newCompletedDates.add(today);
      }

      // 创建新的元数据
      final newMetadata = HabitMetaData(
        completedDates: newCompletedDates,
        frequencyType: metadata.frequencyType,
        frequency: metadata.frequency,
        total: metadata.total,
        refreshDate: metadata.refreshDate,
      );

      // 序列化元数据
      final metadataJson = jsonEncode({
        'completedDates': newCompletedDates.toList(),
        'frequencyType': newMetadata.frequencyType.toString(),
        'frequency': newMetadata.frequency,
        'total': newMetadata.total,
        'refreshDate': newMetadata.refreshDate,
      });

      // 更新后端
      final success = await webUtils.updateDDL(habitId, {'note': metadataJson});

      if (success) {
        setState(() {
          _habitData[index]['metadata'] = newMetadata;
        });
      } else {
        throw Exception('更新习惯失败');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('更新习惯失败: $e')));
      }
    }
  }

  Future<void> addHabit(
    String title,
    String startTimeText,
    String endTimeText,
    DeadlineFrequency frequencyType,
    int frequency,
    int total,
  ) async {
    try {
      // 创建初始元数据
      final metadata = HabitMetaData(
        completedDates: <String>{},
        frequencyType: frequencyType,
        frequency: frequency,
        total: total,
        refreshDate: DateTime.now().toIso8601String().split('T')[0],
      );

      // 序列化元数据
      final metadataJson = jsonEncode({
        'completedDates': metadata.completedDates.toList(),
        'frequencyType': metadata.frequencyType.toString(),
        'frequency': metadata.frequency,
        'total': metadata.total,
        'refreshDate': metadata.refreshDate,
      });

      // 创建新习惯
      final id = await webUtils.createDDL(
        title,
        startTimeText,
        endTimeText,
        metadataJson,
        DeadlineType.HABIT,
      );

      // 更新UI
      setState(() {
        _habitData.add({
          'id': id,
          'title': title,
          'startTime': startTimeText,
          'endTime': endTimeText,
          'metadata': metadata,
        });
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('创建习惯失败: $e')));
      }
    }
  }

  Future<void> deleteHabit(int index) async {
    try {
      final habitId = _habitData[index]['id'];
      if (habitId == null) {
        throw Exception('习惯ID不存在');
      }

      final success = await webUtils.deleteDDL(habitId);

      if (success) {
        setState(() {
          _habitData.removeAt(index);
        });
      } else {
        throw Exception('删除习惯失败');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('删除习惯失败: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount =
        screenWidth >= 1200
            ? 3
            : screenWidth >= 800
            ? 2
            : 1;

    return Expanded(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.5,
              ),
              itemCount: _habitData.length,
              itemBuilder: (context, index) {
                final habit = _habitData[index];
                final metadata = habit['metadata'] as HabitMetaData;
                return HabitItem(
                  title: habit['title'],
                  metadata: metadata,
                  onCheckPressed: () => _handleCheck(index),
                  onTap: () {
                    _showHabitEditDialog(
                      context,
                      index,
                      habit['title'],
                      metadata,
                    );
                  },
                );
              },
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: () {
                _showHabitAddDialog(context);
              },
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }

  void _showHabitAddDialog(BuildContext context) {
    // 这里可以添加创建习惯的对话框
    // 暂时使用简单的示例
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('添加习惯'),
            content: const Text('习惯添加功能待实现'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('确定'),
              ),
            ],
          ),
    );
  }

  void _showHabitEditDialog(
    BuildContext context,
    int index,
    String title,
    HabitMetaData metadata,
  ) {
    // 这里可以添加编辑习惯的对话框
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('编辑习惯: $title'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('频率类型: ${metadata.frequencyType}'),
                Text('频率: ${metadata.frequency}'),
                Text('总计: ${metadata.total}'),
                Text('已完成天数: ${metadata.completedDates.length}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await deleteHabit(index);
                },
                child: const Text('删除', style: TextStyle(color: Colors.red)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('关闭'),
              ),
            ],
          ),
    );
  }
}

class HabitItem extends StatelessWidget {
  final String title;
  final HabitMetaData metadata;
  final VoidCallback onCheckPressed;
  final VoidCallback? onTap;

  const HabitItem({
    super.key,
    required this.title,
    required this.metadata,
    required this.onCheckPressed,
    this.onTap,
  });

  String _getStreakText() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final completedDates = metadata.completedDates.toList()..sort();

    if (completedDates.isEmpty) {
      return '0天连击';
    }

    // 计算连击天数
    int streak = 0;
    final todayDate = DateTime.parse(today);

    for (int i = 0; i <= 30; i++) {
      final checkDate = todayDate.subtract(Duration(days: i));
      final checkDateStr = checkDate.toIso8601String().split('T')[0];

      if (completedDates.contains(checkDateStr)) {
        streak++;
      } else {
        break;
      }
    }

    return '${streak}天连击';
  }

  String _getFrequencyText() {
    final completedCount = metadata.completedDates.length;
    switch (metadata.frequencyType) {
      case DeadlineFrequency.DAILY:
        return '每天${metadata.frequency}次 · 已完成${completedCount}天';
      case DeadlineFrequency.WEEKLY:
        return '每周${metadata.frequency}次 · 已完成${completedCount}次';
      case DeadlineFrequency.MONTHLY:
        return '每月${metadata.frequency}次 · 已完成${completedCount}次';
      case DeadlineFrequency.TOTAL:
        return '共计${metadata.total}次 · 已完成${completedCount}次';
    }
  }

  List<bool> _getDailyChecks() {
    final today = DateTime.now();
    final checks = <bool>[];

    // 显示最近7天的完成情况
    for (int i = 6; i >= 0; i--) {
      final checkDate = today.subtract(Duration(days: i));
      final checkDateStr = checkDate.toIso8601String().split('T')[0];
      checks.add(metadata.completedDates.contains(checkDateStr));
    }

    return checks;
  }

  double _getProgress() {
    if (metadata.frequencyType == DeadlineFrequency.TOTAL) {
      return metadata.completedDates.length / metadata.total;
    }

    // 对于其他类型，基于最近的完成情况计算进度
    final recentDays = 7; // 最近7天
    final today = DateTime.now();
    int recentCompletions = 0;

    for (int i = 0; i < recentDays; i++) {
      final checkDate = today.subtract(Duration(days: i));
      final checkDateStr = checkDate.toIso8601String().split('T')[0];
      if (metadata.completedDates.contains(checkDateStr)) {
        recentCompletions++;
      }
    }

    return recentCompletions / recentDays;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(16),
          height: 120,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderRow(context),
              const SizedBox(height: 4),
              _buildStreakRow(context),
              const SizedBox(height: 4),
              _buildFrequencyRow(context),
              const SizedBox(height: 4),
              _buildDailyDots(context),
              const SizedBox(height: 6),
              _buildMainProgress(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context) {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final isCheckedToday = metadata.completedDates.contains(today);

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: onCheckPressed,
          icon: Icon(Icons.check_circle, size: 16),
          label: Text(
            isCheckedToday ? '今日已打卡' : '打卡',
            style: TextStyle(fontSize: 10),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isCheckedToday
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.primaryContainer,
            foregroundColor:
                isCheckedToday
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onPrimaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildStreakRow(BuildContext context) {
    return Text(
      _getStreakText(),
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    );
  }

  Widget _buildFrequencyRow(BuildContext context) {
    return Text(
      _getFrequencyText(),
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: 12,
      ),
    );
  }

  Widget _buildDailyDots(BuildContext context) {
    final dailyChecks = _getDailyChecks();
    return SizedBox(
      height: 12,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dailyChecks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder:
            (context, index) => Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color:
                    dailyChecks[index]
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      dailyChecks[index]
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                  width: 2,
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildMainProgress(BuildContext context) {
    return LinearProgressIndicator(
      value: _getProgress().clamp(0.0, 1.0),
      minHeight: 4,
      borderRadius: BorderRadius.circular(6),
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
    );
  }
}
