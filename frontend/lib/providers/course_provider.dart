import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course.dart';
import '../services/api_service.dart';

class CourseProvider with ChangeNotifier {
  late final ApiService _apiService;
  List<Course> _courses = [];
  Course? _selectedCourse;
  bool _isLoading = false;
  String? _error;

  List<Course> get courses => _courses;
  Course? get selectedCourse => _selectedCourse;
  bool get isLoading => _isLoading;
  String? get error => _error;

  CourseProvider(SharedPreferences prefs) {
    _apiService = ApiService(prefs);
  }

  Future<void> loadCourses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _courses = await _apiService.getCourses();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
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
      _selectedCourse = await _apiService.getCourse(id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createCourse(Course course) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newCourse = await _apiService.createCourse(course);
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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.updateCourse(course);
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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deleteCourse(id);
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
