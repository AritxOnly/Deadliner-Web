import 'package:intl/intl.dart';

/// 全局工具类
class GlobalUtils {
  /// 用于表示空时间的常量
  static final DateTime timeNull = DateTime(1970, 1, 1);

  /// 解析日期时间字符串为DateTime对象
  /// 支持多种格式的日期时间字符串
  /// @param dateTimeString 日期时间字符串
  /// @return 解析后的DateTime对象，如果解析失败则返回null
  static DateTime? parseDateTime(String dateTimeString) {
    if (dateTimeString == "null") return null;

    final formatters = [
      DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS"),
      DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSSSS"),
      DateFormat("yyyy-MM-dd'T'HH:mm:ss"),
      DateFormat("yyyy-MM-dd'T'HH:mm"),
    ];

    for (var formatter in formatters) {
      try {
        return formatter.parse(dateTimeString);
      } catch (e) {
        // 尝试下一个格式
      }
    }
    throw ArgumentError("Invalid date format: $dateTimeString");
  }

  /// 安全解析日期时间字符串为DateTime对象
  /// 如果解析失败则返回默认的空时间
  /// @param dateTimeString 日期时间字符串
  /// @return 解析后的DateTime对象，如果解析失败则返回timeNull
  static DateTime safeParseDateTime(String dateTimeString) {
    return parseDateTime(dateTimeString) ?? timeNull;
  }
}
