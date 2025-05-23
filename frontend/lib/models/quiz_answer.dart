import 'package:flutter/foundation.dart';

class QuizAnswer {
  final int id;
  final int quizAttemptId;
  final int questionId;
  final int selectedAnswerId;
  final bool isCorrect;
  final DateTime createdAt;

  QuizAnswer({
    required this.id,
    required this.quizAttemptId,
    required this.questionId,
    required this.selectedAnswerId,
    required this.isCorrect,
    required this.createdAt,
  });

  factory QuizAnswer.fromJson(Map<String, dynamic> json) {
    return QuizAnswer(
      id: json['id'],
      quizAttemptId: json['quiz_attempt_id'],
      questionId: json['question_id'],
      selectedAnswerId: json['selected_answer_id'],
      isCorrect: json['is_correct'] == 1,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quiz_attempt_id': quizAttemptId,
      'question_id': questionId,
      'selected_answer_id': selectedAnswerId,
      'is_correct': isCorrect ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
