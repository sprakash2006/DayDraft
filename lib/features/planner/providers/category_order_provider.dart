import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notetracker/shared/services/db_service.dart';

/// Persisted display order for the timeless-task category columns.
///
/// The saved order may reference categories that currently have no todos; the
/// UI is responsible for intersecting this with the categories actually
/// present. New categories not yet in the saved order are appended at the end.
final categoryOrderProvider =
    AsyncNotifierProvider<CategoryOrderNotifier, List<String>>(
        CategoryOrderNotifier.new);

class CategoryOrderNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    return DbService.instance.getCategoryOrder();
  }

  /// Orders [present] categories by the saved order, appending any that are not
  /// yet known (persisting them so they get a stable slot). Returns the ordered
  /// list synchronously derived from current state.
  List<String> orderedFor(List<String> present) {
    final saved = state.value ?? const <String>[];
    final result = <String>[];
    for (final name in saved) {
      if (present.contains(name)) result.add(name);
    }
    for (final name in present) {
      if (!result.contains(name)) result.add(name);
    }
    return result;
  }

  /// Persists a new explicit order for the given categories.
  Future<void> setOrder(List<String> categories) async {
    state = AsyncData(categories);
    await DbService.instance.setCategoryOrder(categories);
  }
}
