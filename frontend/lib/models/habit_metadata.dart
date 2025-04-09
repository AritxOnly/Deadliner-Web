import 'package:frontend/models/deadline_frequency.dart';

class HabitMetaData {
  HabitMetaData({
    required this.completedDates,
    required this.frequencyType,
    required this.frequency,
    required this.total,
    required this.refreshDate
  });

  final Set<String> completedDates;
  final DeadlineFrequency frequencyType;
  final int frequency;
  final int total;
  final String refreshDate;
}
