class TimelessTodo {
  int? id;
  String title;
  String category;
  DateTime dueAt;
  bool isDone;
  DateTime createdAt;

  /// Fallback category used when a todo has no explicit category.
  static const String defaultCategory = 'General';

  /// Default due date/time for a new task: today at 11:00 PM local time
  /// (Indian Standard Time for this app's users).
  static DateTime defaultDueAt() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 23, 0);
  }

  TimelessTodo({
    this.id,
    this.title = '',
    String? category,
    DateTime? dueAt,
    this.isDone = false,
    DateTime? createdAt,
  })  : category = (category == null || category.trim().isEmpty)
            ? defaultCategory
            : category.trim(),
        dueAt = dueAt ?? defaultDueAt(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'category': category,
        'dueAt': dueAt.toIso8601String(),
        'isDone': isDone ? 1 : 0,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TimelessTodo.fromMap(Map<String, dynamic> map) => TimelessTodo(
        id: map['id'] as int?,
        title: map['title'] as String? ?? '',
        category: map['category'] as String?,
        dueAt: (map['dueAt'] as String?) != null
            ? DateTime.parse(map['dueAt'] as String)
            : null,
        isDone: (map['isDone'] as int?) == 1,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );

  TimelessTodo copyWith({
    int? id,
    String? title,
    String? category,
    DateTime? dueAt,
    bool? isDone,
    DateTime? createdAt,
  }) =>
      TimelessTodo(
        id: id ?? this.id,
        title: title ?? this.title,
        category: category ?? this.category,
        dueAt: dueAt ?? this.dueAt,
        isDone: isDone ?? this.isDone,
        createdAt: createdAt ?? this.createdAt,
      );
}
