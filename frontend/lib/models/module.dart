class Module {
  final int id;
  final int courseId;
  final String title;
  final String description;
  final int orderNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Lesson>? lessons;

  Module({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.orderNumber,
    required this.createdAt,
    required this.updatedAt,
    this.lessons,
  });

  factory Module.fromJson(Map<String, dynamic> json) {
    return Module(
      id: int.parse(json['id'].toString()),
      courseId: int.parse(json['course_id'].toString()),
      title: json['title'],
      description: json['description'],
      orderNumber: int.parse(json['order_number'].toString()),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
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
      'order_number': orderNumber,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'lessons': lessons?.map((x) => x.toJson()).toList(),
    };
  }

  Module copyWith({
    int? id,
    int? courseId,
    String? title,
    String? description,
    int? orderNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Lesson>? lessons,
  }) {
    return Module(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      orderNumber: orderNumber ?? this.orderNumber,
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
  final int orderNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  Lesson({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.description,
    required this.contentType,
    this.contentUrl,
    required this.orderNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: int.parse(json['id'].toString()),
      moduleId: int.parse(json['module_id'].toString()),
      title: json['title'],
      description: json['description'],
      contentType: json['content_type'],
      contentUrl: json['content_url'],
      orderNumber: int.parse(json['order_number'].toString()),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
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
      'order_number': orderNumber,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Lesson copyWith({
    int? id,
    int? moduleId,
    String? title,
    String? description,
    String? contentType,
    String? contentUrl,
    int? orderNumber,
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
      orderNumber: orderNumber ?? this.orderNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
