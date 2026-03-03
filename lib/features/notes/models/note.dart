class Note {
  int? id;
  String title;
  String richContentJson;
  bool isPinned;
  DateTime createdAt;
  DateTime updatedAt;

  Note({
    this.id,
    this.title = '',
    this.richContentJson = '',
    this.isPinned = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'richContentJson': richContentJson,
        'isPinned': isPinned ? 1 : 0,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Note.fromMap(Map<String, dynamic> map) => Note(
        id: map['id'] as int?,
        title: map['title'] as String? ?? '',
        richContentJson: map['richContentJson'] as String? ?? '',
        isPinned: (map['isPinned'] as int?) == 1,
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
      );
}
