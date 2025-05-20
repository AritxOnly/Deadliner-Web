import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb; // For platform-specific logic if needed

class SettingKeys {
  static const String vibration = 'vibration';
  static const String archiveDays = 'archiveDays';
  static const String progressDirection = 'progressDirection';
  static const String motivationalQuotes = 'motivationalQuotes';
  static const String fireworks = 'fireworks';
  static const String dynamicSchemeVariant = 'dynamicSchemeVariant';
  static const String accentColor = 'accentColor';
  // Add any other keys from SettingUtils.dart if they exist and are used
}

/// 全局工具类
class GlobalUtils {
  static SharedPreferences? _prefs;

  /// Initializes SharedPreferences instance.
  /// Must be called once at app startup, e.g., in main().
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Helper to ensure _prefs is initialized
  static SharedPreferences get _prefsInstance {
    if (_prefs == null) {
      // This should ideally not happen if init() is called correctly at startup.
      // Consider throwing an error or initializing synchronously if that's possible and safe.
      // For now, let's throw an error to highlight the issue.
      throw StateError(
        'SharedPreferences has not been initialized. Call GlobalUtils.init() first.',
      );
    }
    return _prefs!;
  }

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

  // Settings Getters and Setters

  /// Vibration setting
  static bool get vibration {
    return _prefsInstance.getBool(SettingKeys.vibration) ??
        true; // Default true as per user example
  }

  static set vibration(bool value) {
    _prefsInstance.setBool(SettingKeys.vibration, value);
  }

  /// Archive days setting
  static int get archiveDays {
    return _prefsInstance.getInt(SettingKeys.archiveDays) ??
        7; // Default 7 days
  }

  static set archiveDays(int value) {
    _prefsInstance.setInt(SettingKeys.archiveDays, value);
  }

  /// Progress direction setting
  static bool get progressDirection {
    return _prefsInstance.getBool(SettingKeys.progressDirection) ??
        true; // Default true
  }

  static set progressDirection(bool value) {
    _prefsInstance.setBool(SettingKeys.progressDirection, value);
  }

  /// Motivational quotes setting
  static bool get motivationalQuotes {
    return _prefsInstance.getBool(SettingKeys.motivationalQuotes) ??
        true; // Default true
  }

  static set motivationalQuotes(bool value) {
    _prefsInstance.setBool(SettingKeys.motivationalQuotes, value);
  }

  /// Fireworks effect setting
  static bool get fireworks {
    return _prefsInstance.getBool(SettingKeys.fireworks) ??
        true; // Default true
  }

  static set fireworks(bool value) {
    _prefsInstance.setBool(SettingKeys.fireworks, value);
  }

  /// Dynamic scheme variant setting
  static String get dynamicSchemeVariant {
    // Example default, confirm actual values and appropriate default
    return _prefsInstance.getString(SettingKeys.dynamicSchemeVariant) ??
        'rainbow';
  }

  static set dynamicSchemeVariant(String value) {
    _prefsInstance.setString(SettingKeys.dynamicSchemeVariant, value);
  }

  static String get accentColor =>
      _prefsInstance.getString(SettingKeys.accentColor) ??
      Colors.blue.value.toString(); // Default to blue if not set
  static set accentColor(String value) =>
      _prefsInstance.setString(SettingKeys.accentColor, value);

  /// Reset all settings to their defaults
  /// Note: This clears all SharedPreferences, then re-applies defaults for known keys.
  /// Be cautious if other parts of the app use SharedPreferences directly.
  static Future<void> resetAllSettings() async {
    // Option 1: Clear all and then set defaults (more robust if unknown keys exist)
    // await _prefsInstance.clear();
    // vibration = true; // Re-apply default
    // archiveDays = 7; // Re-apply default
    // ... and so on for all settings

    // Option 2: Set known keys to their default values (safer if other data is in SharedPreferences)
    vibration = true;
    archiveDays = 7;
    progressDirection = true;
    motivationalQuotes = true;
    fireworks = true;
    dynamicSchemeVariant = 'rainbow'; // Ensure these defaults are correct
    accentColor =
        Colors.blue.value.toString(); // Ensure these defaults are correct
    // This requires knowing all settings and their defaults explicitly.
  }

  // It might be useful to keep export/import settings here too, or adapt them.
  // For now, focusing on getters/setters.
}
