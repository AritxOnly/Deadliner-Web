import 'package:flutter/material.dart';
import 'package:frontend/utils/global_utils.dart';

/// 设置操作工具类
class SettingUtils {
  /// 导出设置到JSON
  static Future<Map<String, dynamic>> exportSettings() async {
    return {
      SettingKeys.vibration: GlobalUtils.vibration,
      SettingKeys.archiveDays: GlobalUtils.archiveDays,
      SettingKeys.progressDirection: GlobalUtils.progressDirection,
      SettingKeys.motivationalQuotes: GlobalUtils.motivationalQuotes, // 新增
      SettingKeys.fireworks: GlobalUtils.fireworks,
      SettingKeys.dynamicSchemeVariant: GlobalUtils.dynamicSchemeVariant,
      SettingKeys.accentColor: GlobalUtils.accentColor,
    };
  }

  /// 从JSON导入设置
  static Future<void> importSettings(Map<String, dynamic> json) async {
    GlobalUtils.vibration = json[SettingKeys.vibration] as bool;
    GlobalUtils.archiveDays = json[SettingKeys.archiveDays] as int;
    GlobalUtils.progressDirection = json[SettingKeys.progressDirection] as bool;
    GlobalUtils.motivationalQuotes =
        json[SettingKeys.motivationalQuotes] as bool; // 新增
    GlobalUtils.fireworks = json[SettingKeys.fireworks] as bool;
    GlobalUtils.dynamicSchemeVariant =
        json[SettingKeys.dynamicSchemeVariant] as String;
    GlobalUtils.accentColor = json[SettingKeys.accentColor] as String;
  }
}

/// 设置页面样式工具
class SettingStyleUtils {
  /// 获取卡片默认边距
  static EdgeInsets get cardMargin =>
      const EdgeInsets.symmetric(horizontal: 16, vertical: 8);

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
