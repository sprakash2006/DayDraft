import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notetracker/features/notes/models/note.dart';
import 'package:notetracker/shared/services/db_service.dart';

final notesProvider =
    AsyncNotifierProvider<NotesNotifier, List<Note>>(NotesNotifier.new);

class NotesNotifier extends AsyncNotifier<List<Note>> {
  @override
  Future<List<Note>> build() => _fetchNotes();

  Future<List<Note>> _fetchNotes() async {
    final notes = await DbService.instance.getAllNotes();
    notes.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return notes;
  }

  Future<Note> saveNote(Note note) async {
    final now = DateTime.now();
    if (note.id == null) note.createdAt = now;
    note.updatedAt = now;
    final saved = await DbService.instance.saveNote(note);
    ref.invalidateSelf();
    await future;
    return saved;
  }

  Future<void> deleteNote(int id) async {
    await DbService.instance.deleteNote(id);
    ref.invalidateSelf();
    await future;
  }

  Future<void> togglePin(Note note) async {
    note.isPinned = !note.isPinned;
    note.updatedAt = DateTime.now();
    await DbService.instance.saveNote(note);
    ref.invalidateSelf();
    await future;
  }
}
