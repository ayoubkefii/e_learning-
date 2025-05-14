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
            return status! < 500;
          },
        ),
      );

      print('CourseService: Response status: ${response.statusCode}');
      print('CourseService: Response data: ${response.data}');

      if (response.statusCode == 200) {
        if (response.data is List) {
          return (response.data as List)
              .map((json) => Course.fromJson(json))
              .toList();
        } else if (response.data is Map && response.data['courses'] is List) {
          return (response.data['courses'] as List)
              .map((json) => Course.fromJson(json))
              .toList();
        } else if (response.data is Map && response.data['records'] is List) {
          return (response.data['records'] as List)
              .map((json) => Course.fromJson(json))
              .toList();
        } else {
          print('CourseService: Unexpected response format: ${response.data}');
          throw Exception('Invalid response format');
        }
      } else if (response.statusCode == 404) {
        print('CourseService: No courses found');
        return [];
      }
      throw Exception('Failed to load courses: ${response.statusCode}');
    } on DioException catch (e) {
      print('CourseService: DioError getting courses:');
      print('Error type: ${e.type}');
      print('Error message: ${e.message}');
      print('Error response: ${e.response?.data}');
      print('Request URL: ${e.requestOptions.uri}');
      print('Request headers: ${e.requestOptions.headers}');
      throw Exception('Failed to load courses: ${e.message}');
    } catch (e) {
      print('CourseService: Unexpected error getting courses: $e');
      throw Exception('Failed to load courses: $e');
    }
  }

  Future<Course> getCourse(int id) async {
    try {
      final response = await _apiService.dio.get('/courses/read.php?id=$id');
      return Course.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load course: $e');
    }
  }

  Future<Course> createCourse(Course course) async {
    try {
      final response = await _apiService.dio.post(
        '/courses/create.php',
        data: course.toJson(),
      );
      return Course.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create course: $e');
    }
  }

  Future<void> updateCourse(Course course) async {
    try {
      await _apiService.dio.put(
        '/courses/update.php',
        data: course.toJson(),
      );
    } catch (e) {
      throw Exception('Failed to update course: $e');
    }
  }

  Future<void> deleteCourse(int id) async {
    try {
      await _apiService.dio.delete('/courses/delete.php?id=$id');
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
