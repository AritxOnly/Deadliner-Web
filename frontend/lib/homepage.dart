import 'package:flutter/material.dart';
import 'package:frontend/screens/task_screen.dart';

class ExampleDestination {
  const ExampleDestination(this.label, this.icon, this.selectedIcon);

  final String label;
  final Widget icon;
  final Widget selectedIcon;
}

const List<ExampleDestination> destinations = <ExampleDestination>[
  ExampleDestination('任务', Icon(Icons.task_outlined), Icon(Icons.task)),
  ExampleDestination('习惯', Icon(Icons.repeat_outlined), Icon(Icons.repeat)),
  ExampleDestination('设置', Icon(Icons.settings_outlined), Icon(Icons.settings)),
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

  Widget _buildDesktopLayout() {
    var count = 0;
    return Scaffold(
      key: _scaffoldKey,
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              minWidth: 56,
              destinations: destinations.map((d) {
                return NavigationRailDestination(
                  label: Text(d.label),
                  icon: d.icon,
                  selectedIcon: d.selectedIcon,
                );
              }).toList(),
              selectedIndex: screenIndex,
              onDestinationSelected: _handleScreenChanged,
            ),
            const VerticalDivider(thickness: 1, width: 1),
            TaskScreen()
          ],
        ),
      ),
      endDrawer: NavigationDrawer(
        onDestinationSelected: _handleScreenChanged,
        selectedIndex: screenIndex,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
            child: Text('Deadliner', style: Theme.of(context).textTheme.headlineMedium),
          ),
          ...destinations.map((ExampleDestination destination) {
            return NavigationDrawerDestination(
              label: Text(destination.label),
              icon: destination.icon,
              selectedIcon: destination.selectedIcon,
            );
          }),
          const Padding(padding: EdgeInsets.fromLTRB(28, 16, 28, 10), child: Divider()),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
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
      body: Center(
        child: Text('当前页面: ${destinations[screenIndex].label}'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: screenIndex,
        onDestinationSelected: _handleScreenChanged,
        destinations: destinations.map((d) {
          return NavigationDestination(
            icon: d.icon,
            selectedIcon: d.selectedIcon,
            label: d.label,
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return showNavigationDrawer ? _buildDesktopLayout() : _buildMobileLayout();
  }
}
