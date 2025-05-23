import 'package:flutter/foundation.dart';
import 'quiz_answer.dart';

class QuizAttempt {
  final int id;
  final int quizId;
  final int userId;
  final int score;
  final bool passed;
  final DateTime startedAt;
  final DateTime? completedAt;
  final List<QuizAnswer> answers;

  QuizAttempt({
    required this.id,
    required this.quizId,
    required this.userId,
    required this.score,
    required this.passed,
    required this.startedAt,
    this.completedAt,
    required this.answers,
  });

  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    return QuizAttempt(
      id: json['id'],
      quizId: json['quiz_id'],
      userId: json['user_id'],
      score: json['score'],
      passed: json['passed'] == 1,
      startedAt: DateTime.parse(json['started_at']),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      answers: (json['answers'] as List<dynamic>?)
              ?.map((a) => QuizAnswer.fromJson(a))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quiz_id': quizId,
      'user_id': userId,
      'score': score,
      'passed': passed ? 1 : 0,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'answers': answers.map((a) => a.toJson()).toList(),
    };
  }
}
