class UserModel {
  final int id; // 고유번호 (AUTO_INCREMENT)
  final String name; // 부모이름
  final String email; // 이메일
  final String password; // 비밀번호
  final String childName; // 아이이름
  final int childAge; // 아이나이

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.childName,
    required this.childAge,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      childName: json['child_name'] ?? '',
      childAge: json['child_age'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'child_name': childName,
      'child_age': childAge,
    };
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? password,
    String? childName,
    int? childAge,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      childName: childName ?? this.childName,
      childAge: childAge ?? this.childAge,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.password == password &&
        other.childName == childName &&
        other.childAge == childAge;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        email.hashCode ^
        password.hashCode ^
        childName.hashCode ^
        childAge.hashCode;
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, password: $password, childName: $childName, childAge: $childAge)';
  }
}
