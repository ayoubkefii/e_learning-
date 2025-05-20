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
      final response = await _apiService.dio.get(
        '/modules/read_by_course.php',
        queryParameters: {'course_id': courseId},
        options: Options(
          headers: {
            'Accept': 'application/json',
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
          return (response.data['records'] as List)
              .map((json) => Module.fromJson(json))
              .toList();
        }
        return [];
      }
      throw Exception(
          'Failed to load modules: ${response.data['message'] ?? 'Unknown error'}');
    } catch (e) {
      print('ModuleService: Error getting modules: $e');
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
