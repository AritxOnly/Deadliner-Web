import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // 导入 flutter_markdown
import 'package:frontend/utils/web_utils.dart'; // 导入 WebUtils
import 'package:frontend/models/ddl_item.dart'; // 导入 DDLItem 模型
import 'package:frontend/models/deadline_type.dart'; // 导入 DeadlineType

class AIScreen extends StatefulWidget {
  const AIScreen({super.key});

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  // final TextEditingController _ddlIdController = TextEditingController(); // 旧的控制器
  DDLItem? _selectedDDLItem;
  List<DDLItem> _ddlItems = [];
  bool _isFetchingDDLs = false;

  String _aiResponse = '';
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _fetchDDLItems() async {
    setState(() {
      _isFetchingDDLs = true;
      _errorMessage = ''; // 清除之前的错误信息
    });
    try {
      final items = await WebUtils().getAllDDLs();
      // 过滤掉已归档或习惯类型的任务，因为AI规划通常针对具体任务
      final filteredItems =
          items
              .where(
                (item) => !item.isArchived && item.type != DeadlineType.HABIT,
              )
              .toList();
      setState(() {
        _ddlItems = filteredItems;
        if (_ddlItems.isNotEmpty) {
          // _selectedDDLItem = _ddlItems.first; // 默认选择第一个，或保持为null让用户选择
        } else {
          _errorMessage = '没有可用的 DDL 项目进行规划';
        }
        _isFetchingDDLs = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '获取 DDL 列表失败: $e';
        _isFetchingDDLs = false;
      });
    }
  }

  Future<void> _getAIPlan() async {
    if (_selectedDDLItem == null) {
      setState(() {
        _errorMessage = '请选择一个 DDL 项目';
        _aiResponse = '';
      });
      return;
    }

    final int? ddlId = _selectedDDLItem!.id; // 直接使用选中项的ID

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _aiResponse = '';
    });

    try {
      final response = await WebUtils().getAIResponse(ddlId!);
      setState(() {
        _aiResponse = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '获取 AI 规划失败: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchDDLItems(); // 组件初始化时获取DDL列表
  }

  @override
  void dispose() {
    // _ddlIdController.dispose(); // 不再需要
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (_isFetchingDDLs)
              const Center(child: CircularProgressIndicator())
            else if (_errorMessage.isNotEmpty && _ddlItems.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Text(
                  _errorMessage,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else if (_ddlItems.isEmpty && !_isFetchingDDLs)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Text(
                  '没有可供选择的 DDL 项目。请先创建一些任务。',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              DropdownButtonFormField<DDLItem>(
                decoration: const InputDecoration(
                  labelText: '选择 DDL 项目',
                  border: OutlineInputBorder(),
                ),
                value: _selectedDDLItem,
                hint: const Text('请选择一个 DDL'),
                isExpanded: true,
                items:
                    _ddlItems.map<DropdownMenuItem<DDLItem>>((DDLItem item) {
                      return DropdownMenuItem<DDLItem>(
                        value: item,
                        child: Text(
                          item.name.isNotEmpty
                              ? item.name
                              : '未命名 DDL (ID: ${item.id})',
                        ),
                      );
                    }).toList(),
                onChanged: (DDLItem? newValue) {
                  setState(() {
                    _selectedDDLItem = newValue;
                    _errorMessage = ''; // 清除选择时的错误信息
                    _aiResponse = ''; // 清除之前的AI响应
                  });
                },
                validator: (value) => value == null ? '请选择一个项目' : null,
              ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed:
                  _isLoading ||
                          _selectedDDLItem == null ||
                          _isFetchingDDLs ||
                          _ddlItems.isEmpty
                      ? null
                      : _getAIPlan,
              child:
                  _isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('获取 AI 规划'),
            ),
            const SizedBox(height: 16.0),
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (_aiResponse.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: MarkdownBody(
                      data: _aiResponse,
                      styleSheet: MarkdownStyleSheet.fromTheme(
                        Theme.of(context),
                      ).copyWith(
                        blockquoteDecoration: BoxDecoration(
                          color:
                              Theme.of(
                                context,
                              ).colorScheme.surfaceVariant, // 您可以更改为任何您想要的颜色
                          border: Border(
                            left: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 4,
                            ),
                          ),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        blockquotePadding: const EdgeInsets.all(8.0),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
