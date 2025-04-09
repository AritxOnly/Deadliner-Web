import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/ddl_item.dart';
import 'package:frontend/utils/web_utils.dart';

void main() {
  late WebUtils webUtils;
  late int testId; // 用于测试的ID

  setUp(() {
    webUtils = WebUtils();
  });

  group('WebUtils集成测试', () {
    test('isWebAvailable 检查服务器是否可用', () async {
      // 直接调用真实后端
      final result = await webUtils.isWebAvailable();

      // 验证结果 - 预期服务器已启动
      expect(result, true);
    });

    test('getAllDDLs 获取所有DDL项目', () async {
      // 直接从真实后端获取数据
      final result = await webUtils.getAllDDLs();

      // 验证返回的是列表
      expect(result, isA<List<DDLItem>>());

      // 打印获取到的数据以便检查
      print('获取到 ${result.length} 个DDL项目');
      if (result.isNotEmpty) {
        print('第一个项目: ${result[0].name} | ID: ${result[0].id}');
        testId = result[0].id; // 保存第一个项目的ID，用于后续测试
      }
    });

    test('getDDLByID', () async {
      // 假设 testId 是一个有效的ID，从 getAllDDLs 测试中获取
      final result = await webUtils.getDDLById(testId);
      // 验证返回的是一个 DDLItem
      expect(result, isA<DDLItem>());
      // 打印获取到的DDL项目以便检查
      print('获取到 DDL 项目: ${result.name} | ID: ${result.id}');
    });

    // 可以添加更多与真实后端交互的测试
    // 注意：这些测试依赖于后端的状态，可能不稳定
  });
}
