import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../models/course.dart';
import '../trainer/quiz_management_page.dart';

class CourseView extends StatefulWidget {
  final int courseId;

  const CourseView({Key? key, required this.courseId}) : super(key: key);

  @override
  State<CourseView> createState() => _CourseViewState();
}

class _CourseViewState extends State<CourseView> {
  late final ApiService _apiService;
  bool _isOwner = false;
  bool _isLoading = true;
  Course? _course;

  @override
  void initState() {
    super.initState();
    _initializeApiService();
  }

  Future<void> _initializeApiService() async {
    final prefs = await SharedPreferences.getInstance();
    _apiService = ApiService(prefs);
    await _checkOwnership();
    await _loadCourse();
  }

  Future<void> _loadCourse() async {
    try {
      final course = await _apiService.getCourse(widget.courseId);
      setState(() {
        _course = course;
      });
    } catch (e) {
      print('Error loading course: $e');
    }
  }

  Future<void> _checkOwnership() async {
    try {
      final isOwner = await _apiService.isCourseOwner(widget.courseId);
      setState(() {
        _isOwner = isOwner;
        _isLoading = false;
      });
    } catch (e) {
      print('Error checking course ownership: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Details'),
        actions: [
          if (_isOwner && _course != null)
            IconButton(
              icon: const Icon(Icons.quiz),
              tooltip: 'Manage Quizzes',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuizManagementPage(
                      course: _course!,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      // ... rest of the existing build method ...
    );
  }
}
