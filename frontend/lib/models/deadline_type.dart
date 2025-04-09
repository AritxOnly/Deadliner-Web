// ignore_for_file: constant_identifier_names

enum DeadlineType {
  TASK,
  HABIT;

  static DeadlineType fromString(String str) {
    if (str == 'task') {
      return DeadlineType.TASK;
    } else if (str == 'habit') {
      return DeadlineType.HABIT;
    } else {
      throw Exception('Invalid DeadlineType string: $str');
    }
  }
}
