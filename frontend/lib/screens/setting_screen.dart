import 'package:flutter/material.dart';
import 'package:frontend/utils/setting_utils.dart';
import 'package:frontend/utils/web_utils.dart';
import 'package:http/http.dart';


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '设置',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: MediaQuery.of(context).platformBrightness,
        ),
      ),
      home: SettingsPage(),
    );
  }
}

class SettingsModel extends ChangeNotifier {
  bool _vibration = true;
  int _archiveDays = 7;

  bool get vibration => _vibration;
  int get archiveDays => _archiveDays;

  void toggleVibration(bool value) {
    _vibration = value;
    notifyListeners();
    _saveToPrefs();
  }

  void setArchiveDays(int days) {
    _archiveDays = days;
    notifyListeners();
    _saveToPrefs();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibration', _vibration);
    await prefs.setInt('archiveDays', _archiveDays);
  }

  Future<void> loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _vibration = prefs.getBool('vibration') ?? true;
    _archiveDays = prefs.getInt('archiveDays') ?? 7;
    notifyListeners();
  }
}

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final List<int> _archiveOptions = [1, 3, 7];

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
            isSelected: _archiveOptions.map((e) => e == model.archiveDays).toList(),
            onPressed: (index) => model.setArchiveDays(_archiveOptions[index]),
            children: _archiveOptions.map((days) => Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('${days}天'),
            )).toList(),
            constraints: BoxConstraints(minHeight: 36),
            borderColor: Theme.of(context).colorScheme.outline,
            selectedBorderColor: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<SettingsModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text('设置'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        scrolledUnderElevation: 4,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 通用设置
            _buildSectionTitle('通用设置'),
            Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  _buildSwitchTile('振动反馈', model.vibration, model.toggleVibration),
                  _buildSwitchTile('进度方向', true, (_) {}),
                  _buildSwitchTile('进度组件', true, (_) {}),
                  _buildSwitchTile('励志语录', true, (_) {}),
                  _buildSwitchTile('完成动画', true, (_) {}),
                  _buildArchiveTimeSelector(),
                ],
              ),
            ),

            // 通知设置
            _buildSectionTitle('通知设置'),
            Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.errorContainer,
              child: ListTile(
                leading: Icon(Icons.warning, color: Theme.of(context).colorScheme.onErrorContainer),
                title: Text('通知功能开发中', style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
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
                    onTap: () {},
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.save_alt),
                    title: Text('导出数据'),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {},
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
                leading: Icon(Icons.info, color: Theme.of(context).colorScheme.onSecondaryContainer),
                title: Text('版本号 1.0.0', style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}