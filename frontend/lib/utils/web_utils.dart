import 'dart:convert';
import 'dart:core';

import 'package:frontend/models/ddl_item.dart';
import 'package:frontend/models/deadline_type.dart';
import 'package:http/http.dart' as http;

class WebUtils {
  // 单例模式
  static final WebUtils _instance = WebUtils._internal(http.Client());
  factory WebUtils() => _instance;
  WebUtils._internal(this.client);

  final String baseDomain = 'localhost';
  final String basePort = '3000';
  final String apiVersion = 'v1';

  String get baseUrl => 'http://$baseDomain:$basePort/api/$apiVersion';

  String get ddlItemsUrl => '$baseUrl/db/items';
  String get registerUrl => '$baseUrl/auth/register';
  String get loginUrl => '$baseUrl/auth/login';

  final http.Client client;
  String? _authToken;

  /// 获取认证头
  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  /// 检查网络是否可用
  /// @return 是否可用
  Future<bool> isWebAvailable() async {
    try {
      // 尝试ping baseUrl检查可用性
      final response = await client.get(Uri.parse(baseUrl));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// 用户注册
  /// @param username 用户名
  /// @param password 密码
  /// @return 是否成功
  Future<bool> register(String username, String password) async {
    try {
      final response = await client.post(
        Uri.parse(registerUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        _authToken = data['token'];
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// 用户登录
  /// @param username 用户名
  /// @param password 密码
  /// @return 是否成功
  Future<bool> login(String username, String password) async {
    try {
      final response = await client.post(
        Uri.parse(loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        _authToken = data['token'];
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// 登出
  void logout() {
    _authToken = null;
  }

  /// 检查是否已登录
  bool isLoggedIn() {
    return _authToken != null;
  }

  /// 拉取所有的DDL
  /// @return DDL列表
  Future<List<DDLItem>> getAllDDLs() async {
    final response = await client.get(
      Uri.parse(ddlItemsUrl),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<DDLItem> ddlList = [];
      final List<dynamic> jsonList = json.decode(response.body);
      for (final Map<String, dynamic> jsonItem in jsonList) {
        ddlList.add(
          DDLItem(
            id: jsonItem['id'],
            name: jsonItem['name'],
            startTime: jsonItem['startTime'],
            endTime: jsonItem['endTime'],
            isCompleted: jsonItem['isCompleted'] ?? false,
            completeTime: jsonItem['completeTime'] ?? '',
            note: jsonItem['note'] ?? '',
            isArchived: jsonItem['isArchived'] ?? false,
            isStared: jsonItem['isStared'] ?? false,
            type: DeadlineType.fromString(jsonItem['type']),
            habitCount: jsonItem['habitCount'] ?? 0,
          ),
        );
      }
      return ddlList;
    } else {
      throw Exception('Failed to load DDLs');
    }
  }

  /// 通过ID获取DDL
  /// @param id DDL的ID
  /// @return DDL
  Future<DDLItem> getDDLById(int id) async {
    final response = await client.get(
      Uri.parse('$ddlItemsUrl/$id'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final dynamic responseData = json.decode(response.body);

      // 检查响应是否为空数组或空对象
      if (responseData is List && responseData.isEmpty) {
        throw Exception('DDL not found');
      }

      if (responseData is Map<String, dynamic>) {
        final Map<String, dynamic> jsonItem = responseData;
        return DDLItem(
          id: jsonItem['id'],
          name: jsonItem['name'],
          startTime: jsonItem['startTime'],
          endTime: jsonItem['endTime'],
          isCompleted: jsonItem['isCompleted'] ?? false,
          completeTime: jsonItem['completeTime'] ?? '',
          note: jsonItem['note'] ?? '',
          isArchived: jsonItem['isArchived'] ?? false,
          isStared: jsonItem['isStared'] ?? false,
          type: DeadlineType.fromString(jsonItem['type']),
          habitCount: jsonItem['habitCount'] ?? 0,
        );
      } else {
        throw Exception('Invalid response format');
      }
    } else {
      throw Exception('Failed to load DDL');
    }
  }

  /// 创建新的DDL
  /// @param name 名称
  /// @param startTime 开始时间
  /// @param endTime 结束时间
  /// @param note 备注
  /// @param type 类型
  /// @return 创建的DDL的ID
  Future<int> createDDL(
    String name,
    String startTime,
    String endTime,
    String note,
    DeadlineType type,
  ) async {
    final response = await client.post(
      Uri.parse(ddlItemsUrl),
      headers: _headers,
      body: json.encode({
        'name': name,
        'startTime': startTime,
        'endTime': endTime,
        'note': note,
        'type': type.toString().split('.').last,
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data['id'];
    } else {
      throw Exception('Failed to create DDL');
    }
  }

  /// 更新DDL
  /// @param id DDL的ID
  /// @param updates 需要更新的字段
  /// @return 是否成功
  Future<bool> updateDDL(int id, Map<String, dynamic> updates) async {
    final response = await client.put(
      Uri.parse('$ddlItemsUrl/$id'),
      headers: _headers,
      body: json.encode(updates),
    );

    return response.statusCode == 200;
  }

  /// 删除DDL
  /// @param id DDL的ID
  /// @return 是否成功
  Future<bool> deleteDDL(int id) async {
    final response = await client.delete(
      Uri.parse('$ddlItemsUrl/$id'),
      headers: _headers,
    );

    return response.statusCode == 200;
  }
}
