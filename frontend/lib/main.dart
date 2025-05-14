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
import 'views/trainer/trainer_dashboard.dart';
import 'views/trainer/course_list_page.dart';
import 'views/trainer/create_course_page.dart';
import 'views/trainer/course_details_page.dart';
import 'views/trainer/create_module_page.dart';
import 'views/learner/learner_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(prefs),
        ),
        ChangeNotifierProvider(
          create: (_) => CourseProvider(prefs),
        ),
        Provider(
          create: (context) => ApiService(prefs),
        ),
        Provider(
          create: (context) => CourseService(context.read<ApiService>()),
        ),
        Provider(
          create: (context) => ModuleService(context.read<ApiService>()),
        ),
      ],
      child: MaterialApp(
        title: 'E-Learning Platform',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.poppinsTextTheme(
            Theme.of(context).textTheme,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.black),
            titleTextStyle: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginPage(),
          '/signup': (context) => const SignupPage(),
          '/trainer-dashboard': (context) => const TrainerDashboard(),
          '/learner-dashboard': (context) => const LearnerDashboard(),
          '/trainer/courses': (context) => const CourseListPage(),
          '/trainer/courses/create': (context) => const CreateCoursePage(),
          '/trainer/courses/details': (context) => CourseDetailsPage(
                courseId: ModalRoute.of(context)!.settings.arguments as int,
              ),
          '/trainer/courses/create-module': (context) => CreateModulePage(
                courseId: ModalRoute.of(context)!.settings.arguments as int,
              ),
        },
      ),
    );
  }
}
