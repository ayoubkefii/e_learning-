import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/module.dart';
import 'api_service.dart';

class ModuleService {
  // ignore: unused_field
  final ApiService _apiService;
  final Dio _dio;

  ModuleService(this._apiService) : _dio = _apiService.dio;

  Future<List<Module>> getModulesByCourse(int courseId) async {
    try {
      final response =
          await _dio.get('/modules/read_by_course.php?course_id=$courseId');
      if (response.statusCode == 200) {
        final List<dynamic> modulesJson = response.data['records'];
        return modulesJson.map((json) => Module.fromJson(json)).toList();
      }
      throw Exception('Failed to load modules');
    } catch (e) {
      print('Error getting modules: $e');
      rethrow;
    }
  }

  Future<Module> createModule(Module module) async {
    try {
      final response = await _dio.post(
        '/modules/create.php',
        data: jsonEncode(module.toJson()),
      );
      if (response.statusCode == 201) {
        return module;
      }
      throw Exception('Failed to create module');
    } catch (e) {
      print('Error creating module: $e');
      rethrow;
    }
  }

  Future<Module> updateModule(Module module) async {
    try {
      final response = await _dio.put(
        '/modules/update.php',
        data: jsonEncode(module.toJson()),
      );
      if (response.statusCode == 200) {
        return module;
      }
      throw Exception('Failed to update module');
    } catch (e) {
      print('Error updating module: $e');
      rethrow;
    }
  }

  Future<void> deleteModule(int id, int courseId) async {
    try {
      final response =
          await _dio.delete('/modules/delete.php?id=$id&course_id=$courseId');
      if (response.statusCode != 200) {
        throw Exception('Failed to delete module');
      }
    } catch (e) {
      print('Error deleting module: $e');
      rethrow;
    }
  }
}
