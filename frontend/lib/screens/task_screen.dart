import 'package:flutter/material.dart';
import 'package:frontend/models/deadline_type.dart';
import 'package:frontend/utils/task_utils.dart';
import 'package:frontend/utils/web_utils.dart';
import 'package:frontend/utils/global_utils.dart';
import 'package:frontend/models/ddl_item.dart';
import 'package:http/http.dart';
import 'package:confetti/confetti.dart';

class TaskScreen extends StatefulWidget {
  final Function(bool isMultiSelect, int selectionCount)?
  onMultiSelectModeChanged;
  final VoidCallback? requestDeleteSelected;
  final VoidCallback? requestToggleMultiSelectMode;
  final String? searchQuery; // Added for search functionality

  const TaskScreen({
    super.key,
    this.onMultiSelectModeChanged,
    this.requestDeleteSelected,
    this.requestToggleMultiSelectMode,
    this.searchQuery, // Added for search functionality
  });

  @override
  State<TaskScreen> createState() => TaskScreenState();
}

class TaskScreenState extends State<TaskScreen> {
  final List<Map<String, dynamic>> _taskData = [];
  List<Map<String, dynamic>> _filteredTaskData = []; // For search results
  late WebUtils webUtils;
  late ConfettiController _confettiController;
  bool _isMultiSelectMode = false;
  final List<int> _selectedTaskIndexes = [];

  void _sortTaskData() {
    _taskData.sort((a, b) {
      final bool aCompleted = a['isCompleted'] as bool;
      final bool bCompleted = b['isCompleted'] as bool;
      if (aCompleted != bCompleted) {
        return aCompleted ? 1 : -1;
      }
      final double aProgress = a['progress'] as double;
      final double bProgress = b['progress'] as double;
      return bProgress.compareTo(aProgress);
    });
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
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );

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
              if (item.isCompleted) {
                progress = 0.0; // 已完成的任务进度为0
              } else if (startTime != GlobalUtils.timeNull &&
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

              // 将DDLItem转换为任务数据格式
              _taskData.add({
                'id': item.id, // 保存ID以便后续更新和删除
                'title': item.name,
                'note': item.note,
                'startTime': item.startTime, // Added
                'endTime': item.endTime, // Added
                'progress': progress,
                'isCompleted': item.isCompleted, // Added
                'completeTime': item.completeTime, // Added
              });
            }
            _sortTaskData(); // Sort after fetching DDLs
            _filterTasks(); // Apply initial filter (which might be empty query)
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

