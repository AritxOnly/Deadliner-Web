// ignore_for_file: constant_identifier_names

enum DeadlineType {
  TASK,
  HABIT;

  static DeadlineType fromString(String str) {
    str = str.toLowerCase();
    if (str == 'task') {
      return DeadlineType.TASK;
    } else if (str == 'habit') {
      return DeadlineType.HABIT;
    } else {
      throw Exception('Invalid DeadlineType string: $str');
    }
  }

  @override
  String toString() {
    return name.toLowerCase();
  }
}
