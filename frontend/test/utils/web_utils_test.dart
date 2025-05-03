import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/ddl_item.dart';
import 'package:frontend/models/deadline_type.dart';
import 'package:frontend/utils/web_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late WebUtils webUtils;
  late int testDdlId; // 用于存储测试过程中创建的DDL项目ID
  final testUsername = 'testuser_${DateTime.now().millisecondsSinceEpoch}';
  final testPassword = 'password123';

  // 确保 Flutter 插件系统初始化
  TestWidgetsFlutterBinding.ensureInitialized();
  // 给 shared_preferences 注入一个空的内存实现
  SharedPreferences.setMockInitialValues(<String, Object>{});

  setUp(() async {
    webUtils = WebUtils();
  });

  group('WebUtils基础功能测试', () {
    test('isWebAvailable 检查服务器是否可用', () async {
      // 直接调用真实后端
      final result = await webUtils.isWebAvailable();

      // 验证结果 - 预期服务器已启动
      expect(result, true, reason: '服务器应该处于可用状态');
    });

    test('URL构建测试', () {
      expect(webUtils.baseUrl, 'http://localhost:3000/api/v1');
      expect(webUtils.ddlItemsUrl, 'http://localhost:3000/api/v1/db/items');
      expect(
        webUtils.registerUrl,
        'http://localhost:3000/api/v1/auth/register',
      );
      expect(webUtils.loginUrl, 'http://localhost:3000/api/v1/auth/login');
    });
  });

  group('WebUtils认证功能测试', () {
    test('注册新用户', () async {
      final result = await webUtils.register(testUsername, testPassword);
      expect(result, true, reason: '注册应该成功');
      expect(webUtils.isLoggedIn(), true, reason: '注册后应该自动登录');
    });

    test('登出功能', () {
      webUtils.logout();
      expect(webUtils.isLoggedIn(), false, reason: '登出后应该处于未登录状态');
    });

    test('登录功能', () async {
      final result = await webUtils.login(testUsername, testPassword);
      expect(result, true, reason: '使用正确的凭据登录应该成功');
      expect(webUtils.isLoggedIn(), true, reason: '登录后应该处于已登录状态');
    });

    test('使用错误凭据登录', () async {
      webUtils.logout(); // 先登出
      final result = await webUtils.login('wronguser', 'wrongpass');
      expect(result, false, reason: '使用错误的凭据登录应该失败');
      expect(webUtils.isLoggedIn(), false, reason: '登录失败后应该仍处于未登录状态');
    });
  });

  group('WebUtils DDL操作测试', () {
    setUp(() async {
      // 确保已登录
      if (!webUtils.isLoggedIn()) {
        await webUtils.login(testUsername, testPassword);
      }
    });

    test('创建DDL项目', () async {
      final name = '测试DDL项目 ${DateTime.now().millisecondsSinceEpoch}';
      final startTime = '2023-01-01T00:00:00Z';
      final endTime = '2023-12-31T23:59:59Z';
      final note = '这是一个测试笔记';
      final type = DeadlineType.TASK;

      testDdlId = await webUtils.createDDL(
        name,
        startTime,
        endTime,
        note,
        type,
      );

      expect(testDdlId, isA<int>(), reason: '创建DDL后应返回有效的ID');
      expect(testDdlId > 0, true, reason: 'DDL ID应该是正数');
    });

    test('获取所有DDL项目', () async {
      final ddlList = await webUtils.getAllDDLs();

      expect(ddlList, isA<List<DDLItem>>(), reason: '应返回DDLItem列表');
      expect(ddlList.isNotEmpty, true, reason: '列表不应为空，因为我们刚刚创建了一个项目');

      // 验证是否包含我们刚创建的项目
      final createdItem = ddlList.firstWhere(
        (item) => item.id == testDdlId,
        orElse: () => throw Exception('未找到刚创建的DDL项目'),
      );

      expect(createdItem.id, testDdlId);
    });

    test('通过ID获取DDL项目', () async {
      final ddlItem = await webUtils.getDDLById(testDdlId);

      expect(ddlItem, isA<DDLItem>(), reason: '应返回DDLItem对象');
      expect(ddlItem.id, testDdlId, reason: '返回项目的ID应与请求的ID匹配');
    });

    test('更新DDL项目', () async {
      final updates = {'name': '已更新的DDL项目', 'note': '已更新的笔记', 'isStared': true};

      final updateResult = await webUtils.updateDDL(testDdlId, updates);
      expect(updateResult, true, reason: '更新操作应该成功');

      // 验证更新是否生效
      final updatedItem = await webUtils.getDDLById(testDdlId);
      expect(updatedItem.name, '已更新的DDL项目');
      expect(updatedItem.note, '已更新的笔记');
      expect(updatedItem.isStared, true);
    });

    test('删除DDL项目', () async {
      final deleteResult = await webUtils.deleteDDL(testDdlId);
      expect(deleteResult, true, reason: '删除操作应该成功');

      // 尝试获取已删除的项目应该抛出异常
      expect(
        () async => await webUtils.getDDLById(testDdlId),
        throwsException,
        reason: '尝试获取已删除的项目应该抛出异常',
      );
    });
  });
}
