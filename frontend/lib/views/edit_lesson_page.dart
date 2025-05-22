import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/lesson.dart';
import '../services/lesson_service.dart';

class EditLessonPage extends StatefulWidget {
  final int moduleId;
  final Lesson? lesson;

  const EditLessonPage({
    Key? key,
    required this.moduleId,
    this.lesson,
  }) : super(key: key);

  @override
  _EditLessonPageState createState() => _EditLessonPageState();
}

class _EditLessonPageState extends State<EditLessonPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _durationController = TextEditingController();
  final _lessonService = LessonService();
  bool _isLoading = false;
  PlatformFile? _videoFile;
  List<PlatformFile> _documentFiles = [];

  @override
  void initState() {
    super.initState();
    if (widget.lesson != null) {
      _titleController.text = widget.lesson!.title;
      _contentController.text = widget.lesson!.content;
      if (widget.lesson!.duration != null) {
        _durationController.text = widget.lesson!.duration.toString();
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _saveLesson() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final lessonData = {
        'module_id': widget.moduleId.toString(),
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
      };

      // Only add duration if it's not empty and convert to string
      if (_durationController.text.isNotEmpty) {
        lessonData['duration'] = _durationController.text.trim();
      }

      if (widget.lesson == null) {
        await _lessonService.createLesson(
          lessonData,
          videoFile: _videoFile,
          documentFiles: _documentFiles.isNotEmpty ? _documentFiles : null,
        );
      } else {
        await _lessonService.updateLesson(
          widget.lesson!.id,
          lessonData,
          videoFile: _videoFile,
          documentFiles: _documentFiles.isNotEmpty ? _documentFiles : null,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.lesson == null
                ? 'Lesson created successfully'
                : 'Lesson updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving lesson: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickVideo() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
        withData: true,
      );

      if (result != null) {
        setState(() {
          _videoFile = result.files.first;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking video: $e')),
        );
      }
    }
  }

  Future<void> _pickDocuments() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        allowMultiple: true,
        withData: true,
      );

      if (result != null) {
        setState(() {
          _documentFiles.addAll(result.files);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking documents: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson == null ? 'Create Lesson' : 'Edit Lesson'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        labelText: 'Content',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter content';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _durationController,
                      decoration: const InputDecoration(
                        labelText: 'Duration (minutes)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                    if (_videoFile != null) ...[
                      ListTile(
                        leading: const Icon(Icons.video_library),
                        title: Text(_videoFile!.name),
                        trailing: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _videoFile = null;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    ElevatedButton.icon(
                      onPressed: _pickVideo,
                      icon: const Icon(Icons.video_library),
                      label: Text(
                          _videoFile == null ? 'Add Video' : 'Change Video'),
                    ),
                    const SizedBox(height: 16),
                    if (_documentFiles.isNotEmpty) ...[
                      const Text(
                        'Selected Documents:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _documentFiles.length,
                        itemBuilder: (context, index) {
                          final doc = _documentFiles[index];
                          return ListTile(
                            leading: const Icon(Icons.description),
                            title: Text(doc.name),
                            trailing: IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _documentFiles.removeAt(index);
                                });
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                    ElevatedButton.icon(
                      onPressed: _pickDocuments,
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Add Documents'),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _saveLesson,
                      child: Text(
                        widget.lesson == null
                            ? 'Create Lesson'
                            : 'Update Lesson',
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
