class Module {
  final int id;
  final int courseId;
  final String title;
  final String description;
  final int orderIndex;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<Lesson>? lessons;

  Module({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.orderIndex,
    required this.createdAt,
    this.updatedAt,
    this.lessons,
  });

  // Factory constructor for creating a new module
  factory Module.create({
    required int courseId,
    required String title,
    required String description,
  }) {
    return Module(
      id: 0, // Will be set by the backend
      courseId: courseId,
      title: title,
      description: description,
      orderIndex: 0, // Will be set by the backend
      createdAt: DateTime.now(), // Will be set by the backend
    );
  }

  factory Module.fromJson(Map<String, dynamic> json) {
    return Module(
      id: int.parse(json['id'].toString()),
      courseId: int.parse(json['course_id'].toString()),
      title: json['title'],
      description: json['description'],
      orderIndex: int.parse(json['order_index'].toString()),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      lessons: json['lessons'] != null
          ? List<Lesson>.from(json['lessons'].map((x) => Lesson.fromJson(x)))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'title': title,
      'description': description,
      'order_index': orderIndex,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'lessons': lessons?.map((x) => x.toJson()).toList(),
    };
  }

  Module copyWith({
    int? id,
    int? courseId,
    String? title,
    String? description,
    int? orderIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Lesson>? lessons,
  }) {
    return Module(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lessons: lessons ?? this.lessons,
    );
  }
}

class Lesson {
  final int id;
  final int moduleId;
  final String title;
  final String description;
  final String contentType;
  final String? contentUrl;
  final int orderIndex;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Lesson({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.description,
    required this.contentType,
    this.contentUrl,
    required this.orderIndex,
    required this.createdAt,
    this.updatedAt,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: int.parse(json['id'].toString()),
      moduleId: int.parse(json['module_id'].toString()),
      title: json['title'],
      description: json['description'],
      contentType: json['content_type'],
      contentUrl: json['content_url'],
      orderIndex: int.parse(json['order_index'].toString()),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'module_id': moduleId,
      'title': title,
      'description': description,
      'content_type': contentType,
      'content_url': contentUrl,
      'order_index': orderIndex,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Lesson copyWith({
    int? id,
    int? moduleId,
    String? title,
    String? description,
    String? contentType,
    String? contentUrl,
    int? orderIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Lesson(
      id: id ?? this.id,
      moduleId: moduleId ?? this.moduleId,
      title: title ?? this.title,
      description: description ?? this.description,
      contentType: contentType ?? this.contentType,
      contentUrl: contentUrl ?? this.contentUrl,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
