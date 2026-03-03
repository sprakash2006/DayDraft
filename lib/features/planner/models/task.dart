enum TaskPriority { low, medium, high }

class Task {
  int? id;
  String title;
  DateTime date;

  /// Minutes since midnight. -1 means no time set.
  int timeMins;

  TaskPriority priority;
  bool isDone;
  bool reminderEnabled;
  DateTime createdAt;

  Task({
    this.id,
    this.title = '',
    DateTime? date,
    this.timeMins = -1,
    this.priority = TaskPriority.medium,
    this.isDone = false,
    this.reminderEnabled = false,
    DateTime? createdAt,
  })  : date = date ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  int? get hour => timeMins >= 0 ? timeMins ~/ 60 : null;
  int? get minute => timeMins >= 0 ? timeMins % 60 : null;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'date': date.toIso8601String(),
        'timeMins': timeMins,
        'priority': priority.name,
        'isDone': isDone ? 1 : 0,
        'reminderEnabled': reminderEnabled ? 1 : 0,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Task.fromMap(Map<String, dynamic> map) => Task(
        id: map['id'] as int?,
        title: map['title'] as String? ?? '',
        date: DateTime.parse(map['date'] as String),
        timeMins: map['timeMins'] as int? ?? -1,
        priority: TaskPriority.values.firstWhere(
          (p) => p.name == map['priority'],
          orElse: () => TaskPriority.medium,
        ),
        isDone: (map['isDone'] as int?) == 1,
        reminderEnabled: (map['reminderEnabled'] as int?) == 1,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
