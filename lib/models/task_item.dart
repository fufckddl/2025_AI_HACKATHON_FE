class TaskItem {
  final String id;
  final String text;
  final bool isCompleted;
  final DateTime createdAt;

  TaskItem({
    required this.id,
    required this.text,
    this.isCompleted = false,
    required this.createdAt,
  });

  TaskItem copyWith({
    String? id,
    String? text,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return TaskItem(
      id: id ?? this.id,
      text: text ?? this.text,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
