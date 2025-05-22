import 'package:flutter/foundation.dart';

class Course {
  final int id;
  final String title;
  final String description;
  final int trainerId;
  final String? trainerName;
  final String? thumbnailUrl;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Module>? modules;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.trainerId,
    this.trainerName,
    this.thumbnailUrl,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.modules,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: int.parse(json['id'].toString()),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      trainerId: int.parse(json['trainer_id'].toString()),
      trainerName: json['trainer_name'],
      thumbnailUrl: json['thumbnail_url'],
      imageUrl: json['image_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      modules: json['modules'] != null
          ? List<Module>.from(json['modules'].map((x) => Module.fromJson(x)))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'trainer_id': trainerId,
      'trainer_name': trainerName,
      'thumbnail_url': thumbnailUrl,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'modules': modules?.map((x) => x.toJson()).toList(),
    };
  }

  Course copyWith({
    int? id,
    String? title,
    String? description,
    int? trainerId,
    String? trainerName,
    String? thumbnailUrl,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Module>? modules,
  }) {
    return Course(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      trainerId: trainerId ?? this.trainerId,
      trainerName: trainerName ?? this.trainerName,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      modules: modules ?? this.modules,
    );
  }
}

class Module {
  final int id;
  final int courseId;
  final String title;
  final String description;
  final int orderIndex;
  final DateTime createdAt;
  final List<Lesson>? lessons;

  Module({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.orderIndex,
    required this.createdAt,
    this.lessons,
  });

  factory Module.fromJson(Map<String, dynamic> json) {
    return Module(
      id: json['id'],
      courseId: json['course_id'],
      title: json['title'],
      description: json['description'],
      orderIndex: json['order_index'],
      createdAt: DateTime.parse(json['created_at']),
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
      'lessons': lessons?.map((x) => x.toJson()).toList(),
    };
  }
}

class Lesson {
  final int id;
  final int moduleId;
  final String title;
  final String contentType;
  final String contentUrl;
  final int orderIndex;
  final DateTime createdAt;
  final Quiz? quiz;

  Lesson({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.contentType,
    required this.contentUrl,
    required this.orderIndex,
    required this.createdAt,
    this.quiz,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'],
      moduleId: json['module_id'],
      title: json['title'],
      contentType: json['content_type'],
      contentUrl: json['content_url'],
      orderIndex: json['order_index'],
      createdAt: DateTime.parse(json['created_at']),
      quiz: json['quiz'] != null ? Quiz.fromJson(json['quiz']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'module_id': moduleId,
      'title': title,
      'content_type': contentType,
      'content_url': contentUrl,
      'order_index': orderIndex,
      'created_at': createdAt.toIso8601String(),
      'quiz': quiz?.toJson(),
    };
  }
}

class Quiz {
  final int id;
  final int lessonId;
  final String title;
  final String description;
  final int passingScore;
  final DateTime createdAt;
  final List<Question>? questions;

  Quiz({
    required this.id,
    required this.lessonId,
    required this.title,
    required this.description,
    required this.passingScore,
    required this.createdAt,
    this.questions,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'],
      lessonId: json['lesson_id'],
      title: json['title'],
      description: json['description'],
      passingScore: json['passing_score'],
      createdAt: DateTime.parse(json['created_at']),
      questions: json['questions'] != null
          ? List<Question>.from(
              json['questions'].map((x) => Question.fromJson(x)))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lesson_id': lessonId,
      'title': title,
      'description': description,
      'passing_score': passingScore,
      'created_at': createdAt.toIso8601String(),
      'questions': questions?.map((x) => x.toJson()).toList(),
    };
  }
}

class Question {
  final int id;
  final int quizId;
  final String questionText;
  final String questionType;
  final List<Answer>? answers;

  Question({
    required this.id,
    required this.quizId,
    required this.questionText,
    required this.questionType,
    this.answers,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      quizId: json['quiz_id'],
      questionText: json['question_text'],
      questionType: json['question_type'],
      answers: json['answers'] != null
          ? List<Answer>.from(json['answers'].map((x) => Answer.fromJson(x)))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quiz_id': quizId,
      'question_text': questionText,
      'question_type': questionType,
      'answers': answers?.map((x) => x.toJson()).toList(),
    };
  }
}

class Answer {
  final int id;
  final int questionId;
  final String answerText;
  final bool isCorrect;

  Answer({
    required this.id,
    required this.questionId,
    required this.answerText,
    required this.isCorrect,
  });

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      id: json['id'],
      questionId: json['question_id'],
      answerText: json['answer_text'],
      isCorrect: json['is_correct'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_id': questionId,
      'answer_text': answerText,
      'is_correct': isCorrect,
    };
  }
}
