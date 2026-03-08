import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:notetracker/features/planner/providers/tasks_provider.dart';
import 'package:notetracker/features/planner/screens/task_editor_screen.dart';
import 'package:notetracker/features/planner/screens/timeless_todo_screen.dart';
import 'package:notetracker/features/planner/widgets/task_tile.dart';
import 'package:notetracker/shared/widgets/empty_state.dart';

// Anchor point: page 100000 = today
const int _kTodayPage = 100000;

DateTime _pageToDate(int page) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return today.add(Duration(days: page - _kTodayPage));
}

int _dateToPage(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return _kTodayPage + date.difference(today).inDays;
}

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  late final PageController _pageController;
  bool _pageChanging = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _kTodayPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _jumpToDate(DateTime date) {
    final page = _dateToPage(date);
    _pageChanging = true;
    _pageController.jumpToPage(page);
    _pageChanging = false;
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final theme = Theme.of(context);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isPastDate = selectedDate.isBefore(today);

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onDoubleTap: () {
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const TimelessTodoScreen(),
                transitionDuration: const Duration(milliseconds: 350),
                reverseTransitionDuration: const Duration(milliseconds: 300),
                transitionsBuilder: (_, animation, __, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                        CurvedAnimation(parent: animation, curve: Curves.easeOutExpo),
                      ),
                      child: child,
                    ),
                  );
                },
              ),
            );
          },
          child: const Text('Draft Your Day !'),
        ),
      ),
      body: Column(
        children: [
          // Calendar
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: selectedDate,
            selectedDayPredicate: (day) => isSameDay(day, selectedDate),
            calendarFormat: _calendarFormat,
            availableCalendarFormats: const {
              CalendarFormat.month: 'Month',
              CalendarFormat.week: 'Week',
            },
            onFormatChanged: (f) => setState(() => _calendarFormat = f),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            onDaySelected: (selected, _) {
              final newDate = DateTime(
                selected.year,
                selected.month,
                selected.day,
              );
              ref.read(selectedDateProvider.notifier).state = newDate;
              _jumpToDate(newDate);
            },
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),

          // Swipeable task list
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (page) {
                if (_pageChanging) return;
                final date = _pageToDate(page);
                ref.read(selectedDateProvider.notifier).state = date;
              },
              itemBuilder: (context, page) {
                final date = _pageToDate(page);
                return _DayTaskList(date: date);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: isPastDate
          ? null
          : FloatingActionButton(
              onPressed: () => _openEditor(context),
              child: const Icon(Icons.add),
            ),
    );
  }

  void _openEditor(BuildContext context, {task}) {
    final selectedDate = ref.read(selectedDateProvider);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TaskEditorScreen(
          existingTask: task,
          initialDate: selectedDate,
        ),
      ),
    );
  }
}

/// Renders the task list for a single day, watching providers scoped to that date.
class _DayTaskList extends ConsumerWidget {
  final DateTime date;
  const _DayTaskList({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isPastDate = date.isBefore(today);

    // Derive tasks for this specific date from the global in-memory list
    final tasksAsync = ref.watch(tasksProvider).whenData((allTasks) => allTasks
        .where((t) =>
            DateTime(t.date.year, t.date.month, t.date.day) ==
            DateTime(date.year, date.month, date.day))
        .toList());

    return tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (tasks) {
        if (tasks.isEmpty) {
          return EmptyState(
            icon: Icons.check_circle_outline,
            title: 'No tasks',
            subtitle: isPastDate
                ? 'No tasks were planned for this day.'
                : 'Tap the + button to plan something for this day.',
          );
        }
        final sorted = [...tasks]..sort((a, b) {
            if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
            return a.timeMins.compareTo(b.timeMins);
          });
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 88),
          itemCount: sorted.length,
          itemBuilder: (_, i) => TaskTile(task: sorted[i]),
        );
      },
    );
  }
}
