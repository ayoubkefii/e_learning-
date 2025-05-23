import 'dart:convert';
import 'package:dio/dio.dart';
// ignore: unused_import
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// ignore: unused_import
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/course.dart' as course_models;
import '../models/quiz.dart' as quiz_models;
import '../models/quiz_attempt.dart';
import '../models/quiz_answer.dart';
import '../models/lesson.dart' as lesson_models;
import '../models/module.dart' as module_models;

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
      print('DEBUG: Attempting login for email: $email');
      final response = await dio.post(
        '/auth/login.php',
        data: {
          'email': email,
          'password': password,
        },
      );

      print('DEBUG: Login response status: ${response.statusCode}');
      print('DEBUG: Raw response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        print('DEBUG: Parsed login data: $data');

        if (data['message'] == 'Login successful.') {
          final userData = data['user'];
          print('DEBUG: User data from response: $userData');

          // Store token first
          final token = data['jwt'];
          if (token == null || token.isEmpty) {
            print('DEBUG: No token received in login response');
            throw Exception('Login failed: No token received');
          }

          print('DEBUG: Storing token: $token');
          await prefs.setString('token', token);
          print('DEBUG: Token stored in SharedPreferences');

          // Create user object with token
          final user = User.fromJson(userData).copyWith(token: token);
          print('DEBUG: Created user object with token: ${user.toString()}');

          // Verify token was stored
          final storedToken = prefs.getString('token');
          print('DEBUG: Verified stored token: $storedToken');

          if (storedToken != token) {
            print('DEBUG: Token verification failed');
            throw Exception('Login failed: Token storage error');
          }

          return user;
        } else {
          throw Exception(data['error'] ?? 'Login failed');
        }
      } else {
        throw Exception('Login failed: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Login error: $e');
      rethrow;
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
  Future<List<course_models.Course>> getCourses() async {
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
              .map((json) => course_models.Course.fromJson(json))
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

  Future<course_models.Course> getCourse(int id) async {
    try {
      final response = await dio.get('/courses/get.php?id=$id');
      if (response.statusCode == 200) {
        return course_models.Course.fromJson(response.data);
      }
      throw Exception('Failed to load course');
    } catch (e) {
      throw Exception('Failed to load course: $e');
    }
  }

  Future<course_models.Course> createCourse(course_models.Course course) async {
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
        return course_models.Course.fromJson(response.data);
      }
      throw Exception(
          'Failed to create course: ${response.data['message'] ?? 'Unknown error'}');
    } catch (e) {
      print('Error creating course: $e');
      throw Exception('Failed to create course: $e');
    }
  }

  Future<void> updateCourse(course_models.Course course) async {
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
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      // If this is a login response, handle the token
      if (endpoint == '/auth/login.php' && response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('jwt')) {
          await prefs.setString('token', responseData['jwt']);
        }
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<User>> getUsers() async {
    try {
      print('DEBUG: Getting token from SharedPreferences');
      final token = prefs.getString('token');
      print('DEBUG: Token from SharedPreferences: $token');

      if (token == null || token.isEmpty) {
        print('DEBUG: No token found in SharedPreferences');
        throw Exception('No token found. Please log in again.');
      }

      print('DEBUG: Making request to users/list.php');
      final response = await dio.get(
        '/users/list.php',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      print('DEBUG: Response status: ${response.statusCode}');
      print('DEBUG: Response data: ${response.data}');

      if (response.statusCode == 200) {
        if (response.data is Map && response.data['records'] is List) {
          final List<dynamic> records = response.data['records'];
          return records.map((record) => User.fromJson(record)).toList();
        } else {
          print('DEBUG: Unexpected response format: ${response.data}');
          throw Exception('Invalid response format from server');
        }
      } else if (response.statusCode == 401) {
        print('DEBUG: Unauthorized access. Token may be invalid.');
        throw Exception('Unauthorized access. Please log in again.');
      } else {
        final errorMessage = response.data['message'] ?? 'Failed to load users';
        print('DEBUG: Error response: $errorMessage');
        throw Exception(errorMessage);
      }
    } on DioException catch (e) {
      print('DEBUG: DioError in getUsers:');
      print('Error type: ${e.type}');
      print('Error message: ${e.message}');
      print('Error response: ${e.response?.data}');

      if (e.type == DioExceptionType.connectionError) {
        throw Exception(
            'Failed to connect to server. Please check your internet connection.');
      }

      throw Exception('Failed to load users: ${e.message}');
    } catch (e) {
      print('DEBUG: Error in getUsers: $e');
      rethrow;
    }
  }

  Future<User> getStudentDetails(int studentId) async {
    try {
      final token = prefs.getString('token');
      final response = await dio.get(
        '/students/get.php',
        queryParameters: {'id': studentId},
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return User.fromJson(response.data['data']);
      }
      throw Exception('Failed to load student details');
    } catch (e) {
      throw Exception('Failed to load student details: $e');
    }
  }

  Future<void> updateStudent(int studentId, Map<String, dynamic> data) async {
    try {
      final token = prefs.getString('token');
      final response = await dio.post(
        '/students/update.php',
        data: {'id': studentId, ...data},
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update student');
      }
    } catch (e) {
      throw Exception('Failed to update student: $e');
    }
  }

  Future<void> deleteStudent(int studentId) async {
    try {
      final token = prefs.getString('token');
      final response = await dio.post(
        '/students/delete.php',
        data: {'id': studentId},
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete student');
      }
    } catch (e) {
      throw Exception('Failed to delete student: $e');
    }
  }

  // Quiz Methods
  Future<quiz_models.Quiz> getQuiz(int quizId) async {
    try {
      final token = prefs.getString('token');
      if (token == null || token.isEmpty) {
        throw Exception('No token found. Please log in again.');
      }

      final response = await dio.get(
        '/quizzes/get.php',
        queryParameters: {'id': quizId},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return quiz_models.Quiz.fromJson(response.data);
      } else {
        throw Exception('Failed to load quiz: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getQuiz: $e');
      rethrow;
    }
  }

  Future<quiz_models.QuizAttempt> startQuizAttempt(int quizId) async {
    try {
      final token = prefs.getString('token');
      if (token == null || token.isEmpty) {
        throw Exception('No token found. Please log in again.');
      }

      final response = await dio.post(
        '/quizzes/start.php',
        data: {'quiz_id': quizId},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return quiz_models.QuizAttempt.fromJson(response.data);
      } else {
        throw Exception('Failed to start quiz: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in startQuizAttempt: $e');
      rethrow;
    }
  }

  Future<quiz_models.QuizAttempt> submitQuizAnswers(
      int attemptId, List<quiz_models.QuizAnswer> answers) async {
    try {
      final token = prefs.getString('token');
      if (token == null || token.isEmpty) {
        throw Exception('No token found. Please log in again.');
      }

      final response = await dio.post(
        '/quizzes/submit.php',
        data: {
          'attempt_id': attemptId,
          'answers': answers.map((a) => a.toJson()).toList(),
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return quiz_models.QuizAttempt.fromJson(response.data);
      } else {
        throw Exception('Failed to submit quiz: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in submitQuizAnswers: $e');
      rethrow;
    }
  }

  Future<List<quiz_models.QuizAttempt>> getQuizAttempts(int quizId) async {
    try {
      final token = prefs.getString('token');
      if (token == null || token.isEmpty) {
        throw Exception('No token found. Please log in again.');
      }

      final response = await dio.get(
        '/quizzes/attempts.php',
        queryParameters: {'quiz_id': quizId},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> attempts = response.data['attempts'];
        return attempts
            .map((a) => quiz_models.QuizAttempt.fromJson(a))
            .toList();
      } else {
        throw Exception('Failed to load quiz attempts: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getQuizAttempts: $e');
      rethrow;
    }
  }

  // Quiz Management Methods
  Future<List<quiz_models.Quiz>> getCourseQuizzes(int courseId) async {
    try {
      final token = prefs.getString('token');
      if (token == null || token.isEmpty) {
        throw Exception('No token found. Please log in again.');
      }

      final response = await dio.get(
        '/quizzes/course.php',
        queryParameters: {'course_id': courseId},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> quizzes = response.data['quizzes'];
        return quizzes.map((q) => quiz_models.Quiz.fromJson(q)).toList();
      } else {
        throw Exception('Failed to load quizzes: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getCourseQuizzes: $e');
      rethrow;
    }
  }

  Future<quiz_models.Quiz> createQuiz(quiz_models.Quiz quiz) async {
    try {
      final token = prefs.getString('token');
      if (token == null || token.isEmpty) {
        throw Exception('No token found. Please log in again.');
      }

      final response = await dio.post(
        '/quizzes/create.php',
        data: quiz.toJson(),
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 201) {
        return quiz_models.Quiz.fromJson(response.data);
      } else {
        throw Exception('Failed to create quiz: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in createQuiz: $e');
      rethrow;
    }
  }

  Future<quiz_models.Quiz> updateQuiz(quiz_models.Quiz quiz) async {
    try {
      final token = prefs.getString('token');
      if (token == null || token.isEmpty) {
        throw Exception('No token found. Please log in again.');
      }

      final response = await dio.post(
        '/quizzes/update.php',
        data: quiz.toJson(),
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return quiz_models.Quiz.fromJson(response.data);
      } else {
        throw Exception('Failed to update quiz: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in updateQuiz: $e');
      rethrow;
    }
  }

  Future<void> deleteQuiz(int quizId) async {
    try {
      final token = prefs.getString('token');
      if (token == null || token.isEmpty) {
        throw Exception('No token found. Please log in again.');
      }

      final response = await dio.post(
        '/quizzes/delete.php',
        data: {'id': quizId},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete quiz: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in deleteQuiz: $e');
      rethrow;
    }
  }

  // Course Management Methods
  Future<bool> isCourseOwner(int courseId) async {
    try {
      final token = prefs.getString('token');
      if (token == null) {
        throw Exception('No token found');
      }

      final response = await dio.get(
        '/courses/owner.php',
        queryParameters: {'id': courseId},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        return response.data['is_owner'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error checking course ownership: $e');
      return false;
    }
  }

  // Lesson Methods
  Future<lesson_models.Lesson> getLesson(int lessonId) async {
    try {
      final token = prefs.getString('token');
      if (token == null || token.isEmpty) {
        throw Exception('No token found. Please log in again.');
      }

      final response = await dio.get(
        '/lessons/get.php',
        queryParameters: {'id': lessonId},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return lesson_models.Lesson.fromJson(response.data);
      } else {
        throw Exception('Failed to load lesson: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getLesson: $e');
      rethrow;
    }
  }

  // Module Methods
  Future<module_models.Module> getModule(int moduleId) async {
    try {
      final token = prefs.getString('token');
      if (token == null || token.isEmpty) {
        throw Exception('No token found. Please log in again.');
      }

      final response = await dio.get(
        '/modules/get.php',
        queryParameters: {'id': moduleId},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return module_models.Module.fromJson(response.data);
      } else {
        throw Exception('Failed to load module: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getModule: $e');
      rethrow;
    }
  }
}
