import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:notetracker/features/notes/models/note.dart';
import 'package:notetracker/features/planner/models/timeless_todo.dart';

class DbService {
  DbService._();
  static final DbService instance = DbService._();

  late Database _db;

  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, 'notetracker.db'),
      version: 4,
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
          CREATE TABLE timeless_todos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            category TEXT NOT NULL DEFAULT 'General',
            dueAt TEXT,
            isDone INTEGER NOT NULL DEFAULT 0,
            createdAt TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE timeless_category_order (
            name TEXT PRIMARY KEY,
            position INTEGER NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS timeless_todos (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              isDone INTEGER NOT NULL DEFAULT 0,
              createdAt TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 3) {
          await _addCategoryColumnIfMissing(db);
          await db.execute('''
            CREATE TABLE IF NOT EXISTS timeless_category_order (
              name TEXT PRIMARY KEY,
              position INTEGER NOT NULL
            )
          ''');
        }
        if (oldVersion < 4) {
          await _addDueAtColumnIfMissing(db);
        }
      },
      onOpen: (db) async {
        // Ensure timeless_todos table exists (for migrating from v1)
        await db.execute('''
          CREATE TABLE IF NOT EXISTS timeless_todos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            category TEXT NOT NULL DEFAULT 'General',
            isDone INTEGER NOT NULL DEFAULT 0,
            createdAt TEXT NOT NULL
          )
        ''');
        await _addCategoryColumnIfMissing(db);
        await _addDueAtColumnIfMissing(db);
        await db.execute('''
          CREATE TABLE IF NOT EXISTS timeless_category_order (
            name TEXT PRIMARY KEY,
            position INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  /// Adds the `category` column to timeless_todos when upgrading from a schema
  /// that predates it. Safe to call repeatedly.
  Future<void> _addCategoryColumnIfMissing(Database db) async {
    final cols = await db.rawQuery('PRAGMA table_info(timeless_todos)');
    final hasCategory = cols.any((c) => c['name'] == 'category');
    if (!hasCategory) {
      await db.execute(
        "ALTER TABLE timeless_todos ADD COLUMN category TEXT NOT NULL DEFAULT 'General'",
      );
    }
  }

  /// Adds the nullable `dueAt` column to timeless_todos when upgrading from a
  /// schema that predates it. Safe to call repeatedly.
  Future<void> _addDueAtColumnIfMissing(Database db) async {
    final cols = await db.rawQuery('PRAGMA table_info(timeless_todos)');
    final hasDueAt = cols.any((c) => c['name'] == 'dueAt');
    if (!hasDueAt) {
      await db.execute('ALTER TABLE timeless_todos ADD COLUMN dueAt TEXT');
    }
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

  // ─── Timeless Todos ───────────────────────────────────────────────────────

  Future<void> _ensureTimelessTodosTable() async {
    await _db.execute('''
      CREATE TABLE IF NOT EXISTS timeless_todos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'General',
        isDone INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');
    await _addCategoryColumnIfMissing(_db);
    await _addDueAtColumnIfMissing(_db);
    await _db.execute('''
      CREATE TABLE IF NOT EXISTS timeless_category_order (
        name TEXT PRIMARY KEY,
        position INTEGER NOT NULL
      )
    ''');
  }

  Future<List<TimelessTodo>> getAllTimelessTodos() async {
    await _ensureTimelessTodosTable();
    final rows = await _db.query('timeless_todos', orderBy: 'createdAt DESC');
    return rows.map(TimelessTodo.fromMap).toList();
  }

  Future<TimelessTodo> saveTimelessTodo(TimelessTodo todo) async {
    await _ensureTimelessTodosTable();
    if (todo.id == null) {
      todo.id = await _db.insert('timeless_todos', todo.toMap());
    } else {
      await _db.update(
        'timeless_todos',
        todo.toMap(),
        where: 'id = ?',
        whereArgs: [todo.id],
      );
    }
    return todo;
  }

  Future<void> deleteTimelessTodo(int id) async {
    await _ensureTimelessTodosTable();
    await _db.delete('timeless_todos', where: 'id = ?', whereArgs: [id]);
  }

  /// Returns the saved category display order (may include categories that no
  /// longer have any todos).
  Future<List<String>> getCategoryOrder() async {
    await _ensureTimelessTodosTable();
    final rows = await _db.query(
      'timeless_category_order',
      orderBy: 'position ASC',
    );
    return rows.map((r) => r['name'] as String).toList();
  }

  /// Persists the given category order, replacing any previously saved order.
  Future<void> setCategoryOrder(List<String> categories) async {
    await _ensureTimelessTodosTable();
    final batch = _db.batch();
    batch.delete('timeless_category_order');
    for (var i = 0; i < categories.length; i++) {
      batch.insert('timeless_category_order', {
        'name': categories[i],
        'position': i,
      });
    }
    await batch.commit(noResult: true);
  }
}
