import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notetracker/features/notes/models/note.dart';
import 'package:notetracker/features/notes/providers/notes_provider.dart';
import 'package:notetracker/features/notes/screens/note_editor_screen.dart';
import 'package:notetracker/features/notes/widgets/note_card.dart';
import 'package:notetracker/shared/widgets/empty_state.dart';

class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider);
    final notifier = ref.read(notesProvider.notifier);

    return Scaffold(
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (notes) {
          if (notes.isEmpty) {
            return const EmptyState(
              icon: Icons.sticky_note_2_outlined,
              title: 'No notes yet',
              subtitle: 'Tap the + button to create your first note.',
            );
          }
          return CustomScrollView(
            slivers: [
              const SliverAppBar(
                title: Text('Notes'),
                floating: true,
                snap: true,
              ),
              SliverPadding(
                padding: const EdgeInsets.all(12),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final note = notes[index];
                      return NoteCard(
                        note: note,
                        onTap: () => _openEditor(context, note),
                        onPin: () => notifier.togglePin(note),
                        onDelete: () => _confirmDelete(context, note, notifier),
                      );
                    },
                    childCount: notes.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openEditor(BuildContext context, Note? note) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(existingNote: note),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Note note, NotesNotifier notifier) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              notifier.deleteNote(note.id!);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
