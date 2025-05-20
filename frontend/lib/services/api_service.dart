import 'dart:convert';
import 'package:dio/dio.dart';
// ignore: unused_import
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// ignore: unused_import
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/course.dart';

class ApiService {
  final Dio dio;
  final String baseUrl;
  final SharedPreferences prefs;

  ApiService(this.prefs)
      : baseUrl = kIsWeb
            ? 'http://127.0.0.1/e_learning/backend/api'
            : 'http://10.0.2.2/e_learning/backend/api',
        dio = Dio(BaseOptions(
          baseUrl: kIsWeb
              ? 'http://127.0.0.1/e_learning/backend/api'
              : 'http://10.0.2.2/e_learning/backend/api',
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          validateStatus: (status) {
            return status! < 500;
          },
        )) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        print('Making request to: ${options.uri}');
        print('Request headers: ${options.headers}');
        print('Request data: ${options.data}');

        // Add token if available
        final token = prefs.getString('token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('Response received:');
        print('Status code: ${response.statusCode}');
        print('Response data: ${response.data}');
        return handler.next(response);
      },
      onError: (error, handler) {
        print('Request error:');
        print('Error type: ${error.type}');
        print('Error message: ${error.message}');
        print('Error response: ${error.response?.data}');
        print('Request URL: ${error.requestOptions.uri}');
        print('Request headers: ${error.requestOptions.headers}');
        print('Request data: ${error.requestOptions.data}');

        // Handle specific error types
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.sendTimeout) {
          return handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              error:
                  'Connection timed out. Please check your internet connection.',
              type: error.type,
            ),
          );
        }

        if (error.type == DioExceptionType.connectionError) {
          String errorMessage = 'Unable to connect to the server.';
          if (error.message?.contains('XMLHttpRequest') ?? false) {
            errorMessage =
                'CORS error: Please ensure the server is properly configured for cross-origin requests. Try clearing your browser cache and refreshing the page.';
          } else {
            errorMessage =
                'Connection error. Please check if XAMPP is running and Apache is started.';
          }
          return handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              error: errorMessage,
              type: error.type,
            ),
          );
        }

        return handler.next(error);
      },
    ));
  }

  // Authentication
  Future<User> login(String email, String password) async {
    try {
      print('Attempting login with:');
      print('Email: $email');

      final response = await dio.post(
        '/auth/login.php',
        data: jsonEncode({
          'email': email,
          'password': password,
        }),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      print('Login response status: ${response.statusCode}');
      print('Login response data: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final userData = response.data['user'];
        final token = response.data['jwt'];

        if (userData == null) {
          throw Exception('Invalid response format: user data is missing');
        }

        final user = User.fromJson(userData).copyWith(token: token);
        prefs.setString('token', token);
        return user;
      } else {
        final errorMessage = response.data?['message'] ?? 'Login failed';
        throw Exception(errorMessage);
      }
    } on DioException catch (e) {
      print('DioError during login:');
      print('Error type: ${e.type}');
      print('Error message: ${e.message}');
      print('Error response: ${e.response?.data}');
      print('Request URL: ${e.requestOptions.uri}');
      print('Request headers: ${e.requestOptions.headers}');
      print('Request data: ${e.requestOptions.data}');

      if (e.response?.data != null && e.response?.data['message'] != null) {
        throw Exception(e.response?.data['message']);
      }
      throw Exception('Login failed: ${e.message}');
    } catch (e) {
      print('Unexpected error during login: $e');
      throw Exception('Login failed: $e');
    }
  }

  Future<void> signup(
      String username, String email, String password, String role) async {
    try {
      print('Attempting signup with:');
      print('Username: $username');
      print('Email: $email');
      print('Role: $role');

      final response = await dio.post(
        '/auth/register.php',
        data: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'role': role,
        }),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      print('Signup response status: ${response.statusCode}');
      print('Signup response data: ${response.data}');

      if (response.statusCode != 201) {
        final errorMessage = response.data['message'] ?? 'Signup failed';
        throw Exception(errorMessage);
      }
    } on DioException catch (e) {
      print('DioError during signup:');
      print('Error type: ${e.type}');
      print('Error message: ${e.message}');
      print('Error response: ${e.response?.data}');
      print('Request URL: ${e.requestOptions.uri}');
      print('Request headers: ${e.requestOptions.headers}');
      print('Request data: ${e.requestOptions.data}');

      if (e.response?.data != null && e.response?.data['message'] != null) {
        throw Exception(e.response?.data['message']);
      }
      throw Exception('Signup failed: ${e.message}');
    } catch (e) {
      print('Unexpected error during signup: $e');
      throw Exception('Signup failed: $e');
    }
  }

  Future<void> logout() async {
    prefs.remove('token');
  }

  // Courses
  Future<List<Course>> getCourses() async {
    try {
      print('Fetching courses...');
      final token = prefs.getString('token');
      print('Using token: $token');

      final response = await dio.get(
        '/courses/list.php',
        options: Options(
          headers: {
            'Authorization': token != null ? 'Bearer $token' : '',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      print('Courses response status: ${response.statusCode}');
      print('Courses response data: ${response.data}');

      if (response.statusCode == 200) {
        if (response.data is Map && response.data['records'] is List) {
          return (response.data['records'] as List)
              .map((json) => Course.fromJson(json))
              .toList();
        } else {
          print('Unexpected response format: ${response.data}');
          if (response.data is String &&
              response.data.toString().contains('<br/>')) {
            throw Exception(
                'Server error: PHP error detected. Please check server logs.');
          }
          throw Exception('Invalid response format');
        }
      } else if (response.statusCode == 404) {
        // No courses found, return empty list
        return [];
      }
      throw Exception('Failed to load courses: ${response.statusCode}');
    } on DioException catch (e) {
      print('DioError getting courses:');
      print('Error type: ${e.type}');
      print('Error message: ${e.message}');
      print('Error response: ${e.response?.data}');
      print('Request URL: ${e.requestOptions.uri}');
      print('Request headers: ${e.requestOptions.headers}');

      if (e.type == DioExceptionType.connectionError) {
        throw Exception(
            'Failed to connect to server. Please check your internet connection and try again.');
      }

      // Check if the response contains HTML (indicating a PHP error)
      if (e.response?.data is String &&
          e.response!.data.toString().contains('<br/>')) {
        throw Exception(
            'Server error: PHP error detected. Please check server logs.');
      }

      throw Exception('Failed to load courses: ${e.message}');
    } catch (e) {
      print('Unexpected error getting courses: $e');
      throw Exception('Failed to load courses: $e');
    }
  }

  Future<Course> getCourse(int id) async {
    try {
      final response = await dio.get('/courses/get.php?id=$id');
      if (response.statusCode == 200) {
        return Course.fromJson(response.data);
      }
      throw Exception('Failed to load course');
    } catch (e) {
      throw Exception('Failed to load course: $e');
    }
  }

  Future<Course> createCourse(Course course) async {
    try {
      print('Creating course with data: ${course.toJson()}');

      final response = await dio.post(
        '/courses/create.php',
        data: course.toJson(),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      print('Create course response status: ${response.statusCode}');
      print('Create course response data: ${response.data}');

      if (response.statusCode == 201) {
        return Course.fromJson(response.data);
      }
      throw Exception(
          'Failed to create course: ${response.data['message'] ?? 'Unknown error'}');
    } catch (e) {
      print('Error creating course: $e');
      throw Exception('Failed to create course: $e');
    }
  }

  Future<void> updateCourse(Course course) async {
    try {
      final response = await dio.post(
        '/courses/update.php',
        data: course.toJson(),
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
      final response = await dio.post(
        '/courses/delete.php',
        data: {'id': id},
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to delete course');
      }
    } catch (e) {
      throw Exception('Failed to delete course: $e');
    }
  }

  // Quiz
  Future<void> submitQuizAttempt(int quizId, Map<int, int> answers) async {
    try {
      final response = await dio.post(
        '/progress/quiz_attempt.php',
        data: {
          'quiz_id': quizId,
          'answers': answers,
        },
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to submit quiz');
      }
    } catch (e) {
      throw Exception('Failed to submit quiz: $e');
    }
  }

  // Progress
  Future<Map<String, dynamic>> getUserProgress() async {
    try {
      final response = await dio.get('/progress/get.php');
      if (response.statusCode == 200) {
        return response.data;
      }
      throw Exception('Failed to load progress');
    } catch (e) {
      throw Exception('Failed to load progress: $e');
    }
  }

  Future<void> updateLessonProgress(int lessonId, String status) async {
    try {
      final response = await dio.post(
        '/progress/update.php',
        data: {
          'lesson_id': lessonId,
          'status': status,
        },
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update progress');
      }
    } catch (e) {
      throw Exception('Failed to update progress: $e');
    }
  }

  Future<Response> post(String endpoint, {Map<String, dynamic>? data}) async {
    try {
      final token = prefs.getString('token');
      final response = await dio.post(
        endpoint,
        data: data,
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

      // If this is a login response, handle the token
      if (endpoint == '/auth/login.php' && response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('token')) {
          prefs.setString('token', responseData['token']);
        }
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }
}
