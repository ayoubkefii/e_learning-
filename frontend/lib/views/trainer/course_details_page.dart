import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/course.dart';
import '../../models/module.dart' as module_model;
import '../../services/course_service.dart';
import '../../services/module_service.dart';
import 'create_module_page.dart';

class CourseDetailsPage extends StatefulWidget {
  final int courseId;

  const CourseDetailsPage({super.key, required this.courseId});

  @override
  State<CourseDetailsPage> createState() => _CourseDetailsPageState();
}

class _CourseDetailsPageState extends State<CourseDetailsPage> {
  late Future<Course> _courseFuture;
  late Future<List<module_model.Module>> _modulesFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final courseService = context.read<CourseService>();
    final moduleService = context.read<ModuleService>();
    _courseFuture = courseService.getCourse(widget.courseId);
    _modulesFuture = moduleService.getModulesByCourse(widget.courseId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/trainer/courses/create-module',
                arguments: widget.courseId,
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _loadData();
          });
        },
        child: FutureBuilder<Course>(
          future: _courseFuture,
          builder: (context, courseSnapshot) {
            if (courseSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (courseSnapshot.hasError) {
              return Center(
                child: Text('Error: ${courseSnapshot.error}'),
              );
            }

            final course = courseSnapshot.data!;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    course.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Modules',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<List<module_model.Module>>(
                    future: _modulesFuture,
                    builder: (context, modulesSnapshot) {
                      if (modulesSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (modulesSnapshot.hasError) {
                        return Center(
                          child: Text('Error: ${modulesSnapshot.error}'),
                        );
                      }

                      final modules = modulesSnapshot.data!;

                      if (modules.isEmpty) {
                        return const Center(
                          child: Text('No modules available'),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: modules.length,
                        itemBuilder: (context, index) {
                          final module = modules[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(module.title),
                              subtitle: Text(module.description),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                                onSelected: (value) {
                                  // TODO: Implement edit and delete functionality
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
