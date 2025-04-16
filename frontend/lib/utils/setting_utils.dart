import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 设置项键名常量
class SettingKeys {
  static const String vibration = 'vibration';
  static const String archiveDays = 'archiveDays';
  static const String progressDirection = 'progressDirection';
  static const String progressWidget = 'progressWidget';
  static const String motivationalQuotes = 'motivationalQuotes';
  static const String fireworks = 'fireworks';
}

/// 设置操作工具类
class SettingUtils {
  /// 保存布尔类型设置
  static Future<void> saveBoolSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  /// 获取布尔类型设置
  static Future<bool> getBoolSetting(String key, {bool defaultValue = false}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? defaultValue;
  }

  /// 保存整数类型设置
  static Future<void> saveIntSetting(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  /// 获取整数类型设置
  static Future<int> getIntSetting(String key, {int defaultValue = 0}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key) ?? defaultValue;
  }

  /// 重置所有设置
  static Future<void> resetAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// 导出设置到JSON
  static Future<Map<String, dynamic>> exportSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      SettingKeys.vibration: prefs.getBool(SettingKeys.vibration),
      SettingKeys.archiveDays: prefs.getInt(SettingKeys.archiveDays),
      // 添加其他需要导出的键...
    };
  }

  /// 从JSON导入设置
  static Future<void> importSettings(Map<String, dynamic> json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SettingKeys.vibration, json[SettingKeys.vibration] as bool);
    await prefs.setInt(SettingKeys.archiveDays, json[SettingKeys.archiveDays] as int);
    // 处理其他导入键...
  }
}

/// 设置页面样式工具
class SettingStyleUtils {
  /// 获取卡片默认边距
  static EdgeInsets get cardMargin => const EdgeInsets.symmetric(horizontal: 16, vertical: 8);

  /// 构建设置项标题样式
  static TextStyle sectionTitleStyle(BuildContext context) {
    return TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  /// 构建警告卡片样式
  static CardTheme warningCardTheme(BuildContext context) {
    return CardTheme(
      color: Theme.of(context).colorScheme.errorContainer,
      margin: cardMargin,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}