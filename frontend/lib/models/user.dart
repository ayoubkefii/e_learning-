class User {
  final int? id;
  final String? name;
  final String? email;
  final String? username;
  final String? role;
  final String? token;
  final bool? isActive;
  final bool? isEnrolled;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    this.id,
    this.name,
    this.email,
    this.username,
    this.role,
    this.token,
    this.isActive,
    this.isEnrolled,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] != null ? int.parse(json['id'].toString()) : null,
      name: json['name'],
      email: json['email'],
      username: json['username'],
      role: json['role'],
      token: json['token'],
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      isEnrolled: json['is_enrolled'] == 1 || json['is_enrolled'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'username': username,
      'role': role,
      'token': token,
      'is_active': isActive,
      'is_enrolled': isEnrolled,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? username,
    String? role,
    String? token,
    bool? isActive,
    bool? isEnrolled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      username: username ?? this.username,
      role: role ?? this.role,
      token: token ?? this.token,
      isActive: isActive ?? this.isActive,
      isEnrolled: isEnrolled ?? this.isEnrolled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
