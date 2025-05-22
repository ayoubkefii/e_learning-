import 'package:dio/dio.dart';
import '../models/lesson.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

class LessonService {
  final Dio _dio;
  final String baseUrl = 'http://localhost/e_learning/backend/api';

  LessonService() : _dio = Dio() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        print('Making request to: ${options.uri}');
        print('Request headers: ${options.headers}');
        print('Request data: ${options.data}');
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
        return handler.next(error);
      },
    ));
  }

  Future<List<Lesson>> getLessonsByModule(int moduleId) async {
    try {
      print('Fetching lessons for module $moduleId...');
      final response = await _dio.get(
        '$baseUrl/lessons/read_by_module.php',
        queryParameters: {'module_id': moduleId},
        options: Options(
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      print('Lessons response status: ${response.statusCode}');
      print('Lessons response data: ${response.data}');

      if (response.statusCode == 200) {
        if (response.data is Map && response.data['records'] is List) {
          return (response.data['records'] as List)
              .map((lesson) => Lesson.fromJson(lesson))
              .toList();
        }
        return [];
      } else if (response.statusCode == 404) {
        return [];
      }

      throw Exception(
          'Failed to load lessons: ${response.data['message'] ?? 'Unknown error'}');
    } on DioException catch (e) {
      print('DioError getting lessons:');
      print('Error type: ${e.type}');
      print('Error message: ${e.message}');
      print('Error response: ${e.response?.data}');

      if (e.type == DioExceptionType.connectionError) {
        throw Exception(
            'Unable to connect to the server. Please check if XAMPP is running and Apache is started.');
      }

      if (e.response?.data is String &&
          e.response!.data.toString().contains('<br/>')) {
        throw Exception(
            'Server error: PHP error detected. Please check server logs.');
      }

      throw Exception('Failed to load lessons: ${e.message}');
    } catch (e) {
      print('Unexpected error getting lessons: $e');
      throw Exception('Failed to load lessons: $e');
    }
  }

  Future<Lesson> createLesson(
    Map<String, dynamic> lessonData, {
    PlatformFile? videoFile,
    List<PlatformFile>? documentFiles,
  }) async {
    try {
      print('Creating lesson with data: $lessonData');
      FormData formData = FormData.fromMap({
        'module_id': lessonData['module_id'].toString(),
        'title': lessonData['title'],
        'content': lessonData['content'],
      });

      // Add duration only if it exists in lessonData
      if (lessonData.containsKey('duration') &&
          lessonData['duration'] != null) {
        formData.fields
            .add(MapEntry('duration', lessonData['duration'].toString()));
      }

      // Handle video upload
      if (videoFile != null && videoFile.bytes != null) {
        formData.files.add(MapEntry(
          'video',
          MultipartFile.fromBytes(
            videoFile.bytes!,
            filename: videoFile.name,
          ),
        ));
      }

      // Handle document uploads
      if (documentFiles != null) {
        for (var docFile in documentFiles) {
          if (docFile.bytes != null) {
            formData.files.add(MapEntry(
              'documents[]',
              MultipartFile.fromBytes(
                docFile.bytes!,
                filename: docFile.name,
              ),
            ));
          }
        }
      }

      final response = await _dio.post(
        '$baseUrl/lessons/create.php',
        data: formData,
        options: Options(
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      print('Create lesson response status: ${response.statusCode}');
      print('Create lesson response data: ${response.data}');

      if (response.statusCode == 201) {
        return Lesson.fromJson(response.data);
      }

      throw Exception(
          'Failed to create lesson: ${response.data['message'] ?? 'Unknown error'}');
    } on DioException catch (e) {
      print('DioError creating lesson:');
      print('Error type: ${e.type}');
      print('Error message: ${e.message}');
      print('Error response: ${e.response?.data}');

      if (e.type == DioExceptionType.connectionError) {
        throw Exception(
            'Unable to connect to the server. Please check if XAMPP is running and Apache is started.');
      }

      if (e.response?.data is String &&
          e.response!.data.toString().contains('<br/>')) {
        throw Exception(
            'Server error: PHP error detected. Please check server logs.');
      }

      throw Exception('Failed to create lesson: ${e.message}');
    } catch (e) {
      print('Unexpected error creating lesson: $e');
      throw Exception('Failed to create lesson: $e');
    }
  }

  Future<void> deleteLesson(int lessonId, int moduleId) async {
    try {
      print('Deleting lesson with id: $lessonId, module_id: $moduleId');
      final response = await _dio.post(
        '$baseUrl/lessons/delete.php',
        data: {
          'id': lessonId,
          'module_id': moduleId,
        },
        options: Options(
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      print('Delete lesson response status: ${response.statusCode}');
      print('Delete lesson response data: ${response.data}');

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to delete lesson: ${response.data['message'] ?? 'Unknown error'}');
      }
    } on DioException catch (e) {
      print('DioError deleting lesson:');
      print('Error type: ${e.type}');
      print('Error message: ${e.message}');
      print('Error response: ${e.response?.data}');

      if (e.type == DioExceptionType.connectionError) {
        throw Exception(
            'Unable to connect to the server. Please check if XAMPP is running and Apache is started.');
      }

      if (e.response?.data is String &&
          e.response!.data.toString().contains('<br/>')) {
        throw Exception(
            'Server error: PHP error detected. Please check server logs.');
      }

      throw Exception('Failed to delete lesson: ${e.message}');
    } catch (e) {
      print('Unexpected error deleting lesson: $e');
      throw Exception('Failed to delete lesson: $e');
    }
  }

  Future<Lesson> updateLesson(
    int lessonId,
    Map<String, dynamic> lessonData, {
    PlatformFile? videoFile,
    List<PlatformFile>? documentFiles,
  }) async {
    try {
      print('Updating lesson $lessonId with data: $lessonData');
      FormData formData = FormData.fromMap({
        'id': lessonId.toString(),
        'module_id': lessonData['module_id'].toString(),
        'title': lessonData['title'],
        'content': lessonData['content'],
      });

      // Add duration only if it exists in lessonData
      if (lessonData.containsKey('duration') &&
          lessonData['duration'] != null) {
        formData.fields
            .add(MapEntry('duration', lessonData['duration'].toString()));
      }

      if (videoFile != null && videoFile.bytes != null) {
        formData.files.add(MapEntry(
          'video',
          MultipartFile.fromBytes(
            videoFile.bytes!,
            filename: videoFile.name,
          ),
        ));
      }

      if (documentFiles != null) {
        for (var docFile in documentFiles) {
          if (docFile.bytes != null) {
            formData.files.add(MapEntry(
              'documents[]',
              MultipartFile.fromBytes(
                docFile.bytes!,
                filename: docFile.name,
              ),
            ));
          }
        }
      }

      final response = await _dio.post(
        '$baseUrl/lessons/update.php',
        data: formData,
        options: Options(
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      print('Update lesson response status: ${response.statusCode}');
      print('Update lesson response data: ${response.data}');

      if (response.statusCode == 200) {
        return Lesson.fromJson(response.data);
      }

      throw Exception(
          'Failed to update lesson: ${response.data['message'] ?? 'Unknown error'}');
    } on DioException catch (e) {
      print('DioError updating lesson:');
      print('Error type: ${e.type}');
      print('Error message: ${e.message}');
      print('Error response: ${e.response?.data}');

      if (e.type == DioExceptionType.connectionError) {
        throw Exception(
            'Unable to connect to the server. Please check if XAMPP is running and Apache is started.');
      }

      if (e.response?.data is String &&
          e.response!.data.toString().contains('<br/>')) {
        throw Exception(
            'Server error: PHP error detected. Please check server logs.');
      }

      throw Exception('Failed to update lesson: ${e.message}');
    } catch (e) {
      print('Unexpected error updating lesson: $e');
      throw Exception('Failed to update lesson: $e');
    }
  }
}
