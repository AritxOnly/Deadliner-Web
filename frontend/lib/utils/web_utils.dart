import 'dart:convert';
import 'dart:core';

import 'package:frontend/models/ddl_item.dart';
import 'package:frontend/models/deadline_type.dart';
import 'package:http/http.dart' as http;

class WebUtils {
  final String baseDomain = 'localhost';
  final String basePort = '3000';
  final String apiVersion = 'v1';

  String get baseUrl => 'http://$baseDomain:$basePort/api/$apiVersion';

  String get ddlItemsUrl => '$baseUrl/db/items';
  String get registerUrl => '$baseUrl/auth/register';
  String get loginUrl => '$baseUrl/auth/login';

  final http.Client client;

  WebUtils({http.Client? client}) : client = client ?? http.Client();

  // 协程函数，需要在另一个线程中调用

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

  /// 拉取所有的DDL
  /// @return DDL列表
  Future<List<DDLItem>> getAllDDLs() async {
    final response = await client.get(Uri.parse(ddlItemsUrl));
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
            isCompleted: jsonItem['isCompleted'],
            completeTime: jsonItem['completeTime'],
            note: jsonItem['note'],
            isArchived: jsonItem['isArchived'],
            isStared: jsonItem['isStared'],
            type: DeadlineType.fromString(jsonItem['type']),
            habitCount: jsonItem['habitCount'],
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
    final response = await client.get(Uri.parse('$ddlItemsUrl/$id'));
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonItem = json.decode(response.body);
      return DDLItem(
        id: jsonItem['id'],
        name: jsonItem['name'],
        startTime: jsonItem['startTime'],
        endTime: jsonItem['endTime'],
        isCompleted: jsonItem['isCompleted'],
        completeTime: jsonItem['completeTime'],
        note: jsonItem['note'],
        isArchived: jsonItem['isArchived'],
        isStared: jsonItem['isStared'],
        type: DeadlineType.fromString(jsonItem['type']),
        habitCount: jsonItem['habitCount'],
      );
    } else {
      throw Exception('Failed to load DDL');
    }
  }
}
