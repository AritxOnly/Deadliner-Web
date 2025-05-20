import 'package:flutter/material.dart';
import 'package:frontend/utils/global_utils.dart';
import 'package:provider/provider.dart';
import 'package:frontend/utils/setting_utils.dart';
import 'dart:convert';
import 'package:frontend/utils/web_utils.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'dart:io' show File;

class SettingsModel extends ChangeNotifier {
  bool _vibration = true;
  int _archiveDays = 7;
  DynamicSchemeVariant _dynamicSchemeVariant = DynamicSchemeVariant.rainbow;
  Color _accentColor = Colors.blue; // 默认强调色
  // Add other settings properties if they exist in SettingUtils and need to be managed here
  // For example:
  // bool _progressDirection = true; // Assuming default
  // bool _progressWidget = true; // Assuming default
  // bool _motivationalQuotes = true; // Assuming default
  // bool _fireworks = true; // Assuming default

  // Corresponding getters
  // bool get progressDirection => _progressDirection;
  // bool get progressWidget => _progressWidget;
  // bool get motivationalQuotes => _motivationalQuotes;
  // bool get fireworks => _fireworks;

  bool get vibration => _vibration;
  int get archiveDays => _archiveDays;
  DynamicSchemeVariant get dynamicSchemeVariant => _dynamicSchemeVariant;
  Color get accentColor => _accentColor;

  void toggleVibration(bool value) {
    _vibration = value;
    notifyListeners();
    _saveToPrefs();
  }

  void setDynamicSchemeVariant(DynamicSchemeVariant variant) {
    _dynamicSchemeVariant = variant;
    notifyListeners();
    _saveToPrefs();
  }

  void setAccentColor(Color color) {
    _accentColor = color;
    notifyListeners();
    _saveToPrefs();
  }

  // Add setters for other properties if needed, for example:
  // void toggleProgressDirection(bool value) {
  //   _progressDirection = value;
  //   notifyListeners();
  //   _saveToPrefs();
  // }
  // void toggleProgressWidget(bool value) {
  //   _progressWidget = value;
  //   notifyListeners();
  //   _saveToPrefs();
  // }
  // void toggleMotivationalQuotes(bool value) {
  //   _motivationalQuotes = value;
  //   notifyListeners();
  //   _saveToPrefs();
  // }
  // void toggleFireworks(bool value) {
  //   _fireworks = value;
  //   notifyListeners();
  //   _saveToPrefs();
  // }

  void setArchiveDays(int days) {
    _archiveDays = days;
    notifyListeners();
    _saveToPrefs();
  }

  Future<void> _saveToPrefs() async {
    GlobalUtils.vibration = _vibration;
    GlobalUtils.archiveDays = _archiveDays;
    GlobalUtils.dynamicSchemeVariant = _dynamicSchemeVariant.toString();
    GlobalUtils.accentColor =
        _accentColor.value.toString(); // Store color as int string

    // 同步设置到后端
    final webUtils = WebUtils();
    if (webUtils.currentUser != null) {
      final userPrefs = {
        'vibration': _vibration,
        'archiveDays': _archiveDays,
        'dynamicSchemeVariant': _dynamicSchemeVariant.toString(),
        'accentColor': _accentColor.value.toString(),
      };
      await webUtils.updateUserPrefs(webUtils.currentUser!, userPrefs);
    }
  }

  Future<void> loadPrefs() async {
    _vibration = GlobalUtils.vibration;
    _archiveDays = GlobalUtils.archiveDays;
    final String variantString = GlobalUtils.dynamicSchemeVariant;
    _dynamicSchemeVariant = DynamicSchemeVariant.values.firstWhere(
      (e) => e.toString() == variantString,
      orElse:
          () =>
              DynamicSchemeVariant
                  .rainbow, // Default if parsing fails or value is unexpected
    );
    // Accent color is stored as a string integer, parse it
    try {
      _accentColor = Color(int.parse(GlobalUtils.accentColor));
    } catch (e) {
      _accentColor = Colors.blue; // Default color if parsing fails
    }
    notifyListeners();
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final List<int> _archiveOptions = [1, 3, 7];
  final List<DynamicSchemeVariant> _dynamicSchemeVariantOptions =
      DynamicSchemeVariant.values;

  @override
  void initState() {
    super.initState();
    context.read<SettingsModel>().loadPrefs();
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.symmetric(horizontal: 24),
    );
  }

