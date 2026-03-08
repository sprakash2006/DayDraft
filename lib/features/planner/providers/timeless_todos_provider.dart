import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notetracker/features/planner/models/timeless_todo.dart';
import 'package:notetracker/shared/services/db_service.dart';

final timelessTodosProvider =
    AsyncNotifierProvider<TimelessTodosNotifier, List<TimelessTodo>>(
        TimelessTodosNotifier.new);

class TimelessTodosNotifier extends AsyncNotifier<List<TimelessTodo>> {
  @override
  Future<List<TimelessTodo>> build() async {
    return DbService.instance.getAllTimelessTodos();
  }

  Future<void> saveTodo(TimelessTodo todo) async {
    final isNew = todo.id == null;
    if (isNew) todo.createdAt = DateTime.now();
    await DbService.instance.saveTimelessTodo(todo);

    // Update in-memory state immediately
    state = state.whenData((todos) {
      if (isNew) return [todo, ...todos];
      return todos.map((t) => t.id == todo.id ? todo : t).toList();
    });
  }

  Future<void> deleteTodo(int id) async {
    // Optimistic update: remove from state before DB call
    state = state.whenData((todos) => todos.where((t) => t.id != id).toList());
    await DbService.instance.deleteTimelessTodo(id);
  }

  Future<void> toggleDone(TimelessTodo todo) async {
    final updated = todo.copyWith(isDone: !todo.isDone);
    // Optimistic update: reflect change immediately
    state = state.whenData(
        (todos) => todos.map((t) => t.id == todo.id ? updated : t).toList());
    await DbService.instance.saveTimelessTodo(updated);
  }
}
