import 'package:flutter/material.dart';

class HabitScreen extends StatefulWidget {
  const HabitScreen({super.key});

  @override
  State<HabitScreen> createState() => _HabitScreenState();
}

class _HabitScreenState extends State<HabitScreen> {
  final List<Map<String, dynamic>> _habitData = [
    {
      'title': '喝水',
      'streak': '7天连击',
      'frequency': '每天一次 · 持续30天',
      'progress': 0,
      'dailyChecks': [true, true, true, true, true, true, true],
    },
    {
      'title': '校园跑',
      'streak': '3天连击',
      'frequency': '共计16次 · 剩余30天',
      'progress': 0.4,
      'dailyChecks': [true, true, true, false, false, false, false],
    },
  ];

  void _handleCheck(int index) {
    setState(() {
      final checks = _habitData[index]['dailyChecks'] as List<bool>;
      final firstFalse = checks.indexWhere((element) => !element);
      if (firstFalse != -1) {
        checks[firstFalse] = true;
      }

      // Update the progress and streak
      final completedDays = checks.where((e) => e).length;
      _habitData[index]['progress'] = completedDays / checks.length;

    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = screenWidth >= 1200 ? 3 : screenWidth >= 800 ? 2 : 1;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.5, // Adjusted child aspect ratio
          ),
          itemCount: _habitData.length,
          itemBuilder: (context, index) => HabitItem(
            title: _habitData[index]['title'],
            streak: _habitData[index]['streak'],
            frequency: _habitData[index]['frequency'],
            progress: _habitData[index]['progress'],
            dailyChecks: _habitData[index]['dailyChecks'],
            onCheckPressed: () => _handleCheck(index),
          ),
        ),
      ),
    );
  }
}

class HabitItem extends StatelessWidget {
  final String title;
  final String streak;
  final String frequency;
  final double progress;
  final List<bool> dailyChecks;
  final VoidCallback onCheckPressed;

  const HabitItem({
    super.key,
    required this.title,
    required this.streak,
    required this.frequency,
    required this.progress,
    required this.dailyChecks,
    required this.onCheckPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 2000, // Increased card height
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderRow(context),
            const SizedBox(height: 4),
            _buildStreakRow(context),
            const SizedBox(height: 4),
            _buildFrequencyRow(context),
            const SizedBox(height: 4),
            _buildDailyDots(context),
            const SizedBox(height: 6),
            _buildMainProgress(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: onCheckPressed,
          icon: Icon(Icons.check_circle, size: 16),
          label: Text(
            dailyChecks.contains(false) ? '打卡' : '今日已打卡',
            style: TextStyle(fontSize: 10),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildStreakRow(BuildContext context) {
    return Text(
      streak,
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    );
  }

  Widget _buildFrequencyRow(BuildContext context) {
    return Text(
      frequency,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: 12,
      ),
    );
  }

  Widget _buildDailyDots(BuildContext context) {
    return SizedBox(
      height: 12,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dailyChecks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) => Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: dailyChecks[index]
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: dailyChecks[index]
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildMainProgress(BuildContext context) {
    return LinearProgressIndicator(
      value: progress,
      minHeight: 4,
      borderRadius: BorderRadius.circular(6),
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
    );
  }
}
