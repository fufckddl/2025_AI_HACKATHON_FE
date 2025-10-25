class RoutineModel {
  final int id; // 고유번호 (AUTO_INCREMENT)
  final int userId; // 고유번호2 (FK)
  final String name; // 이름
  final int cycle; // 주기
  final String content; // 내용
  final DateTime createdAt; // 생성일자
  final DateTime updatedAt; // 업데이트일자
  final DateTime routineTime; // 루틴 실행 시간

  RoutineModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.cycle,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.routineTime,
  });

  factory RoutineModel.fromJson(Map<String, dynamic> json) {
    return RoutineModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      name: json['routine'] ?? '',
      cycle: json['routine_cycle'] ?? 0,
      content: json['routine_content'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      routineTime: DateTime.parse(json['routine_time'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'routine': name,
      'routine_cycle': cycle,
      'routine_content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'routine_time': routineTime.toIso8601String(),
    };
  }

  RoutineModel copyWith({
    int? id,
    int? userId,
    String? name,
    int? cycle,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? routineTime,
  }) {
    return RoutineModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      cycle: cycle ?? this.cycle,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      routineTime: routineTime ?? this.routineTime,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RoutineModel &&
        other.id == id &&
        other.userId == userId &&
        other.name == name &&
        other.cycle == cycle &&
        other.content == content &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.routineTime == routineTime;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        name.hashCode ^
        cycle.hashCode ^
        content.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        routineTime.hashCode;
  }

  @override
  String toString() {
    return 'RoutineModel(id: $id, userId: $userId, name: $name, cycle: $cycle, content: $content, createdAt: $createdAt, updatedAt: $updatedAt, routineTime: $routineTime)';
  }
}
