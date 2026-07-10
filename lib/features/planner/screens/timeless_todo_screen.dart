import 'dart:ui' show ImageFilter;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:notetracker/features/planner/models/timeless_todo.dart';
import 'package:notetracker/features/planner/providers/category_order_provider.dart';
import 'package:notetracker/features/planner/providers/timeless_todos_provider.dart';
import 'package:notetracker/shared/widgets/empty_state.dart';

class TimelessTodoScreen extends ConsumerStatefulWidget {
  const TimelessTodoScreen({super.key});

  @override
  ConsumerState<TimelessTodoScreen> createState() => _TimelessTodoScreenState();
}

class _TimelessTodoScreenState extends ConsumerState<TimelessTodoScreen> {
  // Fraction of the viewport each category card occupies, leaving a small peek
  // of the neighbouring columns for a carousel feel.
  static const double _viewportFraction = 0.9;

  // Finger distance (px) to advance one whole card while scrubbing the dots.
  static const double _dragStep = 26.0;

  late final PageController _boardController;
  final FocusNode _focusNode = FocusNode(debugLabel: 'category-carousel-dots');

  bool _dragging = false;
  int _currentPage = 0;
  int _pageCount = 0;

  // Accumulated dot-drag distance and the page the drag started from, used to
  // step through whole cards without showing the in-between slide.
  double _dragAccum = 0;
  int _dragStartPage = 0;

  @override
  void initState() {
    super.initState();
    _boardController = PageController(viewportFraction: _viewportFraction);
    _boardController.addListener(_onControllerChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _boardController.removeListener(_onControllerChanged);
    _boardController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!_boardController.hasClients || _pageCount == 0) return;
    final p = (_boardController.page ?? 0).round().clamp(0, _pageCount - 1);
    if (p != _currentPage) setState(() => _currentPage = p);
  }

  void _onFocusChanged() => setState(() {});

  // Continuous page position (may be fractional mid-scroll/drag).
  double get _page {
    if (!_boardController.hasClients ||
        !_boardController.position.hasContentDimensions) {
      return _currentPage.toDouble();
    }
    return _boardController.page ?? _currentPage.toDouble();
  }

