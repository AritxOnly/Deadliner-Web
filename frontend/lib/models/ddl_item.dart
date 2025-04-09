import 'package:frontend/models/deadline_type.dart';

class DDLItem {
  DDLItem({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    this.isCompleted = false,
    this.completeTime = '',
    this.note = '',
    this.isArchived = false,
    this.isStared = false,
    this.type = DeadlineType.TASK,
    this.habitCount = 0,
  });

  final int id;
  final String name;
  final String startTime;
  final String endTime;
  final bool isCompleted;
  final String completeTime;
  final String note;
  final bool isArchived;
  final bool isStared;
  final DeadlineType type;
  final int habitCount;
}