import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_application_1/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/investor_page.dart';
import 'package:flutter_application_1/login_page.dart';
import 'package:flutter_application_1/owner_home_page.dart';
import 'package:flutter_application_1/project_details_page.dart';
import 'package:flutter_application_1/offers_page.dart';
import 'package:flutter_application_1/edit_project_page.dart';
import 'package:flutter_application_1/sign_up_page.dart';
import 'package:flutter_application_1/splash_screen.dart';
import 'package:flutter_application_1/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Supabase.initialize(
    url: "https://fihsvbtijfheyiwjuduf.supabase.co",
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZpaHN2YnRpamZoZXlpd2p1ZHVmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU1NjkxNzAsImV4cCI6MjA4MTE0NTE3MH0.5wySGzZ7BE0GFOby47biho_uzvCEeFdwTTwnSL7yY9U",
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Investor Owner App',
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashPage(),
            '/login': (context) => const LoginPage(),
            '/signup': (context) => const SignUpPage(),
            '/investor': (context) => const InvestorHomePage(),
            '/owner': (context) => const OwnerHomePage(),
            '/project_details': (context) => ProjectDetailsPage(),
            '/offers': (context) => const OffersPage(),
            '/edit_project': (context) {
              final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
              final projectId = args?['projectId'] as String? ?? '';
              return EditProjectPage(projectId: projectId);
            },
          },
        );
      },
    );
  }
}