  void _goBy(int direction) {
    if (!_boardController.hasClients) return;
    final target = (_currentPage + direction).clamp(0, _pageCount - 1);
    _boardController.animateToPage(
      target,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _onDotsDragStart() {
    _focusNode.requestFocus();
    _dragAccum = 0;
    _dragStartPage = _currentPage;
    setState(() => _dragging = true);
  }

  // Dragging the dots steps through whole cards: every [_dragStep] px of finger
  // movement jumps straight to the next/previous card. Using jumpToPage means
  // the card just appears — no sliding transition between cards is shown.
  void _onDotsDragUpdate(DragUpdateDetails d, double pageWidth) {
    if (!_boardController.hasClients) return;
    _dragAccum += d.delta.dx;
    final steps = (_dragAccum / _dragStep).round();
    final target = (_dragStartPage + steps).clamp(0, _pageCount - 1);
    final current = (_boardController.page ?? _currentPage).round();
    if (target != current) {
      _boardController.jumpToPage(target);
    }
  }

  void _onDotsDragEnd(double velocity) {
    setState(() => _dragging = false);
  }

  @override
  Widget build(BuildContext context) {
    final todosAsync = ref.watch(timelessTodosProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        titleSpacing: 20,
        title: Text(
          'DayDraft',
          style: GoogleFonts.baloo2(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      body: todosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (todos) {
          if (todos.isEmpty) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const EmptyState(
                  icon: Icons.flash_on,
                  title: 'No timeless tasks',
                  subtitle: 'Add tasks you need to do ASAP!',
                ),
                FilledButton.icon(
                  onPressed: () => showTimelessTodoSheet(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Add your first task'),
                ),
                const SizedBox(height: 48),
              ],
            );
          }
          return _buildBoard(context, todos);
        },
      ),
    );
  }

  Widget _buildBoard(BuildContext context, List<TimelessTodo> todos) {
    // Group todos by category, preserving stable first-seen order for
    // categories the user hasn't explicitly ordered yet.
    final grouped = <String, List<TimelessTodo>>{};
    for (final t in todos) {
      grouped.putIfAbsent(t.category, () => []).add(t);
    }
    final present = grouped.keys.toList();
    final ordered = ref.read(categoryOrderProvider.notifier).orderedFor(present);
    // Watch so column order rebuilds when the saved order changes.
    ref.watch(categoryOrderProvider);

    _pageCount = ordered.length;
    // Keep the active page in range if a category disappeared.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_boardController.hasClients || _pageCount == 0) return;
      final maxPage = _pageCount - 1;
      final current = (_boardController.page ?? 0).round();
      if (current > maxPage) _boardController.jumpToPage(maxPage);
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final pageWidth = constraints.maxWidth * _viewportFraction;
        return Column(
          children: [
            Expanded(
              child: ScrollConfiguration(
                // Allow mouse dragging of the columns on desktop/web.
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.trackpad,
                    PointerDeviceKind.stylus,
                  },
                ),
                child: PageView.builder(
                  controller: _boardController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: ordered.length,
                  itemBuilder: (context, index) {
                    final category = ordered[index];
                    final items = [...grouped[category]!]..sort((a, b) {
                        if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
                        // Soonest due first among outstanding tasks.
                        return a.dueAt.compareTo(b.dueAt);
                      });
                    return Padding(
                      key: ValueKey(category),
                      // Slightly shorter card + gap above the pagination dots.
                      padding: const EdgeInsets.fromLTRB(8, 16, 8, 20),
                      child: _CategoryColumn(
                        category: category,
                        todos: items,
                      ),
                    );
                  },
                ),
              ),
            ),
            // Lift the dots clear of the bottom system-gesture area so they
            // don't trigger the phone's assistant/navigation.
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 18),
                child: _PaginationDots(
                  count: ordered.length,
                  controller: _boardController,
                  pageOf: () => _page,
                  currentPage: _currentPage,
                  dragging: _dragging,
                  focusNode: _focusNode,
                  onDragStart: _onDotsDragStart,
                  onDragUpdate: (d) => _onDotsDragUpdate(d, pageWidth),
                  onDragEnd: _onDotsDragEnd,
                  onArrow: _goBy,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A single swipeable category column: header with a completed/incomplete
/// stats capsule, a vertical list of its tasks, and a quick-add button.
class _CategoryColumn extends ConsumerWidget {
  final String category;
  final List<TimelessTodo> todos;

  const _CategoryColumn({
    required this.category,
    required this.todos,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final doneCount = todos.where((t) => t.isDone).length;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        // Thin, subtle shadow.
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        // Frosted-glass backdrop blur behind the card body.
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              // Solid white card body.
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFFE6E6E6),
                width: 0.6,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Gradient header with an accent bar, title, and stats capsule.
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 15, 12, 15),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      // Accent bar.
                      Container(
                        width: 4,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          category,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.lexend(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Completed / total stats capsule.
                      _StatsCapsule(
                        done: doneCount,
                        total: todos.length,
                      ),
                    ],
                  ),
                ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: todos.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _TimelessTodoTile(todo: todos[i]),
              ),
            ),
            const Divider(
              height: 1,
              thickness: 0.5,
              color: Color(0xFFCFCFCF),
            ),
            // Quick-add straight into this category.
            TextButton.icon(
              onPressed: () => showTimelessTodoSheet(
                context,
                ref,
                initialCategory: category,
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add task'),
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                shape: const RoundedRectangleBorder(),
              ),
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Capsule showing completed-of-total task counts for a category (e.g. 2/3),
/// with a green tick. Red-bordered pill.
class _StatsCapsule extends StatelessWidget {
  final int done;
  final int total;

  const _StatsCapsule({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD2042D), width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle,
            size: 14,
            color: Color(0xFF2E9E4F), // green tick
          ),
          const SizedBox(width: 5),
          Text(
            '$done/$total',
            style: GoogleFonts.lexend(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3A3A3A),
            ),
          ),
        ],
      ),
    );
  }
}

/// Instagram-style interactive pagination dots. Reads the shared
/// [PageController] so the dots and cards stay perfectly in sync, and lets the
/// user scrub the carousel by dragging horizontally across the dots.
class _PaginationDots extends StatelessWidget {
  final int count;
  final PageController controller;
  final double Function() pageOf;
  final int currentPage;
  final bool dragging;
  final FocusNode focusNode;
  final VoidCallback onDragStart;
  final ValueChanged<DragUpdateDetails> onDragUpdate;
  final ValueChanged<double> onDragEnd;
  final ValueChanged<int> onArrow;

