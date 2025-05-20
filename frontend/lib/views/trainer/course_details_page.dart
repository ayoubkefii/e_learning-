import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/course.dart';
import '../../models/module.dart' as module_model;
import '../../services/course_service.dart';
import '../../services/module_service.dart';
import 'create_module_page.dart';
import 'edit_course_page.dart';

class CourseDetailsPage extends StatefulWidget {
  final int courseId;

  const CourseDetailsPage({Key? key, required this.courseId}) : super(key: key);

  @override
  _CourseDetailsPageState createState() => _CourseDetailsPageState();
}

class _CourseDetailsPageState extends State<CourseDetailsPage> {
  late Future<Course> _courseFuture;
  late Future<List<module_model.Module>> _modulesFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final courseService = Provider.of<CourseService>(context, listen: false);
    final moduleService = Provider.of<ModuleService>(context, listen: false);
    _courseFuture = courseService.getCourse(widget.courseId);
    _modulesFuture = moduleService.getModulesByCourse(widget.courseId);
  }

  Future<void> _deleteCourse(Course course) async {
    final courseService = Provider.of<CourseService>(context, listen: false);

    try {
      setState(() => _isLoading = true);

      // Show confirmation dialog
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Course'),
          content: Text('Are you sure you want to delete "${course.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await courseService.deleteCourse(course.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Course deleted successfully')),
          );
          Navigator.of(context).pop(true); // Return true to indicate deletion
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete course: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Course>(
      future: _courseFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Course Details'),
            ),
            body: Center(
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        }

        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Course Details'),
            ),
            body: const Center(
              child: Text('Course not found'),
            ),
          );
        }

        final course = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text(course.title),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditCoursePage(course: course),
                    ),
                  );
                  if (result == true) {
                    _loadData(); // Refresh the data after edit
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/trainer/courses/modules/create',
                    arguments: widget.courseId,
                  );
                },
              ),
              if (_isLoading)
                const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteCourse(course),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleLarge,
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
                const SizedBox(height: 8),
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
          ),
        );
      },
    );
  }
}
