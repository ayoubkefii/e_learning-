import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../models/quiz.dart' as quiz_models;
import '../../providers/auth_provider.dart';

class QuizPage extends StatefulWidget {
  final int quizId;

  const QuizPage({Key? key, required this.quizId}) : super(key: key);

  @override
  _QuizPageState createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  late Future<quiz_models.Quiz> _quizFuture;
  late Future<quiz_models.QuizAttempt> _attemptFuture;
  final Map<int, int> _selectedAnswers = {};
  bool _isSubmitting = false;
  bool _showResults = false;
  quiz_models.QuizAttempt? _lastAttempt;

  @override
  void initState() {
    super.initState();
    _quizFuture = _loadQuiz();
    _attemptFuture = _startAttempt();
  }

  Future<quiz_models.Quiz> _loadQuiz() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    return apiService.getQuiz(widget.quizId);
  }

  Future<quiz_models.QuizAttempt> _startAttempt() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    return apiService.startQuizAttempt(widget.quizId);
  }

  Future<void> _submitQuiz() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final attempt = await _attemptFuture;

      final answers = _selectedAnswers.entries.map((entry) {
        return quiz_models.QuizAnswer(
          id: 0,
          attemptId: attempt.id,
          questionId: entry.key,
          selectedAnswerId: entry.value,
          isCorrect: false, // This will be set by the server
        );
      }).toList();

      final result = await apiService.submitQuizAnswers(attempt.id, answers);

      setState(() {
        _lastAttempt = result;
        _showResults = true;
      });

      if (result.passed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Congratulations! You passed the quiz!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You did not pass the quiz. Try again!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting quiz: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz'),
        actions: [
          if (!_showResults)
            TextButton(
              onPressed: _isSubmitting ? null : _submitQuiz,
              child: Text(
                'Submit',
                style: TextStyle(
                  color: _isSubmitting ? Colors.grey : Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: FutureBuilder<quiz_models.Quiz>(
        future: _quizFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading quiz: ${snapshot.error}'),
            );
          }

          final quiz = snapshot.data!;

          if (_showResults && _lastAttempt != null) {
            return _buildResults(quiz, _lastAttempt!);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quiz.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  quiz.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                ...quiz.questions.map((question) => _buildQuestion(question)),
                const SizedBox(height: 32),
                Center(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitQuiz,
                    child: _isSubmitting
                        ? const CircularProgressIndicator()
                        : const Text('Submit Quiz'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuestion(quiz_models.Question question) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.questionText,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (question.questionType == 'multiple_choice')
              ...question.answers.map((answer) => RadioListTile<int>(
                    title: Text(answer.answerText),
                    value: answer.id,
                    groupValue: _selectedAnswers[question.id],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedAnswers[question.id] = value;
                        });
                      }
                    },
                  ))
            else if (question.questionType == 'true_false')
              ...question.answers.map((answer) => RadioListTile<int>(
                    title: Text(answer.answerText),
                    value: answer.id,
                    groupValue: _selectedAnswers[question.id],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedAnswers[question.id] = value;
                        });
                      }
                    },
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(quiz_models.Quiz quiz, quiz_models.QuizAttempt attempt) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color:
                attempt.passed ? Colors.green.shade50 : Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attempt.passed ? 'Quiz Passed!' : 'Quiz Not Passed',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: attempt.passed ? Colors.green : Colors.orange,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Score: ${attempt.score}%',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    'Passing Score: ${quiz.passingScore}%',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Question Review',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          ...quiz.questions.map((question) {
            final selectedAnswerId = _selectedAnswers[question.id];
            final selectedAnswer = question.answers.firstWhere(
                (a) => a.id == selectedAnswerId,
                orElse: () => question.answers.first);
            final isCorrect = selectedAnswer.isCorrect;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.questionText,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    ...question.answers.map((answer) {
                      final isSelected = answer.id == selectedAnswerId;
                      final isRightAnswer = answer.isCorrect;

                      return ListTile(
                        title: Text(answer.answerText),
                        leading: Icon(
                          isSelected
                              ? (isRightAnswer
                                  ? Icons.check_circle
                                  : Icons.cancel)
                              : (isRightAnswer
                                  ? Icons.check_circle_outline
                                  : null),
                          color: isSelected
                              ? (isRightAnswer ? Colors.green : Colors.red)
                              : (isRightAnswer ? Colors.green : null),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 32),
          Center(
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _showResults = false;
                  _selectedAnswers.clear();
                  _attemptFuture = _startAttempt();
                });
              },
              child: const Text('Try Again'),
            ),
          ),
        ],
      ),
    );
  }
}
