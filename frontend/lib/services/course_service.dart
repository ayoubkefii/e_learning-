import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/course.dart';
import 'api_service.dart';

class CourseService {
  // ignore: unused_field
  final ApiService _apiService;
  final Dio _dio;

  CourseService(this._apiService) : _dio = _apiService.dio;

  Future<List<Course>> getCourses() async {
    try {
      final response = await _dio.get('/courses/read.php');
      if (response.statusCode == 200) {
        final List<dynamic> coursesJson = response.data['records'];
        return coursesJson.map((json) => Course.fromJson(json)).toList();
      }
      throw Exception('Failed to load courses');
    } catch (e) {
      print('Error getting courses: $e');
      rethrow;
    }
  }

  Future<Course> getCourse(int id) async {
    try {
      final response = await _dio.get('/courses/read_one.php?id=$id');
      if (response.statusCode == 200) {
        return Course.fromJson(response.data);
      }
      throw Exception('Failed to load course');
    } catch (e) {
      print('Error getting course: $e');
      rethrow;
    }
  }

  Future<Course> createCourse(Course course) async {
    try {
      final response = await _dio.post(
        '/courses/create.php',
        data: jsonEncode(course.toJson()),
      );
      if (response.statusCode == 201) {
        return course;
      }
      throw Exception('Failed to create course');
    } catch (e) {
      print('Error creating course: $e');
      rethrow;
    }
  }

  Future<Course> updateCourse(Course course) async {
    try {
      final response = await _dio.put(
        '/courses/update.php',
        data: jsonEncode(course.toJson()),
      );
      if (response.statusCode == 200) {
        return course;
      }
      throw Exception('Failed to update course');
    } catch (e) {
      print('Error updating course: $e');
      rethrow;
    }
  }

  Future<void> deleteCourse(int id) async {
    try {
      final response = await _dio.delete('/courses/delete.php?id=$id');
      if (response.statusCode != 200) {
        throw Exception('Failed to delete course');
      }
    } catch (e) {
      print('Error deleting course: $e');
      rethrow;
    }
  }

  Future<List<Course>> getTrainerCourses(int trainerId) async {
    try {
      final response =
          await _dio.get('/courses/read_by_trainer.php?trainer_id=$trainerId');
      if (response.statusCode == 200) {
        final List<dynamic> coursesJson = response.data['records'];
        return coursesJson.map((json) => Course.fromJson(json)).toList();
      }
      throw Exception('Failed to load trainer courses');
    } catch (e) {
      print('Error getting trainer courses: $e');
      rethrow;
    }
  }
}
