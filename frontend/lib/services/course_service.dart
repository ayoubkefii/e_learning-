import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/course.dart';
import 'api_service.dart';

class CourseService {
  final ApiService _apiService;

  CourseService(this._apiService);

  Future<List<Course>> getCourses() async {
    try {
      print('CourseService: Fetching courses...');
      final response = await _apiService.dio.get(
        '/courses/list.php',
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
          validateStatus: (status) {
            return status! < 500; // Accept any status code less than 500
          },
        ),
      );

      print('CourseService: Response status: ${response.statusCode}');
      print('CourseService: Response data: ${response.data}');

      if (response.statusCode == 200) {
        if (response.data is Map && response.data['records'] is List) {
          return (response.data['records'] as List)
              .map((json) => Course.fromJson(json))
              .toList();
        }
      }
      // If no courses found or any other non-500 status, return empty list
      print('CourseService: No courses found');
      return [];
    } catch (e) {
      print('CourseService: Error getting courses: $e');
      throw Exception('Failed to load courses: $e');
    }
  }

  Future<Course> getCourse(int id) async {
    try {
      print('CourseService: Getting course with id: $id');
      final response = await _apiService.dio.get(
        '/courses/get.php',
        queryParameters: {'id': id},
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      print(
          'CourseService: Get course response status: ${response.statusCode}');
      print('CourseService: Get course response data: ${response.data}');

      if (response.statusCode == 200) {
        return Course.fromJson(response.data);
      }
      throw Exception(
          'Failed to load course: ${response.data['message'] ?? 'Unknown error'}');
    } catch (e) {
      print('CourseService: Error getting course: $e');
      throw Exception('Failed to load course: $e');
    }
  }

  Future<Course> createCourse(Course course) async {
    try {
      // Only send required fields for course creation
      final courseData = {
        'title': course.title,
        'description': course.description,
        'trainer_id': course.trainerId,
      };

      print('CourseService: Creating course with data: $courseData');
      final response = await _apiService.dio.post(
        '/courses/create.php',
        data: courseData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          validateStatus: (status) {
            return status! < 500; // Accept any status code less than 500
          },
        ),
      );

      print('CourseService: Create response status: ${response.statusCode}');
      print('CourseService: Create response data: ${response.data}');

      if (response.statusCode == 201) {
        return Course.fromJson(response.data);
      }
      throw Exception(
          'Failed to create course: ${response.data['message'] ?? 'Unknown error'}');
    } catch (e) {
      print('CourseService: Error creating course: $e');
      throw Exception('Failed to create course: $e');
    }
  }

  Future<void> updateCourse(Course course) async {
    try {
      final response = await _apiService.dio.post(
        '/courses/update.php',
        data: jsonEncode(course.toJson()),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update course');
      }
    } catch (e) {
      throw Exception('Failed to update course: $e');
    }
  }

  Future<void> deleteCourse(int id) async {
    try {
      final response = await _apiService.dio.post(
        '/courses/delete.php',
        data: jsonEncode({'id': id}),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to delete course');
      }
    } catch (e) {
      throw Exception('Failed to delete course: $e');
    }
  }

  Future<List<Course>> getTrainerCourses(int trainerId) async {
    try {
      final response = await _apiService.dio
          .get('/courses/read_by_trainer.php?trainer_id=$trainerId');
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
