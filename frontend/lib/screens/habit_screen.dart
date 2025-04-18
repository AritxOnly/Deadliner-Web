import 'package:flutter/material.dart';
import 'package:frontend/utils/task_utils.dart';
import 'package:frontend/utils/web_utils.dart';
import 'package:http/http.dart';

class HabitScreen extends StatefulWidget {
  const HabitScreen({super.key});

  @override
  State<HabitScreen> createState() => _HabitScreenState();
}

class _HabitScreenState extends State<HabitScreen> {
  final List<Map<String, dynamic>> _habitData = [];
  late WebUtils webUtils;


  void exampleInit() {
    _habitData.addAll([
      {'title': '晨跑', 'note': '每天跑3公里', 'count': 5},
      {'title': '读书', 'note': '每日阅读30分钟', 'count': 12},
    ]);
  }

  @override
  void initState() {
    super.initState();
    exampleInit();
  }

  void addHabit(String title, String note) {
    setState(() {
      _habitData.add({
        'title': title,
        'note': note,
        'count': 0,
      });
    });
  }

  void updateHabit(int index, String title, String note) {
    setState(() {
      _habitData[index]['title'] = title;
      _habitData[index]['note'] = note;
    });
  }

  void deleteHabit(int index) {
    setState(() {
      _habitData.removeAt(index);
    });
  }

  void incrementCount(int index) {
    setState(() {
      _habitData[index]['count'] += 1;
    });
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
                childAspectRatio: 3,
              ),
              itemCount: _habitData.length,
              itemBuilder: (context, index) {
                final habit = _habitData[index];
                return HabitItem(
                  title: habit['title'],
                  note: habit['note'],
                  count: habit['count'],
                  onTap: () {
                    HabitUtils.showEditDialog(
                      context,
                      initialTitle: habit['title'],
                      initialNote: habit['note'],
                      onConfirm: (newTitle, newNote) {
                        updateHabit(index, newTitle, newNote);
                      },
                      onDelete: () {
                        deleteHabit(index);
                      },
                    );
                  },
                  onCheckIn: () => incrementCount(index),
                );
              },
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: () {
                HabitUtils.onFABPressed(context, onHabitAdd: addHabit);
              },
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}

class HabitItem extends StatelessWidget {
  final String title;
  final String note;
  final int count;
  final VoidCallback? onTap;
  final VoidCallback onCheckIn;

  const HabitItem({
    super.key,
    required this.title,
    this.note = '',
    required this.count,
    this.onTap,
    required this.onCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        clipBehavior: Clip.hardEdge,
        child: Container(
          padding: const EdgeInsets.all(16),
          height: 110,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '已打卡 $count 次',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  note,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: onCheckIn,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('打卡'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HabitUtils {
  static void onFABPressed(
    BuildContext context, {
    required void Function(String title, String note) onHabitAdd,
  }) {
    _showHabitDialog(context, onConfirm: onHabitAdd);
  }

  static void showEditDialog(
    BuildContext context, {
    required String initialTitle,
    required String initialNote,
    required void Function(String title, String note) onConfirm,
    required VoidCallback onDelete,
  }) {
    _showHabitDialog(
      context,
      initialTitle: initialTitle,
      initialNote: initialNote,
      onConfirm: onConfirm,
      onDelete: onDelete,
    );
  }

  static void _showHabitDialog(
    BuildContext context, {
    String initialTitle = '',
    String initialNote = '',
    required void Function(String title, String note) onConfirm,
    VoidCallback? onDelete,
  }) {
    final titleController = TextEditingController(text: initialTitle);
    final noteController = TextEditingController(text: initialNote);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(onDelete == null ? '添加习惯' : '编辑习惯'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: '习惯名称',
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
              ],
            ),
          ),
          actions: [
            if (onDelete != null)
              TextButton(onPressed: onDelete, child: const Text('删除')),
            ElevatedButton(
              onPressed: () {
                onConfirm(
                  titleController.text,
                  noteController.text,
                );
                Navigator.of(context).pop();
              },
              child: const Text('确认'),
            ),
          ],
        );
      },
    );
  }
}
