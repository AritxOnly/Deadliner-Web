import 'package:flutter/material.dart';
import 'package:frontend/models/deadline_type.dart';
import 'package:frontend/utils/task_utils.dart';
import 'package:frontend/utils/web_utils.dart';
import 'package:frontend/utils/global_utils.dart';
import 'package:frontend/models/ddl_item.dart';
import 'package:http/http.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final List<Map<String, dynamic>> _taskData = [];
  late WebUtils webUtils;

  void _sortTaskData() {
    _taskData.sort(
      (a, b) => (a['progress'] as double).compareTo(b['progress'] as double),
    );
  }

  void exampleInit() {
    _taskData.addAll([
      {
        'title': '项目原型设计',
        'note': '需完成用户流程设计',
        'startTime': DateTime.now().toIso8601String(),
        'endTime':
            DateTime.now().add(const Duration(days: 3)).toIso8601String(),
        'progress': 0.6,
      },
      {
        'title': '开发文档编写',
        'note': '',
        'startTime': DateTime.now().toIso8601String(),
        'endTime':
            DateTime.now().add(const Duration(hours: 12)).toIso8601String(),
        'progress': 0.2,
      },
    ]);
  }

  @override
  void initState() {
    super.initState();

    webUtils = WebUtils();

    // 启动第二个线程尝试连接API服务器
    Future<void> initializeConnection() async {
      try {
        final response = await webUtils.isWebAvailable();
        if (response) {
          // 连接成功，获取DDL数据
          final ddlItems = await webUtils.getAllDDLs();
          setState(() {
            _taskData.clear(); // 清空现有数据
            final now = DateTime.now();

            for (var item in ddlItems) {
              // 解析开始时间和结束时间
              final startTime = GlobalUtils.safeParseDateTime(item.startTime);
              final endTime = GlobalUtils.safeParseDateTime(item.endTime);

              // 计算进度
              double progress = 0.0;
              if (startTime != GlobalUtils.timeNull &&
                  endTime != GlobalUtils.timeNull) {
                // 如果当前时间在开始时间之前，进度为0
                if (now.isBefore(startTime)) {
                  progress = 0.0;
                }
                // 如果当前时间在结束时间之后，进度为1
                else if (now.isAfter(endTime)) {
                  progress = 1.0;
                }
                // 否则，计算进度比例
                else {
                  final totalDuration =
                      endTime.difference(startTime).inMilliseconds;
                  final elapsedDuration =
                      now.difference(startTime).inMilliseconds;
                  progress =
                      totalDuration > 0 ? elapsedDuration / totalDuration : 0.0;
                  // 确保进度在0-1之间
                  progress = progress.clamp(0.0, 1.0);
                }
              }

              // 剩余时间显示逻辑已移至DDLItemWidget

              if (item.isArchived || item.type == DeadlineType.HABIT) {
                continue; // 跳过已归档或习惯类型的任务
              }

              progress =
                  GlobalUtils.progressDirection ? (1.0 - progress) : progress;

              // 将DDLItem转换为任务数据格式
              _taskData.add({
                'id': item.id, // 保存ID以便后续更新和删除
                'title': item.name,
                'note': item.note,
                'startTime': item.startTime, // Added
                'endTime': item.endTime, // Added
                'progress': progress,
              });
            }
            _sortTaskData(); // Sort after fetching DDLs
          });
        }
      } catch (e) {
        // 连接失败，显示错误信息
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('无法连接到服务器: $e')));
        }
      }
    }

    initializeConnection();
  }

  Future<void> addTask(
    String title,
    String note,
    String startTimeText,
    String endTimeText,
  ) async {
    // MODIFIED
    try {
      // Parse start and end times
      final startDateTime = GlobalUtils.safeParseDateTime(startTimeText);
      final endDateTime = GlobalUtils.safeParseDateTime(endTimeText);
      final now = DateTime.now();

      if (startDateTime != GlobalUtils.timeNull &&
          endDateTime != GlobalUtils.timeNull &&
          startDateTime.isAfter(endDateTime)) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('开始时间不能晚于结束时间')));
        }
        return;
      }

      // Create new DDL item
      final id = await webUtils.createDDL(
        title,
        startTimeText, // MODIFIED
        endTimeText, // MODIFIED
        note,
        DeadlineType.TASK,
      );

      // Calculate progress
      double progress = 0.0;
      if (startDateTime != GlobalUtils.timeNull &&
          endDateTime != GlobalUtils.timeNull) {
        if (now.isBefore(startDateTime)) {
          progress = 0.0;
        } else if (now.isAfter(endDateTime)) {
          progress = 1.0;
        } else {
          final totalDuration =
              endDateTime.difference(startDateTime).inMilliseconds;
          final elapsedDuration = now.difference(startDateTime).inMilliseconds;
          progress = totalDuration > 0 ? elapsedDuration / totalDuration : 0.0;
          progress = progress.clamp(0.0, 1.0);
        }
      } else if (endDateTime != GlobalUtils.timeNull &&
          now.isAfter(endDateTime)) {
        progress = 1.0;
      }

      // Update UI
      setState(() {
        _taskData.add({
          'id': id,
          'title': title,
          'note': note,
          'startTime': startTimeText, // MODIFIED
          'endTime': endTimeText, // MODIFIED
          'progress': progress,
        });
        _sortTaskData();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('创建任务失败: $e')));
      }
    }
  }

  Future<void> updateTask(
    int index,
    String title,
    String note,
    String startTimeText, // MODIFIED
    String endTimeText, // MODIFIED
  ) async {
    try {
      final taskId = _taskData[index]['id'];
      if (taskId == null) throw Exception('任务ID不存在');

      final newStartDateTime = GlobalUtils.safeParseDateTime(startTimeText);
      final newEndDateTime = GlobalUtils.safeParseDateTime(endTimeText);
      final now = DateTime.now();

      if (newStartDateTime != GlobalUtils.timeNull &&
          newEndDateTime != GlobalUtils.timeNull &&
          newStartDateTime.isAfter(newEndDateTime)) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('开始时间不能晚于结束时间')));
        }
        return;
      }

      final Map<String, dynamic> updates = {
        'name': title,
        'note': note,
        'startTime': startTimeText, // MODIFIED - Assuming API supports this
        'endTime': endTimeText, // MODIFIED
      };

      final success = await webUtils.updateDDL(taskId, updates);

      if (success) {
        double progress = 0.0;
        // Use the new start and end times for progress calculation
        if (newStartDateTime != GlobalUtils.timeNull &&
            newEndDateTime != GlobalUtils.timeNull) {
          if (now.isBefore(newStartDateTime)) {
            progress = 0.0;
          } else if (now.isAfter(newEndDateTime)) {
            progress = 1.0;
          } else {
            final totalDuration =
                newEndDateTime.difference(newStartDateTime).inMilliseconds;
            final elapsedDuration =
                now.difference(newStartDateTime).inMilliseconds;
            progress =
                totalDuration > 0 ? elapsedDuration / totalDuration : 0.0;
            progress = progress.clamp(0.0, 1.0);
          }
        } else if (newEndDateTime != GlobalUtils.timeNull &&
            now.isAfter(newEndDateTime)) {
          progress = 1.0;
        } else {
          progress = _taskData[index]['progress']; // Fallback
        }

        setState(() {
          _taskData[index]['title'] = title;
          _taskData[index]['note'] = note;
          _taskData[index]['startTime'] = startTimeText; // MODIFIED
          _taskData[index]['endTime'] = endTimeText; // MODIFIED
          _taskData[index]['progress'] = progress;
          _sortTaskData();
        });
      } else {
        throw Exception('更新任务失败');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('更新任务失败: $e')));
      }
    }
  }

  Future<void> deleteTask(int index) async {
    try {
      // 获取任务ID
      final taskId = _taskData[index]['id'];
      if (taskId == null) {
        throw Exception('任务ID不存在');
      }

      // 调用API删除任务
      final success = await webUtils.deleteDDL(taskId);

      if (success) {
        // 更新UI
        setState(() {
          _taskData.removeAt(index);
        });
      } else {
        throw Exception('删除任务失败');
      }
    } catch (e) {
      // 处理错误
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('删除任务失败: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount;

    if (screenWidth >= 1200) {
      crossAxisCount = 3;
    } else if (screenWidth >= 800) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 1;
    }

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
                childAspectRatio: 3, // 控制任务卡片比例，宽高比为3:1
              ),
              itemCount: _taskData.length,
              itemBuilder: (context, index) {
                final task = _taskData[index];
                return DDLItemWidget(
                  title: task['title'],
                  note: task['note'],
                  startTime: task['startTime'] as String,
                  endTime: task['endTime'] as String,
                  progress: task['progress'],
                  onTap: () {
                    TaskUtils.showEditDialog(
                      context,
                      initialTitle: task['title'],
                      initialNote: task['note'],
                      initialStartTime: task['startTime'] as String, // MODIFIED
                      initialEndTime: task['endTime'] as String, // MODIFIED
                      onConfirm: (
                        newTitle,
                        newNote,
                        newStartTime,
                        newEndTime,
                      ) async {
                        // MODIFIED
                        await updateTask(
                          index,
                          newTitle,
                          newNote,
                          newStartTime,
                          newEndTime,
                        ); // MODIFIED
                      },
                      onDelete: () async {
                        await deleteTask(index);
                      },
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
                TaskUtils.onFABPressed(context, onTaskAdd: addTask);
              },
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}

class DDLItemWidget extends StatelessWidget {
  final String title;
  final String startTime;
  final String endTime;
  final String note;
  final double progress;
  final VoidCallback? onTap;

  const DDLItemWidget({
    super.key,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.note = "",
    required this.progress,
    this.onTap,
  });

  String _getRemainingTimeText() {
    final now = DateTime.now();
    final endDateTime = GlobalUtils.safeParseDateTime(endTime);

    if (endDateTime != GlobalUtils.timeNull) {
      if (now.isAfter(endDateTime)) {
        return '已截止';
      } else {
        final remaining = endDateTime.difference(now);
        final remainingMinutes = remaining.inMinutes;
        final actualRemainingDays = remaining.inMinutes / (60 * 24);
        final actualRemainingHours = (remaining.inMinutes / 60) % 24;
        final actualRemainingMinutes = remaining.inMinutes % 60;
        print(
          '$actualRemainingDays $actualRemainingHours $actualRemainingMinutes',
        );

        if (remainingMinutes <= 0) {
          return '已截止';
        } else if (remainingMinutes < 60) {
          return '剩余 $remainingMinutes 分钟';
        } else if (remainingMinutes < 60 * 24) {
          return '剩余 ${remaining.inHours} 小时 ${remaining.inMinutes % 60} 分钟';
        } else {
          return '剩余 ${remaining.inDays} 天 ${remaining.inHours % 24} 小时 ${remaining.inMinutes % 60} 分钟';
        }
      }
    }
    return '截止: $endTime';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 0, // 去掉阴影
        margin: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ), // 加大 margin
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24), // 圆角更大
        ),
        clipBehavior: Clip.hardEdge,
        child: Container(
          padding: const EdgeInsets.all(16),
          height: 110,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitleRow(context),
              const SizedBox(height: 6),
              Expanded(child: _buildNoteRow(context)),
              const SizedBox(height: 8),
              _buildProgressBar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _getRemainingTimeText(), // Changed
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildNoteRow(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        note,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.secondary,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: LinearProgressIndicator(
        value: 1.0 - progress,
        minHeight: 6,
        borderRadius: BorderRadius.circular(6),
        color: Theme.of(context).colorScheme.primary,
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      ),
    );
  }
}

class TaskUtils {
  static void onFABPressed(
    BuildContext context, {
    required Future<void> Function(
      String title,
      String note,
      String startTimeText,
      String endTimeText,
    )
    onTaskAdd,
  }) {
    final now = DateTime.now();
    final initialStartTime = _formatDateTimeToString(
      now,
      TimeOfDay.fromDateTime(now),
    );
    _showTaskDialog(
      context,
      onConfirm: onTaskAdd,
      initialStartTime: initialStartTime,
    );
  }

  static void showEditDialog(
    BuildContext context, {
    required String initialTitle,
    required String initialNote,
    required String initialStartTime,
    required String initialEndTime,
    required Future<void> Function(
      String title,
      String note,
      String startTimeText,
      String endTimeText,
    )
    onConfirm,
    required Future<void> Function() onDelete,
  }) {
    _showTaskDialog(
      context,
      initialTitle: initialTitle,
      initialNote: initialNote,
      initialStartTime: initialStartTime,
      initialEndTime: initialEndTime,
      onConfirm: onConfirm,
      onDelete: onDelete,
    );
  }

  static String _formatDateTimeToDisplayString(
    DateTime? date,
    TimeOfDay? time,
  ) {
    if (date == null || time == null) return "";
    final dateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    return "${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  static String _formatDateTimeToString(DateTime? date, TimeOfDay? time) {
    if (date == null || time == null) return "";
    final dateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}T${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00";
  }

  static void _showTaskDialog(
    BuildContext context, {
    String initialTitle = "",
    String initialNote = "",
    String initialStartTime = "",
    String initialEndTime = "",
    required Future<void> Function(
      String title,
      String note,
      String startTimeText,
      String endTimeText,
    )
    onConfirm,
    Future<void> Function()? onDelete,
  }) {
    final titleController = TextEditingController(text: initialTitle);
    final noteController = TextEditingController(text: initialNote);

    DateTime? selectedStartDate;
    TimeOfDay? selectedStartTime;
    DateTime? selectedEndDate;
    TimeOfDay? selectedEndTime;

    if (initialStartTime.isNotEmpty) {
      final parsedStartTime = GlobalUtils.safeParseDateTime(initialStartTime);
      if (parsedStartTime != GlobalUtils.timeNull) {
        selectedStartDate = parsedStartTime;
        selectedStartTime = TimeOfDay.fromDateTime(parsedStartTime);
      }
    }
    if (initialEndTime.isNotEmpty) {
      final parsedEndTime = GlobalUtils.safeParseDateTime(initialEndTime);
      if (parsedEndTime != GlobalUtils.timeNull) {
        selectedEndDate = parsedEndTime;
        selectedEndTime = TimeOfDay.fromDateTime(parsedEndTime);
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            String currentFormattedStartTime = _formatDateTimeToString(
              selectedStartDate,
              selectedStartTime,
            );
            if (currentFormattedStartTime.isEmpty &&
                initialStartTime.isNotEmpty &&
                selectedStartDate == null &&
                selectedStartTime == null) {
              currentFormattedStartTime = initialStartTime;
            }

            String displayStartTime = _formatDateTimeToDisplayString(
              selectedStartDate,
              selectedStartTime,
            );
            if (displayStartTime.isEmpty &&
                initialStartTime.isNotEmpty &&
                selectedStartDate == null &&
                selectedStartTime == null) {
              final parsedInitialStartTime = GlobalUtils.safeParseDateTime(
                initialStartTime,
              );
              if (parsedInitialStartTime != GlobalUtils.timeNull) {
                displayStartTime = _formatDateTimeToDisplayString(
                  parsedInitialStartTime,
                  TimeOfDay.fromDateTime(parsedInitialStartTime),
                );
              }
            }

            String currentFormattedEndTime = _formatDateTimeToString(
              selectedStartDate,
              selectedStartTime,
            );
            if (currentFormattedStartTime.isEmpty &&
                initialStartTime.isNotEmpty &&
                selectedStartDate == null &&
                selectedStartTime == null) {
              currentFormattedStartTime = initialStartTime;
            }

            String displayEndTime = _formatDateTimeToDisplayString(
              selectedEndDate,
              selectedEndTime,
            );
            if (displayEndTime.isEmpty &&
                initialEndTime.isNotEmpty &&
                selectedEndDate == null &&
                selectedEndTime == null) {
              final parsedInitialEndTime = GlobalUtils.safeParseDateTime(
                initialEndTime,
              );
              if (parsedInitialEndTime != GlobalUtils.timeNull) {
                displayEndTime = _formatDateTimeToDisplayString(
                  parsedInitialEndTime,
                  TimeOfDay.fromDateTime(parsedInitialEndTime),
                );
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(onDelete == null ? '添加任务' : '编辑任务'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: '任务标题',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      decoration: InputDecoration(
                        labelText: '备注',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedStartDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                          builder: (BuildContext context, Widget? child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (date != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: selectedStartTime ?? TimeOfDay.now(),
                            builder: (BuildContext context, Widget? child) {
                              return MediaQuery(
                                data: MediaQuery.of(
                                  context,
                                ).copyWith(alwaysUse24HourFormat: true),
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: child!,
                                ),
                              );
                            },
                          );
                          if (time != null) {
                            setStateDialog(() {
                              selectedStartDate = date;
                              selectedStartTime = time;
                            });
                          }
                        }
                      },
                      child: const Text('选择开始时间'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentFormattedStartTime.isEmpty
                          ? '未选择开始时间'
                          : '开始: $displayStartTime',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate:
                              selectedEndDate ??
                              selectedStartDate ??
                              DateTime.now(),
                          firstDate: selectedStartDate ?? DateTime(2000),
                          lastDate: DateTime(2101),
                          builder: (BuildContext context, Widget? child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (date != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime:
                                selectedEndTime ??
                                const TimeOfDay(hour: 23, minute: 59),
                            builder: (BuildContext context, Widget? child) {
                              return MediaQuery(
                                data: MediaQuery.of(
                                  context,
                                ).copyWith(alwaysUse24HourFormat: true),
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: child!,
                                ),
                              );
                            },
                          );
                          if (time != null) {
                            setStateDialog(() {
                              selectedEndDate = date;
                              selectedEndTime = time;
                            });
                          }
                        }
                      },
                      child: const Text('选择结束时间'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      displayEndTime.isEmpty
                          ? '未选择结束时间'
                          : '结束: $displayEndTime',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              actions: [
                if (onDelete != null)
                  TextButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await onDelete();
                    },
                    child: const Text('删除'),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () async {
                    final finalStartTimeString = _formatDateTimeToString(
                      selectedStartDate,
                      selectedStartTime,
                    );
                    final finalEndTimeString = _formatDateTimeToString(
                      selectedEndDate,
                      selectedEndTime,
                    );

                    if (titleController.text.isEmpty) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('任务标题不能为空')));
                      return;
                    }
                    if (finalStartTimeString.isEmpty) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('请选择开始时间')));
                      return;
                    }
                    if (finalEndTimeString.isEmpty) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('请选择结束时间')));
                      return;
                    }

                    if (selectedStartDate != null &&
                        selectedStartTime != null &&
                        selectedEndDate != null &&
                        selectedEndTime != null) {
                      final startDateTime = DateTime(
                        selectedStartDate!.year,
                        selectedStartDate!.month,
                        selectedStartDate!.day,
                        selectedStartTime!.hour,
                        selectedStartTime!.minute,
                      );
                      final endDateTime = DateTime(
                        selectedEndDate!.year,
                        selectedEndDate!.month,
                        selectedEndDate!.day,
                        selectedEndTime!.hour,
                        selectedEndTime!.minute,
                      );
                      if (startDateTime.isAfter(endDateTime)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('开始时间不能晚于结束时间')),
                        );
                        return;
                      }
                    }

                    await onConfirm(
                      titleController.text,
                      noteController.text,
                      finalStartTimeString,
                      finalEndTimeString,
                    );
                    Navigator.of(context).pop();
                  },
                  child: const Text('确认'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
