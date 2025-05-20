import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/auth_provider.dart';
import 'providers/course_provider.dart';
import 'services/api_service.dart';
import 'services/course_service.dart';
import 'services/module_service.dart';
import 'views/auth/login_page.dart';
import 'views/auth/signup_page.dart';
import 'views/learner/learner_dashboard.dart';
import 'views/trainer/trainer_dashboard.dart';
import 'views/trainer/course_list_page.dart';
import 'views/trainer/create_course_page.dart';
import 'views/trainer/course_details_page.dart';
import 'views/trainer/create_module_page.dart';

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
        Provider<CourseService>(
          create: (_) => courseService,
        ),
        Provider<ModuleService>(
          create: (_) => moduleService,
        ),
        Provider<ApiService>(
          create: (_) => apiService,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SUP4 DEV – FlutterLearn',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/learner-dashboard': (context) => const LearnerDashboard(),
        '/trainer-dashboard': (context) => const TrainerDashboard(),
        '/trainer/courses': (context) => const CourseListPage(),
        '/trainer/courses/create': (context) => const CreateCoursePage(),
        '/trainer/courses/details': (context) => CourseDetailsPage(
              courseId: ModalRoute.of(context)!.settings.arguments as int,
            ),
        '/trainer/courses/modules/create': (context) => CreateModulePage(
              courseId: ModalRoute.of(context)!.settings.arguments as int,
            ),
      },
    );
  }
}
