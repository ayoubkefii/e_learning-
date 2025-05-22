import 'package:flutter/material.dart';
import '../models/lesson.dart' as lesson_model;
import '../services/lesson_service.dart';
import '../models/module.dart';
import 'lesson_details_page.dart';
import 'edit_lesson_page.dart';

class ModuleDetailsPage extends StatefulWidget {
  final Module module;

  const ModuleDetailsPage({Key? key, required this.module}) : super(key: key);

  @override
  _ModuleDetailsPageState createState() => _ModuleDetailsPageState();
}

class _ModuleDetailsPageState extends State<ModuleDetailsPage> {
  final LessonService _lessonService = LessonService();
  bool _isLoading = true;
  List<lesson_model.Lesson> _lessons = [];
  String? _error;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final lessons = await _lessonService.getLessonsByModule(widget.module.id);
      setState(() {
        _lessons = lessons;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load lessons: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteLesson(lesson_model.Lesson lesson) async {
    setState(() => _isDeleting = true);
    try {
      await _lessonService.deleteLesson(lesson.id, widget.module.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lesson deleted successfully')),
      );
      _loadLessons();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete lesson: $e')),
      );
    } finally {
      setState(() => _isDeleting = false);
    }
  }

  Widget _buildLessonIcon(lesson_model.Lesson lesson) {
    if (lesson.videoUrl != null) {
      return const Icon(Icons.video_library);
    } else if (lesson.documents != null && lesson.documents!.isNotEmpty) {
      return const Icon(Icons.description);
    }
    return const Icon(Icons.article);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.module.title),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _lessons.isEmpty
                  ? const Center(child: Text('No lessons available'))
                  : ListView.builder(
                      itemCount: _lessons.length,
                      itemBuilder: (context, index) {
                        final lesson = _lessons[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: ListTile(
                            leading: _buildLessonIcon(lesson),
                            title: Text(lesson.title),
                            subtitle: Text(
                              lesson.duration != null
                                  ? 'Duration: ${lesson.duration} minutes'
                                  : 'Text content',
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (_isDeleting) return;
                                if (value == 'edit') {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditLessonPage(
                                        moduleId: widget.module.id,
                                        lesson: lesson,
                                      ),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadLessons();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Lesson updated successfully'),
                                          backgroundColor: Colors.green),
                                    );
                                  }
                                } else if (value == 'delete') {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Lesson'),
                                      content: Text(
                                        'Are you sure you want to delete "${lesson.title}"?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: _isDeleting
                                              ? null
                                              : () =>
                                                  Navigator.pop(context, true),
                                          child: _isDeleting
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child:
                                                      CircularProgressIndicator(
                                                          strokeWidth: 2),
                                                )
                                              : const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirmed == true) {
                                    await _deleteLesson(lesson);
                                  }
                                }
                              },
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
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LessonDetailsPage(
                                    lesson: lesson,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditLessonPage(
                moduleId: widget.module.id,
              ),
            ),
          );
          if (result == true) {
            _loadLessons();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
