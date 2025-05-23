class User {
  final int id;
  final String name;
  final String email;
  final String username;
  final String role;
  final bool isEnrolled;
  final bool isActive;
  final String? token;

  User({
    required this.id,
    this.name = '',
    required this.email,
    required this.username,
    required this.role,
    this.isEnrolled = false,
    this.isActive = true,
    this.token,
  });

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? username,
    String? role,
    bool? isEnrolled,
    bool? isActive,
    String? token,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      username: username ?? this.username,
      role: role ?? this.role,
      isEnrolled: isEnrolled ?? this.isEnrolled,
      isActive: isActive ?? this.isActive,
      token: token ?? this.token,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String,
      username: json['username'] as String,
      role: json['role'] as String,
      isEnrolled: json['is_enrolled'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      token: json['token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'username': username,
      'role': role,
      'is_enrolled': isEnrolled,
      'is_active': isActive,
      'token': token,
    };
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, username: $username, role: $role, isEnrolled: $isEnrolled, isActive: $isActive, token: ${token != null ? "present" : "null"})';
  }
}