  @override
  void didUpdateWidget(covariant TaskScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery) {
      _filterTasks();
    }
  }

  void _filterTasks() {
    if (widget.searchQuery == null || widget.searchQuery!.isEmpty) {
      setState(() {
        _filteredTaskData = List.from(_taskData);
      });
    } else {
      final query = widget.searchQuery!.toLowerCase();
      setState(() {
        _filteredTaskData =
            _taskData.where((task) {
              final title = task['title']?.toString().toLowerCase() ?? '';
              final note = task['note']?.toString().toLowerCase() ?? '';
              return title.contains(query) || note.contains(query);
            }).toList();
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _completeTask(int index) async {
    if (_isMultiSelectMode) return; // Disable complete in multi-select mode
    final task = _taskData[index];
    final taskId = task['id'];
    if (taskId == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('任务ID不存在，无法完成任务')));
      }
      return;
    }

    final taskIsCompleted = task['isCompleted'] ?? false;

    final nowString = DateTime.now().toIso8601String();
    final Map<String, dynamic> updates = {
      'isCompleted': !taskIsCompleted,
      'completeTime': nowString,
      // 'progress': 0.0, // 后端可能会根据isCompleted自动处理，或者我们在这里也发送
    };

    try {
      final success = await webUtils.updateDDL(taskId, updates);
      if (success) {
        final taskItem = await webUtils.getDDLById(taskId);

        final startDateTime = GlobalUtils.safeParseDateTime(taskItem.startTime);
        final endDateTime = GlobalUtils.safeParseDateTime(taskItem.endTime);
        final now = DateTime.now();
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
            final elapsedDuration =
                now.difference(startDateTime).inMilliseconds;
            progress =
                totalDuration > 0 ? elapsedDuration / totalDuration : 0.0;
            progress = progress.clamp(0.0, 1.0);
          }
        } else if (endDateTime != GlobalUtils.timeNull &&
            now.isAfter(endDateTime)) {
          progress = 1.0;
        }

        final actualProgress = (!taskIsCompleted) ? 0.0 : progress;

        setState(() {
          _taskData[index]['isCompleted'] = !taskIsCompleted;
          _taskData[index]['completeTime'] = nowString;
          _taskData[index]['progress'] = actualProgress; // 客户端也将进度设置为0
          _sortTaskData();
          _filterTasks(); // Re-apply filter after task completion
        });
        if (GlobalUtils.fireworks) _confettiController.play();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('标记任务完成失败')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('标记任务完成时出错: $e')));
      }
    }
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
          'isCompleted': false, // New tasks are not completed
          'completeTime': '', // No complete time for new tasks
        });
        _sortTaskData();
        _filterTasks(); // Re-apply filter after adding task
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
        // isCompleted and completeTime are not changed here, only by _completeTask
      };

      final success = await webUtils.updateDDL(taskId, updates);

      if (success) {
        double progress = 0.0;
        bool isCompleted = _taskData[index]['isCompleted'] ?? false;

        if (isCompleted) {
          progress = 0.0; // If already completed, progress remains 0
        } else if (newStartDateTime != GlobalUtils.timeNull &&
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
          // isCompleted and completeTime remain unchanged by this method
          _sortTaskData();
          _filterTasks(); // Re-apply filter after updating task
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
    // This individual delete might still be used by the edit dialog
    // Or we can choose to remove it if all deletions go through multi-select
    try {
      final taskId = _taskData[index]['id'];
      if (taskId == null) {
        throw Exception('任务ID不存在');
      }
      final success = await webUtils.deleteDDL(taskId);
      if (success) {
        setState(() {
          _taskData.removeAt(index);
          // If in multi-select mode, also remove from selected indexes if present
          _selectedTaskIndexes.remove(index);
          // Adjust other selected indexes if they were after the deleted one
          for (int i = 0; i < _selectedTaskIndexes.length; i++) {
            if (_selectedTaskIndexes[i] > index) {
              _selectedTaskIndexes[i]--;
            }
          }
          _filterTasks(); // Re-apply filter after deleting task
        });
      } else {
        throw Exception('删除任务失败');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('删除任务失败: $e')));
      }
    }
  }

  void _toggleMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) {
        _selectedTaskIndexes.clear();
      }
    });
    widget.onMultiSelectModeChanged?.call(
      _isMultiSelectMode,
      _selectedTaskIndexes.length,
    );
    // This call might be redundant if HomePage directly calls _toggleMultiSelectMode via a new callback
    // For now, let's assume HomePage has a button that calls requestToggleMultiSelectMode, which in turn calls this.
    // Or, HomePage listens to onMultiSelectModeChanged and updates its UI, and provides buttons that call requestDeleteSelected or requestToggleMultiSelectMode.
  }

  void _toggleTaskSelection(int index) {
    setState(() {
      if (_selectedTaskIndexes.contains(index)) {
        _selectedTaskIndexes.remove(index);
      } else {
        _selectedTaskIndexes.add(index);
      }
    });
    widget.onMultiSelectModeChanged?.call(
      _isMultiSelectMode,
      _selectedTaskIndexes.length,
    );
  }

  Future<void> _deleteSelectedTasks() async {
    if (_selectedTaskIndexes.isEmpty) return;

    List<int> idsToDelete = [];
    List<int> successfullyDeletedIndexes = []; // Store original indexes

    // Sort indexes in descending order to avoid issues when removing items
    _selectedTaskIndexes.sort((a, b) => b.compareTo(a));

    for (int index in _selectedTaskIndexes) {
      final taskId = _taskData[index]['id'];
      if (taskId != null) {
        idsToDelete.add(taskId);
      }
    }

    bool allSucceeded = true;
    for (int id in idsToDelete) {
      try {
        final success = await webUtils.deleteDDL(id);
        if (!success) {
          allSucceeded = false;
          // Optionally, collect failed IDs or show individual error messages
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('删除任务ID $id 失败')));
          }
        }
      } catch (e) {
        allSucceeded = false;
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('删除任务ID $id 时出错: $e')));
        }
      }
    }

    if (allSucceeded || _selectedTaskIndexes.isNotEmpty) {
      // Proceed to update UI if any attempt was made or some succeeded
      setState(() {
        for (int index in _selectedTaskIndexes) {
          // Check if the task at this index still exists (it might have been shifted by previous deletions)
          // This logic is complex due to index shifting. A safer way is to remove by ID or re-fetch.
          // For now, we assume _selectedTaskIndexes are original indexes and remove them carefully.
          // This part needs careful handling of indexes if not all deletions succeed or if _taskData is modified elsewhere.
        }
        // A simpler way to update _taskData after deletions:
        _taskData.removeWhere((task) => idsToDelete.contains(task['id']));
        _selectedTaskIndexes.clear();
        _isMultiSelectMode = false;
        _sortTaskData();
        _filterTasks(); // Re-apply filter after deleting selected tasks
      });
      if (mounted && !allSucceeded) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('部分任务删除失败，请检查')));
      } else if (mounted && allSucceeded && idsToDelete.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('选定任务已删除')));
      }
    }
  }

  // Expose methods to be called by HomePage via callbacks
  void handleRequestToggleMultiSelectMode() {
    _toggleMultiSelectMode();
  }

  void handleRequestDeleteSelected() {
    _deleteSelectedTasks();
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

    // Removed Scaffold and AppBar from here
    return Stack(
      alignment: Alignment.topCenter, // For Confetti
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
            itemCount: _filteredTaskData.length, // Use filtered data
            itemBuilder: (context, index) {
              final task = _filteredTaskData[index]; // Use filtered data
              // Find original index in _taskData if needed for operations like delete/update
              // This is important because _completeTask, updateTask, deleteTask still use original _taskData indexes.
              // A more robust way would be to pass the task object or its ID directly to these functions.
              // For now, we'll try to find the original index.
              final originalIndex = _taskData.indexWhere(
                (t) => t['id'] == task['id'],
              );
              if (originalIndex == -1) {
                // This should not happen if data is consistent
                return const SizedBox.shrink();
              }
              final bool isSelected = _selectedTaskIndexes.contains(index);
              return DDLItemWidget(
                title: task['title'],
                note: task['note'],
                startTime: task['startTime'] as String,
                endTime: task['endTime'] as String,
                progress: task['progress'],
                isCompleted: task['isCompleted'] ?? false,
                isSelected: isSelected,
                onTap: () {
                  if (originalIndex == -1) return;
                  if (_isMultiSelectMode) {
                    _toggleTaskSelection(
                      originalIndex,
                    ); // Use originalIndex for multi-select
                  } else {
                    if (task['isCompleted'] ?? false) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已完成的任务不能编辑')),
                      );
                      return;
                    }
                    TaskUtils.showEditDialog(
                      context,
                      initialTitle: task['title'],
                      initialNote: task['note'],
                      initialStartTime: task['startTime'] as String,
                      initialEndTime: task['endTime'] as String,
                      onConfirm: (
                        newTitle,
                        newNote,
                        newStartTime,
                        newEndTime,
                      ) async {
                        await updateTask(
                          originalIndex, // Use originalIndex
                          newTitle,
                          newNote,
                          newStartTime,
                          newEndTime,
                        );
                      },
                      onDelete: () async {
                        await deleteTask(originalIndex); // Use originalIndex
                      },
                    );
                  }
                },
                onLongPress: () {
                  if (originalIndex == -1) return;
                  if (_isMultiSelectMode) {
                    _toggleTaskSelection(originalIndex); // Use originalIndex
                  } else {
                    _completeTask(originalIndex); // Use originalIndex
                  }
                },
                onSelectToggle:
                    () => _toggleTaskSelection(
                      originalIndex,
                    ), // Use originalIndex
              );
            },
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () {
              if (_isMultiSelectMode) {
                // This FAB will now call the exposed method if HomePage needs to trigger it
                // For now, it directly calls _deleteSelectedTasks. If AppBar in HomePage handles delete,
                // this FAB might need a different role or be hidden in multi-select mode by HomePage.
                // Let's assume FAB's delete action is still managed here for simplicity of this step.
                _deleteSelectedTasks();
              } else {
                TaskUtils.onFABPressed(context, onTaskAdd: addTask);
              }
            },
            child: Icon(_isMultiSelectMode ? Icons.delete : Icons.add),
            backgroundColor:
                _isMultiSelectMode && _selectedTaskIndexes.isEmpty
                    ? Colors.grey
                    : null,
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
            ],
            numberOfParticles: 20,
            gravity: 0.1,
          ),
        ),
      ],
    );
  }
}

