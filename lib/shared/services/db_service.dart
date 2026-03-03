import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:notetracker/features/notes/models/note.dart';
import 'package:notetracker/features/planner/models/task.dart';

class DbService {
  DbService._();
  static final DbService instance = DbService._();

  late Database _db;

  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, 'notetracker.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            richContentJson TEXT NOT NULL,
            isPinned INTEGER NOT NULL DEFAULT 0,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            date TEXT NOT NULL,
            timeMins INTEGER NOT NULL DEFAULT -1,
            priority TEXT NOT NULL DEFAULT 'medium',
            isDone INTEGER NOT NULL DEFAULT 0,
            reminderEnabled INTEGER NOT NULL DEFAULT 0,
            createdAt TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // ─── Notes ────────────────────────────────────────────────────────────────

  Future<List<Note>> getAllNotes() async {
    final rows = await _db.query('notes', orderBy: 'updatedAt DESC');
    return rows.map(Note.fromMap).toList();
  }

  Future<Note> saveNote(Note note) async {
    if (note.id == null) {
      note.id = await _db.insert('notes', note.toMap());
    } else {
      await _db.update(
        'notes',
        note.toMap(),
        where: 'id = ?',
        whereArgs: [note.id],
      );
    }
    return note;
  }

  Future<void> deleteNote(int id) async {
    await _db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Tasks ────────────────────────────────────────────────────────────────

  Future<List<Task>> getAllTasks() async {
    final rows = await _db.query('tasks');
    return rows.map(Task.fromMap).toList();
  }

  Future<List<Task>> getTasksForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day).toIso8601String();
    final end =
        DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();
    final rows = await _db.query(
      'tasks',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start, end],
      orderBy: 'timeMins ASC',
    );
    return rows.map(Task.fromMap).toList();
  }

  Future<Task> saveTask(Task task) async {
    if (task.id == null) {
      task.id = await _db.insert('tasks', task.toMap());
    } else {
      await _db.update(
        'tasks',
        task.toMap(),
        where: 'id = ?',
        whereArgs: [task.id],
      );
    }
    return task;
  }

  Future<void> deleteTask(int id) async {
    await _db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }
}