  Widget _buildArchiveTimeSelector() {
    final model = context.watch<SettingsModel>();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '自动归档时间',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8),
          ToggleButtons(
            isSelected:
                _archiveOptions.map((e) => e == model.archiveDays).toList(),
            onPressed: (index) => model.setArchiveDays(_archiveOptions[index]),
            constraints: BoxConstraints(minHeight: 36),
            borderColor: Theme.of(context).colorScheme.outline,
            selectedBorderColor: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(8),
            children:
                _archiveOptions
                    .map(
                      (days) => Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('$days天'),
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<SettingsModel>();

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 通用设置
            _buildSectionTitle('通用设置'),
            Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  _buildSwitchTile(
                    '振动反馈',
                    model.vibration,
                    model.toggleVibration,
                  ),
                  _buildSwitchTile('进度方向', true, (_) {}),
                  _buildSwitchTile('励志语录', true, (_) {}),
                  _buildSwitchTile('完成动画', true, (_) {}),
                  _buildArchiveTimeSelector(),
                  _buildDynamicSchemeVariantSelector(),
                  _buildAccentColorSelector(), // 新增强调色选择器
                ],
              ),
            ),

            // 通知设置
            _buildSectionTitle('通知设置'),
            Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.errorContainer,
              child: ListTile(
                leading: Icon(
                  Icons.warning,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                title: Text(
                  '通知功能开发中',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),

            // 备份设置
            _buildSectionTitle('数据管理'),
            Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.import_export),
                    title: Text('导入数据'),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['json'],
                        withData: kIsWeb, // web 直接拿 bytes
                      );
                      if (result == null || result.files.isEmpty)
                        return; // 用户取消

                      String content;
                      if (kIsWeb) {
                        // Web 上直接用 bytes 解码
                        final bytes = result.files.first.bytes!;
                        content = utf8.decode(bytes);
                      } else {
                        // 移动端读取本地路径
                        final path = result.files.first.path!;
                        content = await File(path).readAsString();
                      }

                      // 2. 解析 JSON
                      dynamic jsonData;
                      try {
                        jsonData = jsonDecode(content);
                      } catch (e) {
                        // 解析失败
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('解析 JSON 失败：$e')),
                        );
                        return;
                      }

                      // 3. 调用你的导入逻辑
                      try {
                        await SettingUtils.importSettings(jsonData);
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('导入成功')));
                      } catch (e) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('导入失败：$e')));
                      }
                    },
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.save_alt),
                    title: Text('导出数据'),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () async {
                      final json = await SettingUtils.exportSettings();
                      print(json);
                    },
                  ),
                ],
              ),
            ),

            // 关于
            _buildSectionTitle('关于'),
            Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: ListTile(
                leading: Icon(
                  Icons.info,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
                title: Text(
                  '版本号 1.0.0',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicSchemeVariantSelector() {
    final model = context.watch<SettingsModel>();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '色彩风格',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8),
          DropdownButton<DynamicSchemeVariant>(
            value: model.dynamicSchemeVariant,
            isExpanded: true,
            onChanged: (DynamicSchemeVariant? newValue) {
              if (newValue != null) {
                model.setDynamicSchemeVariant(newValue);
              }
            },
            items:
                _dynamicSchemeVariantOptions
                    .map<DropdownMenuItem<DynamicSchemeVariant>>((
                      DynamicSchemeVariant value,
                    ) {
                      return DropdownMenuItem<DynamicSchemeVariant>(
                        value: value,
                        child: Text(
                          value.toString().split('.').last,
                        ), // Display friendly name
                      );
                    })
                    .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAccentColorSelector() {
    final model = context.watch<SettingsModel>();
    // 定义一些预设的颜色选项
    final List<Color> _colorOptions = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
    ];

    // 将颜色转换为用户友好的名称
    String _getColorName(Color color) {
      if (color.toARGB32() == Colors.blue.toARGB32()) return '蓝色';
      if (color.toARGB32() == Colors.red.toARGB32()) return '红色';
      if (color.toARGB32() == Colors.green.toARGB32()) return '绿色';
      if (color.toARGB32() == Colors.orange.toARGB32()) return '橙色';
      if (color.toARGB32() == Colors.purple.toARGB32()) return '紫色';
      if (color.toARGB32() == Colors.teal.toARGB32()) return '青色';
      if (color.toARGB32() == Colors.indigo.toARGB32()) return '靛色';
      return color.toString(); // 备用名称
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '强调色',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8),
          DropdownButton<Color>(
            value: _colorOptions.firstWhere(
              (c) => c.toARGB32() == model.accentColor.toARGB32(),
              orElse: () => _colorOptions.first,
            ),
            isExpanded: true,
            onChanged: (Color? newValue) {
              if (newValue != null) {
                model.setAccentColor(newValue);
              }
            },
            items:
                _colorOptions.map<DropdownMenuItem<Color>>((Color value) {
                  return DropdownMenuItem<Color>(
                    value: value,
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: value,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                              width: 1,
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Text(_getColorName(value)),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}