class DDLItemWidget extends StatelessWidget {
  final String title;
  final String startTime;
  final String endTime;
  final String note;
  final double progress;
  final bool isCompleted;
  final bool isSelected; // New parameter
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSelectToggle; // New parameter

  const DDLItemWidget({
    super.key,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.note = "",
    required this.progress,
    required this.isCompleted,
    required this.isSelected, // New
    this.onTap,
    this.onLongPress,
    this.onSelectToggle, // New
  });

  String _getRemainingTimeText() {
    if (isCompleted) {
      return '已完成';
    }
    final now = DateTime.now();
    final endDateTime = GlobalUtils.safeParseDateTime(endTime);

    if (endDateTime != GlobalUtils.timeNull) {
      if (now.isAfter(endDateTime)) {
        return '已截止';
      } else {
        final remaining = endDateTime.difference(now);
        // final remainingMinutes = remaining.inMinutes;
        // final actualRemainingDays = remaining.inMinutes / (60 * 24);
        // final actualRemainingHours = (remaining.inMinutes / 60) % 24;
        // final actualRemainingMinutes = remaining.inMinutes % 60;
        // print(
        //   '$actualRemainingDays $actualRemainingHours $actualRemainingMinutes',
        // );

        if (remaining.inMinutes <= 0) {
          return '已截止';
        } else if (remaining.inMinutes < 60) {
          return '剩余 ${remaining.inMinutes} 分钟';
        } else if (remaining.inMinutes < 60 * 24) {
          return '剩余 ${remaining.inHours} 小时 ${remaining.inMinutes % 60} 分钟';
        } else {
          return '剩余 ${remaining.inDays} 天 ${remaining.inHours % 24} 小时'; // Simplified for brevity
        }
      }
    }
    return '截止: $endTime';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // onTap will handle selection in multi-select mode
      onLongPress:
          onLongPress, // onLongPress will handle selection in multi-select or complete task
      child: Card(
        elevation: 0, // 去掉阴影
        margin: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ), // 加大 margin
        shape: RoundedRectangleBorder(
          side:
              isSelected
                  ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
                  : BorderSide.none,
          borderRadius: BorderRadius.circular(24), // 圆角更大
        ),
        clipBehavior: Clip.hardEdge,
        color:
            isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
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
        value:
            isCompleted
                ? 0.0
                : (GlobalUtils.progressDirection
                    ? progress
                    : 1.0 - progress), // Adjusted for completion and direction
        minHeight: 6,
        borderRadius: BorderRadius.circular(6),
        color:
            isCompleted ? Colors.grey : Theme.of(context).colorScheme.primary,
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
