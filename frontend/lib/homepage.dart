import 'package:flutter/material.dart';
import 'package:frontend/screens/ai_screen.dart';
import 'package:frontend/screens/setting_screen.dart';
import 'package:frontend/screens/task_screen.dart';
import 'package:frontend/screens/habit_screen.dart';
import 'package:frontend/screens/overview_screen.dart';
import 'package:frontend/screens/users_page.dart';
import 'dart:math';

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
  final GlobalKey<TaskScreenState> _taskScreenKey =
      GlobalKey<TaskScreenState>();
  late String _randomQuote;
  bool _isScreenOverlayVisible = false;
  int _targetScreenIndex = 0;

  // State for TaskScreen multi-select mode
  bool _isTaskMultiSelectMode = false;
  int _taskSelectionCount = 0;

  // State for Search
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _motivationQuotes = [
    'Deadline 在追杀你！快跑💨',
    '任务完成度：1% → 99%🤯',
    '再拖？DDL要咬人了！🦖',
    '你离「完成」只差一个「提交」🚀',
    '提醒：别躺了，起来肝！🛏️→💻',
    '「先玩5分钟」→ 5小时😱',
    '你的待办列表：📜🔥（烧起来了)',
    '今日任务：活着 + 搞定它💪',
    'DDL越近，手速越快⚡',
    '「我明天做」→ 经典flag🚩',
    '任务完成 ✔️ 奖励：睡大觉！😴',
    '检测到：你在焦虑🌀',
    '别刷电脑了！💻→❌',
    '「最后亿分钟」⌛',
    '任务堆积如山？愚公移山！⛰️',
    'DDL是你的敌人？不，是动力！💥',
    '「我好了」→「我装的」😏',
    '今日成就：没放弃！🏆',
    '建议：先做最难的！🎯',
    '完成它！然后大喊：Next！🎤',
  ];

  // 控制导航抽屉是否展开的状态
  bool _isDrawerExpanded = false;

  @override
  void initState() {
    super.initState();
    _selectRandomQuote();
    _targetScreenIndex = screenIndex; // Initialize _targetScreenIndex
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectRandomQuote() {
    final random = Random();
    _randomQuote = _motivationQuotes[random.nextInt(_motivationQuotes.length)];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    showNavigationDrawer = MediaQuery.of(context).size.width >= 600;
  }

  void _handleScreenChanged(int selectedScreen) {
    if (selectedScreen == screenIndex && !_isScreenOverlayVisible) return;

    setState(() {
      _targetScreenIndex = selectedScreen;
      _isScreenOverlayVisible = true;
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          screenIndex = _targetScreenIndex;
          // Start fading out the overlay after the content is set to switch
          // The actual fade out is handled by AnimatedOpacity's reaction to _isScreenOverlayVisible changing
        });
        // Delayed hiding of overlay to allow fade-out animation
        Future.delayed(const Duration(milliseconds: 50), () {
          // Small delay before triggering fade out
          if (mounted) {
            setState(() {
              _isScreenOverlayVisible = false;
            });
          }
        });
      }
    });
  }

  // 根据当前选中的屏幕获取标题
  String _getScreenTitle() {
    return destinations[screenIndex].label;
  }

  void _handleTaskMultiSelectModeChanged(
    bool isMultiSelect,
    int selectionCount,
  ) {
    if (mounted) {
      setState(() {
        _isTaskMultiSelectMode = isMultiSelect;
        _taskSelectionCount = selectionCount;
      });
    }
  }

  // 构建操作按钮
  List<Widget> _buildActions() {
    // 只在任务页面 (screenIndex为0) 并且是桌面布局时，根据多选模式显示不同按钮
    if (screenIndex == 0 && showNavigationDrawer) {
      // Assuming showNavigationDrawer implies desktop/wider layout
      if (_isTaskMultiSelectMode) {
        return [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: '退出多选',
            onPressed: () {
              _taskScreenKey.currentState?.handleRequestToggleMultiSelectMode();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '删除选中',
            onPressed:
                _taskSelectionCount > 0
                    ? () {
                      _taskScreenKey.currentState
                          ?.handleRequestDeleteSelected();
                    }
                    : null,
          ),
        ];
      } else {
        return [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: '用户',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const UsersPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search_outlined),
            tooltip: '搜索',
            onPressed: () {
              setState(() {
                _isSearching = true;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: '多选删除',
            onPressed: () {
              _taskScreenKey.currentState?.handleRequestToggleMultiSelectMode();
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
      }
    } else if (screenIndex == 1) {
      // Habit screen
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
          tooltip: '搜索 (不可用)',
          onPressed: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('搜索功能仅在任务页面可用')));
          },
        ),
        IconButton(
          icon: const Icon(Icons.more_vert_outlined),
          tooltip: '更多',
          onPressed: () {
            // TODO: Implement more options
          },
        ),
      ];
    } else {
      // Overview, AI, Settings screens
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
          tooltip: '搜索 (不可用)',
          onPressed: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('搜索功能仅在任务页面可用')));
          },
        ),
        IconButton(
          icon: const Icon(Icons.more_vert_outlined),
          tooltip: '更多',
          onPressed: () {
            // TODO: Implement more options
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
                // Display random quote
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28.0,
                    vertical: 16.0,
                  ),
                  child: Text(
                    _randomQuote,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                    textScaleFactor: 1.1,
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
                    title:
                        _isSearching && screenIndex == 0
                            ? TextField(
                              controller: _searchController,
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: '搜索任务...',
                                border: InputBorder.none,
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    setState(() {
                                      _isSearching = false;
                                      _searchController.clear();
                                    });
                                  },
                                ),
                              ),
                              onChanged: (query) {
                                // setState(() {
                                //   _searchQuery = query;
                                // });
                              },
                            )
                            : AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (
                                Widget child,
                                Animation<double> animation,
                              ) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                              child: Text(
                                _getScreenTitle(),
                                key: ValueKey<String>(
                                  _getScreenTitle(),
                                ), // Use title string as key
                              ),
                            ),
                    actions:
                        _isSearching && screenIndex == 0
                            ? [
                              // IconButton(
                              //   icon: const Icon(Icons.close),
                              //   tooltip: '关闭搜索',
                              //   onPressed: () {
                              //     setState(() {
                              //       _isSearching = false;
                              //       _searchController.clear();
                              //     });
                              //   },
                              // ),
                            ]
                            : _buildActions(),
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
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: Text(
            _getScreenTitle(),
            key: ValueKey<String>(_getScreenTitle()), // Use title string as key
          ),
        ),
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
    Widget screen;
    switch (screenIndex) {
      case 0:
        screen = TaskScreen(
          key: _taskScreenKey, // Assign the key
          onMultiSelectModeChanged: _handleTaskMultiSelectModeChanged,
          searchQuery: _searchQuery,
          // requestDeleteSelected and requestToggleMultiSelectMode are handled by AppBar actions calling _taskScreenKey.currentState methods
        );
        break;
      case 1:
        screen = const HabitScreen();
        break;
      case 2:
        screen = const OverviewScreen();
        break;
      case 3:
        screen = const AIScreen();
        break;
      case 4:
        screen = const SettingsScreen();
        break;
      default:
        screen = TaskScreen(
          searchQuery: _searchQuery,
        ); // Pass searchQuery here too as a fallback
        break;
    }

    Widget screenSwitcher = AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: SizedBox(key: ValueKey<int>(screenIndex), child: screen),
    );

    return Stack(
      children: [
        screenSwitcher,
        IgnorePointer(
          ignoring:
              !_isScreenOverlayVisible, // When overlay is visible, don't ignore pointer events for the overlay itself, but allow events to pass through when it's not visible.
          child: AnimatedOpacity(
            opacity: _isScreenOverlayVisible ? 1.0 : 0.0,
            duration: const Duration(
              milliseconds: 200,
            ), // Overlay fade-out duration
            child: Container(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
            ), // Added transparency to see content below
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return showNavigationDrawer ? _buildDesktopLayout() : _buildMobileLayout();
  }
}
