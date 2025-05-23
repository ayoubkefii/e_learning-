import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/auth_provider.dart';
import 'providers/course_provider.dart';
import 'services/api_service.dart';
import 'services/course_service.dart';
import 'services/module_service.dart';
import 'models/module.dart' as module_model;
import 'models/course.dart';
import 'views/auth/login_page.dart';
import 'views/auth/signup_page.dart';
import 'views/learner/learner_dashboard.dart';
import 'views/trainer/trainer_dashboard.dart';
import 'views/trainer/course_list_page.dart';
import 'views/trainer/create_course_page.dart';
import 'views/trainer/create_module_page.dart';
import 'views/trainer/edit_course_page.dart';
import 'views/trainer/edit_module_page.dart';
import 'views/course_details_page.dart';
import 'views/home_page.dart';
import 'views/trainer/users_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final apiService = ApiService(prefs);
  final courseService = CourseService(apiService);
  final moduleService = ModuleService(apiService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => CourseProvider(courseService),
        ),
        Provider<ApiService>(
          create: (_) => apiService,
        ),
        Provider<CourseService>(
          create: (_) => courseService,
        ),
        Provider<ModuleService>(
          create: (_) => moduleService,
        ),
      ],
      child: MaterialApp(
        title: 'E-Learning',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        initialRoute: '/login',
        routes: {
          '/': (context) => const HomePage(),
          '/login': (context) => const LoginPage(),
          '/signup': (context) => const SignupPage(),
          '/trainer-dashboard': (context) {
            final authProvider = context.read<AuthProvider>();
            if (!authProvider.isTrainer) {
              return const HomePage();
            }
            return const TrainerDashboard();
          },
          '/learner-dashboard': (context) => const LearnerDashboard(),
          '/course-details': (context) {
            final courseId = ModalRoute.of(context)!.settings.arguments as int;
            return CourseDetailsPage(courseId: courseId);
          },
          '/trainer/courses': (context) {
            final authProvider = context.read<AuthProvider>();
            if (!authProvider.isTrainer) {
              return const HomePage();
            }
            return const CourseListPage();
          },
          '/trainer/courses/create': (context) {
            final authProvider = context.read<AuthProvider>();
            if (!authProvider.isTrainer) {
              return const HomePage();
            }
            return const CreateCoursePage();
          },
          '/trainer/courses/edit': (context) {
            final authProvider = context.read<AuthProvider>();
            if (!authProvider.isTrainer) {
              return const HomePage();
            }
            final courseId = ModalRoute.of(context)!.settings.arguments as int;
            final courseProvider = context.read<CourseProvider>();
            return FutureBuilder<Course>(
              future: courseProvider.getCourse(courseId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Scaffold(
                    body: Center(
                      child: Text('Error: ${snapshot.error}'),
                    ),
                  );
                }
                return EditCoursePage(course: snapshot.data!);
              },
            );
          },
          '/trainer/courses/details': (context) {
            final courseId = ModalRoute.of(context)!.settings.arguments as int;
            return CourseDetailsPage(courseId: courseId);
          },
          '/trainer/modules/create': (context) {
            final authProvider = context.read<AuthProvider>();
            if (!authProvider.isTrainer) {
              return const HomePage();
            }
            return CreateModulePage(
              courseId: ModalRoute.of(context)!.settings.arguments as int,
            );
          },
          '/trainer/modules/edit': (context) {
            final authProvider = context.read<AuthProvider>();
            if (!authProvider.isTrainer) {
              return const HomePage();
            }
            final module = ModalRoute.of(context)!.settings.arguments
                as module_model.Module;
            return EditModulePage(module: module);
          },
          '/trainer/students': (context) {
            final authProvider = context.read<AuthProvider>();
            if (!authProvider.isTrainer) {
              return const HomePage();
            }
            return const UsersPage();
          },
        },
      ),
    ),
  );
}
