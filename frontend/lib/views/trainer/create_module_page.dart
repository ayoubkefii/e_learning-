import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/module.dart';
import '../../services/module_service.dart';

class CreateModulePage extends StatefulWidget {
  final int courseId;

  const CreateModulePage({super.key, required this.courseId});

  @override
  State<CreateModulePage> createState() => _CreateModulePageState();
}

class _CreateModulePageState extends State<CreateModulePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createModule() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final moduleService = context.read<ModuleService>();
      final now = DateTime.now();
      final module = Module(
        id: 0, // This will be set by the backend
        courseId: widget.courseId,
        title: _titleController.text,
        description: _descriptionController.text,
        orderNumber: 0, // This will be set by the backend
        createdAt: now,
        updatedAt: now,
      );

      await moduleService.createModule(module);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Module created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating module: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Module'),
      ),
      body: Padding(
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
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _createModule,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Create Module'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
