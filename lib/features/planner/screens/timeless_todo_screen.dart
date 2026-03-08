import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notetracker/features/planner/models/timeless_todo.dart';
import 'package:notetracker/features/planner/providers/timeless_todos_provider.dart';
import 'package:notetracker/shared/widgets/empty_state.dart';

class TimelessTodoScreen extends ConsumerStatefulWidget {
  const TimelessTodoScreen({super.key});

  @override
  ConsumerState<TimelessTodoScreen> createState() => _TimelessTodoScreenState();
}

class _TimelessTodoScreenState extends ConsumerState<TimelessTodoScreen> {
  @override
  Widget build(BuildContext context) {
    final todosAsync = ref.watch(timelessTodosProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Text('Do It Asap!'),
        ),
      ),
      body: todosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (todos) {
          if (todos.isEmpty) {
            return const EmptyState(
              icon: Icons.flash_on,
              title: 'No timeless tasks',
              subtitle: 'Tap + to add tasks you need to do ASAP!',
            );
          }
          // Sort: incomplete first, then by creation date
          final sorted = [...todos]..sort((a, b) {
              if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
              return b.createdAt.compareTo(a.createdAt);
            });
          return MasonryGridView.count(
            padding: const EdgeInsets.only(top: 16, bottom: 88, left: 12, right: 12),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            itemCount: sorted.length,
            itemBuilder: (_, i) => _TimelessTodoTile(todo: sorted[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, {TimelessTodo? existing}) {
    final controller = TextEditingController(text: existing?.title ?? '');
    final isEditing = existing != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Edit Task' : 'Add Task'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'What needs to be done?',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (_) => _saveTodo(ctx, controller.text, existing),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _saveTodo(ctx, controller.text, existing),
            child: Text(isEditing ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _saveTodo(BuildContext ctx, String title, TimelessTodo? existing) {
    if (title.trim().isEmpty) return;
    Navigator.of(ctx).pop();

    final notifier = ref.read(timelessTodosProvider.notifier);
    if (existing != null) {
      notifier.saveTodo(existing.copyWith(title: title.trim()));
    } else {
      notifier.saveTodo(TimelessTodo(title: title.trim()));
    }
  }
}

class _TimelessTodoTile extends ConsumerWidget {
  final TimelessTodo todo;
  const _TimelessTodoTile({required this.todo});

  // Black and white colors
  static const List<Color> _cardColors = [
    Color(0xFFFFFFFF), // White
  ];

  Color _getCardColor() {
    if (todo.isDone) return const Color(0xFFF5F5F5);
    final index = (todo.id ?? 0) % _cardColors.length;
    return _cardColors[index];
  }

  Color _getBorderColor() {
    if (todo.isDone) return const Color(0xFFBDBDBD);
    return const Color(0xFFB0B0B0); // Light grey border
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(timelessTodosProvider.notifier);

    const titleColor = Color(0xFF212121);
    const doneColor = Color(0xFF9E9E9E);

    final bg = _getCardColor();
    final borderColor = _getBorderColor();

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
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onLongPress: () => _showOptionsMenu(context, notifier),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              todo.title,
              style: titleStyle,
              textAlign: TextAlign.start,
            ),
          ),
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context, TimelessTodosNotifier notifier) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit'),
              onTap: () {
                Navigator.of(ctx).pop();
                final state = context
                    .findAncestorStateOfType<_TimelessTodoScreenState>();
                state?._showAddEditDialog(context, existing: todo);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Color(0xFFE53935)),
              title: const Text('Delete', style: TextStyle(color: Color(0xFFE53935))),
              onTap: () {
                Navigator.of(ctx).pop();
                _confirmDelete(context, notifier);
              },
            ),
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
