import 'package:flutter/foundation.dart';
import '../models/course.dart';
import '../services/course_service.dart';

class CourseProvider with ChangeNotifier {
  final CourseService _courseService;
  List<Course> _courses = [];
  Course? _selectedCourse;
  bool _isLoading = false;
  String? _error;

  List<Course> get courses => _courses;
  Course? get selectedCourse => _selectedCourse;
  bool get isLoading => _isLoading;
  String? get error => _error;

  CourseProvider(this._courseService);

  Future<void> loadCourses() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('CourseProvider: Loading courses...');
      _courses = await _courseService.getCourses();
      print('CourseProvider: Loaded ${_courses.length} courses');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('CourseProvider: Error loading courses: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCourse(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedCourse = await _courseService.getCourse(id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createCourse(Course course) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final newCourse = await _courseService.createCourse(course);
      _courses.add(newCourse);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateCourse(Course course) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _courseService.updateCourse(course);
      final index = _courses.indexWhere((c) => c.id == course.id);
      if (index != -1) {
        _courses[index] = course;
      }
      if (_selectedCourse?.id == course.id) {
        _selectedCourse = course;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteCourse(int id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _courseService.deleteCourse(id);
      _courses.removeWhere((course) => course.id == id);
      if (_selectedCourse?.id == id) {
        _selectedCourse = null;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectCourse(Course course) {
    _selectedCourse = course;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
