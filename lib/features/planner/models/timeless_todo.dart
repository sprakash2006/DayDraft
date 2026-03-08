class TimelessTodo {
  int? id;
  String title;
  bool isDone;
  DateTime createdAt;

  TimelessTodo({
    this.id,
    this.title = '',
    this.isDone = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'isDone': isDone ? 1 : 0,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TimelessTodo.fromMap(Map<String, dynamic> map) => TimelessTodo(
        id: map['id'] as int?,
        title: map['title'] as String? ?? '',
        isDone: (map['isDone'] as int?) == 1,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );

  TimelessTodo copyWith({
    int? id,
    String? title,
    bool? isDone,
    DateTime? createdAt,
  }) =>
      TimelessTodo(
        id: id ?? this.id,
        title: title ?? this.title,
        isDone: isDone ?? this.isDone,
        createdAt: createdAt ?? this.createdAt,
      );
}
