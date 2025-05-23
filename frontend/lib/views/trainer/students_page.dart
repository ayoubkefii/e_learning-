import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final TextEditingController _searchController = TextEditingController();
  List<User> _students = [];
  List<User> _filteredStudents = [];
  bool _isLoading = true;
  String? _error;
  bool _showEnrolledOnly = false;
  bool _showActiveOnly = false;
  late final ApiService _apiService;

  final List<String> _filters = [
    'All',
    'Enrolled',
    'Not Enrolled',
    'Active',
    'Inactive'
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _initApiService();
    _loadStudents();
  }

  Future<void> _initApiService() async {
    final prefs = await SharedPreferences.getInstance();
    _apiService = ApiService(
      baseUrl: 'http://localhost/e_learning/api',
      prefs: prefs,
    );
  }

  Future<void> _loadStudents() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final students = await _apiService.getStudents();
      setState(() {
        _students = students;
        _filteredStudents = students;
        _isLoading = false;
      });
      _controller.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterStudents(String query) {
    setState(() {
      _filteredStudents = _students.where((student) {
        final matchesSearch = query.isEmpty ||
            student.name?.toLowerCase().contains(query.toLowerCase()) == true ||
            student.email?.toLowerCase().contains(query.toLowerCase()) ==
                true ||
            student.username?.toLowerCase().contains(query.toLowerCase()) ==
                true;

        final matchesEnrollment =
            !_showEnrolledOnly || student.isEnrolled == true;
        final matchesActive = !_showActiveOnly || student.isActive == true;

        return matchesSearch && matchesEnrollment && matchesActive;
      }).toList();
    });
  }

  Future<void> _handleStudentAction(String action, User student) async {
    try {
      switch (action) {
        case 'view':
          final details = await _apiService.getStudentDetails(student.id!);
          if (mounted) {
            // TODO: Navigate to student details page
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Viewing details for ${details.name}')),
            );
          }
          break;

        case 'edit':
          if (mounted) {
            // TODO: Navigate to edit student page
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Editing ${student.name}')),
            );
          }
          break;

        case 'delete':
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Student'),
              content: Text('Are you sure you want to delete ${student.name}?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );

          if (confirmed == true) {
            await _apiService.deleteStudent(student.id!);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${student.name} deleted successfully')),
              );
              _loadStudents();
            }
          }
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: theme.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Students'),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.primaryColor,
                          theme.primaryColor.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  const Center(
                    child: Icon(
                      Icons.people,
                      size: 100,
                      color: Colors.white24,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            theme.primaryColor.withOpacity(0.8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => _filterStudents(value),
                        decoration: InputDecoration(
                          hintText: 'Search students...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _filters.map((filter) {
                            final isSelected = filter == _filters[0];
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: FilterChip(
                                label: Text(filter),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _showEnrolledOnly = filter == 'Enrolled';
                                    _showActiveOnly = filter == 'Active';
                                    _filterStudents(_searchController.text);
                                  });
                                },
                                backgroundColor: Colors.grey[100],
                                selectedColor:
                                    theme.primaryColor.withOpacity(0.2),
                                checkmarkColor: theme.primaryColor,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? theme.primaryColor
                                      : Colors.grey[600],
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_filteredStudents.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No students found',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try adjusting your search or filters',
                      style: TextStyle(
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final student = _filteredStudents[index];
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: theme.primaryColor,
                              child: Text(
                                student.name?.substring(0, 1).toUpperCase() ??
                                    'S',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              student.name ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(student.email ?? 'No email'),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: student.isEnrolled == true
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.orange.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        student.isEnrolled == true
                                            ? 'Enrolled'
                                            : 'Not Enrolled',
                                        style: TextStyle(
                                          color: student.isEnrolled == true
                                              ? Colors.green
                                              : Colors.orange,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: student.isActive == true
                                            ? Colors.blue.withOpacity(0.1)
                                            : Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        student.isActive == true
                                            ? 'Active'
                                            : 'Inactive',
                                        style: TextStyle(
                                          color: student.isActive == true
                                              ? Colors.blue
                                              : Colors.red,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (action) =>
                                  _handleStudentAction(action, student),
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'view',
                                  child: Row(
                                    children: [
                                      Icon(Icons.visibility),
                                      SizedBox(width: 8),
                                      Text('View Details'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete',
                                          style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: _filteredStudents.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
