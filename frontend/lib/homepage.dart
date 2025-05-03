import 'package:flutter/material.dart';
import 'package:frontend/screens/task_screen.dart';
import 'package:frontend/screens/habit_screen.dart';
import 'package:frontend/screens/overview_screen.dart';
import 'package:frontend/screens/users_page.dart';

class HomepageDestination {
  const HomepageDestination(this.label, this.icon, this.selectedIcon);

  final String label;
  final Widget icon;
  final Widget selectedIcon;
}

const List<HomepageDestination> destinations = <HomepageDestination>[
  HomepageDestination('任务', Icon(Icons.task_outlined), Icon(Icons.task)),
  HomepageDestination('习惯', Icon(Icons.repeat_outlined), Icon(Icons.repeat)),
  HomepageDestination(
    '概览',
    Icon(Icons.pie_chart_outline),
    Icon(Icons.pie_chart),
  ),
  HomepageDestination(
    'AI规划',
    Icon(Icons.rocket_launch_outlined),
    Icon(Icons.rocket_launch),
  ),
  HomepageDestination(
    '设置',
    Icon(Icons.settings_outlined),
    Icon(Icons.settings),
  ),
];

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int screenIndex = 0;
  late bool showNavigationDrawer;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // 控制导航抽屉是否展开的状态
  bool _isDrawerExpanded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    showNavigationDrawer = MediaQuery.of(context).size.width >= 600;
  }

  void _handleScreenChanged(int selectedScreen) {
    setState(() {
      screenIndex = selectedScreen;
    });
  }

  // 根据当前选中的屏幕获取标题
  String _getScreenTitle() {
    return destinations[screenIndex].label;
  }

  // 构建操作按钮
  List<Widget> _buildActions() {
    // 只在任务和习惯页面显示工具栏图标（screenIndex为0或1）
    if (screenIndex == 0 || screenIndex == 1) {
      return [
        IconButton(
          icon: const Icon(Icons.account_circle_outlined),
          tooltip: '用户',
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (context) => const UsersPage()));
          },
        ),
        IconButton(
          icon: const Icon(Icons.search_outlined),
          tooltip: '搜索',
          onPressed: () {
            // TODO: 实现搜索功能
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete_outlined),
          tooltip: '删除',
          onPressed: () {
            // TODO: 实现删除功能
          },
        ),
        IconButton(
          icon: const Icon(Icons.more_vert_outlined),
          tooltip: '更多',
          onPressed: () {
            // TODO: 实现更多功能
          },
        ),
      ];
    } else {
      // 在概览页面不显示工具栏图标
      return [
        IconButton(
          icon: const Icon(Icons.more_vert_outlined),
          tooltip: '更多',
          onPressed: () {
            // TODO: 实现更多功能
          },
        ),
      ];
    }
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      key: _scaffoldKey,
      body: SafeArea(
        child: Row(
          children: [
            NavigationDrawer(
              elevation: 1,
              surfaceTintColor: Theme.of(context).colorScheme.surface,
              onDestinationSelected: _handleScreenChanged,
              selectedIndex: screenIndex,
              children: [
                // 自定义App Logo展示区，不可点击
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(24.0),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 16.0,
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12.0),
                          child: Image.asset(
                            'assets/ic_launcher.png',
                            width: 40.0,
                            height: 40.0,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        Text(
                          'Deadliner',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 28)),
                ...destinations.map((d) {
                  return NavigationDrawerDestination(
                    label: Text(d.label),
                    icon: d.icon,
                    selectedIcon: d.selectedIcon,
                  );
                }),
              ],
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppBar(
                    title: Text(_getScreenTitle()),
                    actions: _buildActions(),
                    centerTitle: false,
                  ),
                  Expanded(child: _buildCurrentScreen()),
                ],
              ),
            ),
          ],
        ),
      ),
      endDrawer: NavigationDrawer(
        onDestinationSelected: _handleScreenChanged,
        selectedIndex: screenIndex,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
            child: Text(
              'Deadliner',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          ...destinations.map((HomepageDestination destination) {
            return NavigationDrawerDestination(
              label: Text(destination.label),
              icon: destination.icon,
              selectedIcon: destination.selectedIcon,
            );
          }),
          const Padding(
            padding: EdgeInsets.fromLTRB(28, 16, 28, 10),
            child: Divider(),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getScreenTitle()),
        actions: _buildActions(),
        centerTitle: false,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Deadliner', style: TextStyle(color: Colors.white)),
            ),
            ...destinations.map((d) {
              return ListTile(
                leading: d.icon,
                title: Text(d.label),
                selected: screenIndex == destinations.indexOf(d),
                onTap: () {
                  _handleScreenChanged(destinations.indexOf(d));
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
      body: _buildCurrentScreen(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: screenIndex,
        onDestinationSelected: _handleScreenChanged,
        destinations:
            destinations.map((d) {
              return NavigationDestination(
                icon: d.icon,
                selectedIcon: d.selectedIcon,
                label: d.label,
              );
            }).toList(),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (screenIndex) {
      case 0:
        return const TaskScreen();
      case 1:
        return const HabitScreen();
      case 2:
        return const OverviewScreen();
      // case 3:
      //   return const SettingsScreen();
      default:
        return const TaskScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return showNavigationDrawer ? _buildDesktopLayout() : _buildMobileLayout();
  }
}
