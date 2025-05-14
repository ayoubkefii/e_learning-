import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class LearnerDashboard extends StatelessWidget {
  const LearnerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learner Dashboard'),
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
                subtitle: const Text('View your enrolled courses'),
                onTap: () {
                  // TODO: Navigate to enrolled courses page
                },
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.assignment),
                title: const Text('Assignments'),
                subtitle: const Text('View and submit assignments'),
                onTap: () {
                  // TODO: Navigate to assignments page
                },
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.analytics),
                title: const Text('Progress'),
                subtitle: const Text('Track your learning progress'),
                onTap: () {
                  // TODO: Navigate to progress page
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
