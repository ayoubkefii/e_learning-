class User {
  final int id;
  final String username;
  final String name;
  final String email;
  final String role;
  final String? token;

  User({
    required this.id,
    required this.username,
    required this.name,
    required this.email,
    required this.role,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    print('DEBUG: Raw JSON for User: $json'); // Debug print
    final role = json['role']?.toString().trim().toLowerCase() ?? '';
    print('DEBUG: Processed role value: $role'); // Debug print

    return User(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      username: json['username']?.toString() ?? json['name']?.toString() ?? '',
      name: json['name']?.toString() ?? json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: role,
      token: json['token']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'email': email,
      'role': role,
      'token': token,
    };
  }

  User copyWith({
    int? id,
    String? username,
    String? name,
    String? email,
    String? role,
    String? token,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      token: token ?? this.token,
    );
  }
}
