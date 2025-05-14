import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'course_list_page.dart';

class TrainerDashboard extends StatelessWidget {
  const TrainerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trainer Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${user?.username}!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.school),
                title: const Text('My Courses'),
                subtitle: const Text('Manage your courses and content'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CourseListPage(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.analytics),
                title: const Text('Analytics'),
                subtitle:
                    const Text('View course statistics and student progress'),
                onTap: () {
                  // TODO: Navigate to analytics page
                },
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.people),
                title: const Text('Students'),
                subtitle: const Text('Manage student enrollments and progress'),
                onTap: () {
                  // TODO: Navigate to students page
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
