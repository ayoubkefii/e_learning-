import 'dart:convert';

class Quiz {
  final int id;
  final int courseId;
  final String title;
  final String description;
  final int passingScore;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Question> questions;

  Quiz({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.passingScore,
    required this.createdAt,
    required this.updatedAt,
    required this.questions,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'],
      courseId: json['course_id'],
      title: json['title'],
      description: json['description'],
      passingScore: json['passing_score'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      questions: (json['questions'] as List?)
              ?.map((q) => Question.fromJson(q))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'title': title,
      'description': description,
      'passing_score': passingScore,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }
}

class Question {
  final int id;
  final int quizId;
  final String questionText;
  final String questionType;
  final int points;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Answer> answers;

  Question({
    required this.id,
    required this.quizId,
    required this.questionText,
    required this.questionType,
    required this.points,
    required this.createdAt,
    required this.updatedAt,
    this.answers = const [],
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      quizId: json['quiz_id'],
      questionText: json['question_text'],
      questionType: json['question_type'],
      points: json['points'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      answers: json['answers'] != null
          ? List<Answer>.from(json['answers'].map((x) => Answer.fromJson(x)))
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quiz_id': quizId,
      'question_text': questionText,
      'question_type': questionType,
      'points': points,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'answers': answers.map((x) => x.toJson()).toList(),
    };
  }
}

class Answer {
  final int id;
  final int questionId;
  final String answerText;
  final bool isCorrect;
  final DateTime createdAt;
  final DateTime updatedAt;

  Answer({
    required this.id,
    required this.questionId,
    required this.answerText,
    required this.isCorrect,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      id: json['id'],
      questionId: json['question_id'],
      answerText: json['answer_text'],
      isCorrect: json['is_correct'] == 1 || json['is_correct'] == true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_id': questionId,
      'answer_text': answerText,
      'is_correct': isCorrect,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class QuizAttempt {
  final int id;
  final int userId;
  final int quizId;
  final int? score;
  final bool passed;
  final DateTime startedAt;
  final DateTime? completedAt;
  final List<QuizAnswer> answers;

  QuizAttempt({
    required this.id,
    required this.userId,
    required this.quizId,
    this.score,
    required this.passed,
    required this.startedAt,
    this.completedAt,
    this.answers = const [],
  });

  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    return QuizAttempt(
      id: json['id'],
      userId: json['user_id'],
      quizId: json['quiz_id'],
      score: json['score'],
      passed: json['passed'] == 1 || json['passed'] == true,
      startedAt: DateTime.parse(json['started_at']),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      answers: json['answers'] != null
          ? List<QuizAnswer>.from(
              json['answers'].map((x) => QuizAnswer.fromJson(x)))
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'quiz_id': quizId,
      'score': score,
      'passed': passed,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'answers': answers.map((x) => x.toJson()).toList(),
    };
  }
}

class QuizAnswer {
  final int id;
  final int attemptId;
  final int questionId;
  final int selectedAnswerId;
  final bool isCorrect;

  QuizAnswer({
    required this.id,
    required this.attemptId,
    required this.questionId,
    required this.selectedAnswerId,
    required this.isCorrect,
  });

  factory QuizAnswer.fromJson(Map<String, dynamic> json) {
    return QuizAnswer(
      id: json['id'],
      attemptId: json['attempt_id'],
      questionId: json['question_id'],
      selectedAnswerId: json['selected_answer_id'],
      isCorrect: json['is_correct'] == 1 || json['is_correct'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'attempt_id': attemptId,
      'question_id': questionId,
      'selected_answer_id': selectedAnswerId,
      'is_correct': isCorrect,
    };
  }
}
