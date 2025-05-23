import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/course.dart';
import '../../models/quiz.dart' as quiz_models;
import '../../services/api_service.dart';
import 'quiz_editor_page.dart';

class QuizManagementPage extends StatefulWidget {
  final Course course;

  const QuizManagementPage({
    Key? key,
    required this.course,
  }) : super(key: key);

  @override
  State<QuizManagementPage> createState() => _QuizManagementPageState();
}

class _QuizManagementPageState extends State<QuizManagementPage> {
  late final ApiService _apiService;
  List<quiz_models.Quiz> _quizzes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApiService();
  }

  Future<void> _initializeApiService() async {
    final prefs = await SharedPreferences.getInstance();
    _apiService = ApiService(prefs);
    await _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    try {
      final quizzes = await _apiService.getCourseQuizzes(widget.course.id);
      setState(() {
        _quizzes = quizzes;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading quizzes: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteQuiz(quiz_models.Quiz quiz) async {
    try {
      await _apiService.deleteQuiz(quiz.id);
      await _loadQuizzes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiz deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting quiz: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Quizzes'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _quizzes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'No quizzes yet',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuizEditorPage(
                                courseId: widget.course.id,
                              ),
                            ),
                          );
                          if (result == true) {
                            _loadQuizzes();
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Create Quiz'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _quizzes.length,
                  itemBuilder: (context, index) {
                    final quiz = _quizzes[index];
                    return Card(
                      child: ListTile(
                        title: Text(quiz.title),
                        subtitle: Text(
                          '${quiz.questions.length} questions • Passing score: ${quiz.passingScore}%',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => QuizEditorPage(
                                      courseId: widget.course.id,
                                      quiz: quiz,
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  _loadQuizzes();
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Quiz'),
                                    content: Text(
                                      'Are you sure you want to delete "${quiz.title}"?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _deleteQuiz(quiz);
                                        },
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuizEditorPage(
                courseId: widget.course.id,
              ),
            ),
          );
          if (result == true) {
            _loadQuizzes();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