  const _PaginationDots({
    required this.count,
    required this.controller,
    required this.pageOf,
    required this.currentPage,
    required this.dragging,
    required this.focusNode,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onArrow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Single card: nothing to paginate, dragging disabled.
    if (count <= 1) return const SizedBox(height: 28);

    final active = theme.colorScheme.primary;
    final inactive = theme.colorScheme.outline;

    final dots = AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final page = pageOf();
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < count; i++)
              _buildDot(page, i, active, inactive),
          ],
        );
      },
    );

    return Semantics(
      container: true,
      label: 'Category pagination',
      value: 'Category ${currentPage + 1} of $count',
      hint: 'Drag or use the left and right arrow keys to change category',
      child: Focus(
        focusNode: focusNode,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent || event is KeyRepeatEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              onArrow(-1);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              onArrow(1);
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: MouseRegion(
          cursor: dragging
              ? SystemMouseCursors.grabbing
              : SystemMouseCursors.grab,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: focusNode.requestFocus,
            onHorizontalDragStart: (_) => onDragStart(),
            onHorizontalDragUpdate: onDragUpdate,
            onHorizontalDragEnd: (d) => onDragEnd(d.primaryVelocity ?? 0),
            // No border/background — kept clean. Larger touch target height.
            child: Container(
              height: 32,
              alignment: Alignment.center,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: dots,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDot(double page, int i, Color active, Color inactive) {
    final dist = (page - i).abs();
    final t = (1 - dist).clamp(0.0, 1.0); // 1 at the active dot, fades out
    final diameter = 6.0 + 4.0 * t; // 6 → 10 px
    final color = Color.lerp(inactive, active, t) ?? inactive;
    return Semantics(
      label: 'Category ${i + 1}',
      selected: i == currentPage,
      child: Container(
        width: 10,
        height: 12,
        alignment: Alignment.center,
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _TimelessTodoTile extends ConsumerWidget {
  final TimelessTodo todo;
  const _TimelessTodoTile({required this.todo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const titleColor = Color(0xFF212121);
    const doneColor = Color(0xFF9E9E9E);

    final bg = todo.isDone ? const Color(0xFFF5F5F5) : Colors.white;
    // Thin, soft borders: light green when done, light red when pending.
    final borderColor = todo.isDone
        ? const Color(0xFFA5D6A7) // light green
        : const Color(0xFFFFB3BA); // light red

    // Task title font restored to the original Lexend styling.
    final titleStyle = GoogleFonts.lexend(
      fontSize: 15,
      fontWeight: FontWeight.w300,
      color: todo.isDone ? doneColor : titleColor,
      decoration: todo.isDone ? TextDecoration.lineThrough : null,
      decorationColor: doneColor,
    );

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          // Tap toggles completion; long-press opens the options menu.
          onTap: () => ref.read(timelessTodosProvider.notifier).toggleDone(todo),
          onLongPress: () => _showOptionsMenu(context, ref),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF9E9E9E),
                      width: 1.4,
                    ),
                    color: todo.isDone
                        ? const Color(0xFF9E9E9E)
                        : Colors.transparent,
                  ),
                  child: todo.isDone
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(todo.title, style: titleStyle)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDue(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    final diff = day.difference(today).inDays;
    final time = DateFormat.jm().format(dt); // e.g. 11:00 PM
    if (diff == 0) return 'Today · $time';
    if (diff == 1) return 'Tomorrow · $time';
    if (diff == -1) return 'Yesterday · $time';
    return '${DateFormat('MMM d').format(dt)} · $time';
  }

  void _showOptionsMenu(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(timelessTodosProvider.notifier);
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
              child: Text(
                todo.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                '${todo.category} · ${_formatDue(todo.dueAt)}',
                style: theme.textTheme.bodySmall,
              ),
            ),
            const Divider(height: 1),
            _SheetAction(
              icon: todo.isDone
                  ? Icons.radio_button_unchecked
                  : Icons.check_circle_outline,
              label: todo.isDone ? 'Mark as not done' : 'Mark as done',
              onTap: () {
                Navigator.of(ctx).pop();
                notifier.toggleDone(todo);
              },
            ),
            _SheetAction(
              icon: Icons.edit_outlined,
              label: 'Edit',
              onTap: () {
                Navigator.of(ctx).pop();
                showTimelessTodoSheet(context, ref, existing: todo);
              },
            ),
            _SheetAction(
              icon: Icons.delete_outline,
              label: 'Delete',
              destructive: true,
              onTap: () {
                Navigator.of(ctx).pop();
                _confirmDelete(context, notifier);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, TimelessTodosNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('Are you sure you want to delete "${todo.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFFE53935)),
            onPressed: () {
              Navigator.of(ctx).pop();
              notifier.deleteTodo(todo.id!);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        destructive ? const Color(0xFFE53935) : Theme.of(context).colorScheme.onSurface;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color)),
      onTap: onTap,
    );
  }
}

/// Shows the polished bottom-sheet form for adding or editing a timeless task,
/// with title, category, and a due date + time (time defaults to 11:00 PM).
Future<void> showTimelessTodoSheet(
  BuildContext context,
  WidgetRef ref, {
  TimelessTodo? existing,
  String? initialCategory,
}) {
  final existingCategories = <String>{
    ...?ref.read(timelessTodosProvider).value?.map((t) => t.category),
  }.toList()
    ..sort();

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _TimelessTodoSheet(
      existing: existing,
      initialCategory: initialCategory,
      existingCategories: existingCategories,
      onSave: (title, category, dueAt) {
        final notifier = ref.read(timelessTodosProvider.notifier);
        if (existing != null) {
          notifier.saveTodo(existing.copyWith(
              title: title, category: category, dueAt: dueAt));
        } else {
          notifier.saveTodo(
              TimelessTodo(title: title, category: category, dueAt: dueAt));
        }
      },
    ),
  );
}

class _TimelessTodoSheet extends StatefulWidget {
  final TimelessTodo? existing;
  final String? initialCategory;
  final List<String> existingCategories;
  final void Function(String title, String category, DateTime dueAt) onSave;

  const _TimelessTodoSheet({
    required this.existing,
    required this.initialCategory,
    required this.existingCategories,
    required this.onSave,
  });

  @override
  State<_TimelessTodoSheet> createState() => _TimelessTodoSheetState();
}

class _TimelessTodoSheetState extends State<_TimelessTodoSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _categoryController;
  late DateTime _dueDate;
  late TimeOfDay _dueTime;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existing?.title ?? '');
    _categoryController = TextEditingController(
      text: widget.existing?.category ??
          widget.initialCategory ??
          (widget.existingCategories.isNotEmpty
              ? widget.existingCategories.first
              : TimelessTodo.defaultCategory),
    );
    final due = widget.existing?.dueAt ?? TimelessTodo.defaultDueAt();
    _dueDate = DateTime(due.year, due.month, due.day);
    _dueTime = TimeOfDay(hour: due.hour, minute: due.minute);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  DateTime get _combinedDue => DateTime(
        _dueDate.year,
        _dueDate.month,
        _dueDate.day,
        _dueTime.hour,
        _dueTime.minute,
      );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime,
    );
    if (picked != null) setState(() => _dueTime = picked);
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    final category = _categoryController.text.trim().isEmpty
        ? TimelessTodo.defaultCategory
        : _categoryController.text.trim();
    Navigator.of(context).pop();
    widget.onSave(title, category, _combinedDue);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.existing != null;
    // Lift the sheet above the keyboard.
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Edit Task' : 'New Task',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _titleController,
                autofocus: !isEditing,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Task',
                  hintText: 'What needs to be done?',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _categoryController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  hintText: 'e.g. Work, Personal, Shopping',
                  prefixIcon: Icon(Icons.folder_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              if (widget.existingCategories.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in widget.existingCategories)
                      ActionChip(
                        label: Text(c),
                        onPressed: () =>
                            setState(() => _categoryController.text = c),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              Text('Due', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _PickerField(
                      icon: Icons.event_outlined,
                      label: DateFormat('EEE, MMM d').format(_dueDate),
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PickerField(
                      icon: Icons.access_time,
                      label: _dueTime.format(context),
                      onTap: _pickTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(110, 48),
                    ),
                    child: Text(isEditing ? 'Save' : 'Add task'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerField({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
