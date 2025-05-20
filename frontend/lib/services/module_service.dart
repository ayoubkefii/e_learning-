import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/module.dart';
import 'api_service.dart';

class ModuleService {
  final ApiService _apiService;

  ModuleService(this._apiService);

  Future<List<Module>> getModulesByCourse(int courseId) async {
    try {
      print('ModuleService: Fetching modules for course $courseId...');

      // Get token from ApiService
      final token = _apiService.prefs.getString('token');
      print('ModuleService: Using token: $token');

      final response = await _apiService.dio.get(
        '/modules/read_by_course.php',
        queryParameters: {'course_id': courseId},
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

      print('ModuleService: Response status: ${response.statusCode}');
      print('ModuleService: Response data: ${response.data}');

      if (response.statusCode == 200) {
        if (response.data is Map && response.data['records'] is List) {
          final modules = (response.data['records'] as List)
              .map((json) => Module.fromJson(json))
              .toList();
          print('ModuleService: Successfully parsed ${modules.length} modules');
          return modules;
        } else {
          print('ModuleService: No modules found or invalid response format');
          return [];
        }
      } else if (response.statusCode == 404) {
        print('ModuleService: No modules found for course $courseId');
        return [];
      }

      final errorMessage =
          response.data is Map ? response.data['message'] : 'Unknown error';
      throw Exception('Failed to load modules: $errorMessage');
    } on DioException catch (e) {
      print('ModuleService: DioError getting modules:');
      print('Error type: ${e.type}');
      print('Error message: ${e.message}');
      print('Error response: ${e.response?.data}');
      print('Request URL: ${e.requestOptions.uri}');
      print('Request headers: ${e.requestOptions.headers}');

      if (e.type == DioExceptionType.connectionError) {
        throw Exception(
            'Unable to connect to the server. Please check if XAMPP is running and Apache is started.');
      }

      final errorMessage =
          e.response?.data is Map ? e.response?.data['message'] : e.message;
      throw Exception('Failed to load modules: $errorMessage');
    } catch (e) {
      print('ModuleService: Unexpected error getting modules: $e');
      throw Exception('Failed to load modules: $e');
    }
  }

  Future<Module> createModule(Module module) async {
    try {
      print('ModuleService: Creating module with data: ${module.toJson()}');

      final moduleData = {
        'course_id': module.courseId,
        'title': module.title,
        'description': module.description,
      };

      final response = await _apiService.dio.post(
        '/modules/create.php',
        data: moduleData,
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

      print('ModuleService: Create response status: ${response.statusCode}');
      print('ModuleService: Create response data: ${response.data}');

      if (response.statusCode == 201) {
        return Module.fromJson(response.data);
      }
      throw Exception(
          'Failed to create module: ${response.data['message'] ?? 'Unknown error'}');
    } catch (e) {
      print('ModuleService: Error creating module: $e');
      throw Exception('Failed to create module: $e');
    }
  }

  Future<void> updateModule(Module module) async {
    try {
      print('ModuleService: Updating module with data: ${module.toJson()}');
      final response = await _apiService.dio.post(
        '/modules/update.php',
        data: module.toJson(),
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

      print('ModuleService: Update response status: ${response.statusCode}');
      print('ModuleService: Update response data: ${response.data}');

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to update module: ${response.data['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('ModuleService: Error updating module: $e');
      throw Exception('Failed to update module: $e');
    }
  }

  Future<void> deleteModule(int id, int courseId) async {
    try {
      print('ModuleService: Deleting module $id from course $courseId');
      final response = await _apiService.dio.post(
        '/modules/delete.php',
        data: {
          'id': id,
          'course_id': courseId,
        },
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

      print('ModuleService: Delete response status: ${response.statusCode}');
      print('ModuleService: Delete response data: ${response.data}');

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to delete module: ${response.data['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('ModuleService: Error deleting module: $e');
      throw Exception('Failed to delete module: $e');
    }
  }
}
