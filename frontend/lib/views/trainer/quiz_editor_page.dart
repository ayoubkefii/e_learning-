import 'package:e_learning/models/quiz.dart' as question_models;
import 'package:e_learning/models/quiz.dart' as answer_models;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/quiz.dart';
import '../../services/api_service.dart';

class QuizEditorPage extends StatefulWidget {
  final int courseId;
  final int? lessonId;
  final Quiz? quiz;

  const QuizEditorPage({
    Key? key,
    required this.courseId,
    this.lessonId,
    this.quiz,
  }) : super(key: key);

  @override
  _QuizEditorPageState createState() => _QuizEditorPageState();
}

class _QuizEditorPageState extends State<QuizEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _passingScoreController = TextEditingController(text: '70');
  final List<QuestionEditor> _questions = [];
  bool _isLoading = false;
  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _initializeApiService();
    if (widget.quiz != null) {
      _titleController.text = widget.quiz!.title;
      _descriptionController.text = widget.quiz!.description;
      _passingScoreController.text = widget.quiz!.passingScore.toString();
      // TODO: Load questions from existing quiz
    }
  }

  Future<void> _initializeApiService() async {
    final prefs = await SharedPreferences.getInstance();
    _apiService = ApiService(prefs);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _passingScoreController.dispose();
    super.dispose();
  }

  void _addQuestion() {
    setState(() {
      _questions.add(QuestionEditor(
        key: GlobalKey<_QuestionEditorState>(),
        onDelete: () {
          setState(() {
            _questions.removeLast();
          });
        },
      ));
    });
  }

  Future<void> _saveQuiz() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create quiz object
      final quiz = Quiz(
        id: widget.quiz?.id ?? 0,
        courseId: widget.courseId,
        title: _titleController.text,
        description: _descriptionController.text,
        passingScore: int.parse(_passingScoreController.text),
        createdAt: widget.quiz?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        questions: _questions.map((q) {
          final state = q.key as GlobalKey<_QuestionEditorState>;
          final questionState = state.currentState!;
          return Question(
            id: 0,
            quizId: 0,
            questionText: questionState._questionController.text,
            questionType: questionState._questionType,
            points: 1,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            answers: questionState._answers.map((a) {
              final answerState =
                  (a.key as GlobalKey<_AnswerEditorState>).currentState!;
              return Answer(
                id: 0,
                questionId: 0,
                answerText: answerState._answerController.text,
                isCorrect: answerState._isCorrect,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
            }).toList(),
          );
        }).toList(),
      );

      // Save quiz
      if (widget.quiz != null) {
        await _apiService.updateQuiz(quiz);
      } else {
        await _apiService.createQuiz(quiz);
      }
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving quiz: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Quiz'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveQuiz,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _passingScoreController,
              decoration: const InputDecoration(
                labelText: 'Passing Score (%)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a passing score';
                }
                final score = int.tryParse(value);
                if (score == null || score < 0 || score > 100) {
                  return 'Please enter a valid score (0-100)';
                }
                return null;
              },
            ),
            const SizedBox(height: 24.0),
            const Text(
              'Questions',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
            ..._questions,
            const SizedBox(height: 16.0),
            ElevatedButton.icon(
              onPressed: _addQuestion,
              icon: const Icon(Icons.add),
              label: const Text('Add Question'),
            ),
          ],
        ),
      ),
    );
  }
}

class QuestionEditor extends StatefulWidget {
  final VoidCallback onDelete;

  const QuestionEditor({
    Key? key,
    required this.onDelete,
  }) : super(key: key);

  @override
  _QuestionEditorState createState() => _QuestionEditorState();
}

class _QuestionEditorState extends State<QuestionEditor> {
  final _questionController = TextEditingController();
  String _questionType = 'multiple_choice';
  final List<AnswerEditor> _answers = [];

  @override
  void initState() {
    super.initState();
    _addAnswer();
    _addAnswer();
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  void _addAnswer() {
    setState(() {
      _answers.add(AnswerEditor(
        key: GlobalKey<_AnswerEditorState>(),
        onDelete: () {
          setState(() {
            _answers.removeLast();
          });
        },
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _questionController,
                    decoration: const InputDecoration(
                      labelText: 'Question',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a question';
                      }
                      return null;
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: widget.onDelete,
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            DropdownButtonFormField<String>(
              value: _questionType,
              decoration: const InputDecoration(
                labelText: 'Question Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'multiple_choice',
                  child: Text('Multiple Choice'),
                ),
                DropdownMenuItem(
                  value: 'true_false',
                  child: Text('True/False'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _questionType = value!;
                  if (value == 'true_false') {
                    while (_answers.length > 2) {
                      _answers.removeLast();
                    }
                  }
                });
              },
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Answers',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            ..._answers,
            if (_questionType == 'multiple_choice')
              ElevatedButton.icon(
                onPressed: _addAnswer,
                icon: const Icon(Icons.add),
                label: const Text('Add Answer'),
              ),
          ],
        ),
      ),
    );
  }
}

class AnswerEditor extends StatefulWidget {
  final VoidCallback onDelete;

  const AnswerEditor({
    Key? key,
    required this.onDelete,
  }) : super(key: key);

  @override
  _AnswerEditorState createState() => _AnswerEditorState();
}

class _AnswerEditorState extends State<AnswerEditor> {
  final _answerController = TextEditingController();
  bool _isCorrect = false;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _answerController,
              decoration: const InputDecoration(
                labelText: 'Answer',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an answer';
                }
                return null;
              },
            ),
          ),
          Checkbox(
            value: _isCorrect,
            onChanged: (value) {
              setState(() {
                _isCorrect = value!;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: widget.onDelete,
          ),
        ],
      ),
    );
  }
}
