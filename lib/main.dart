import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intern_management_system/widgets/custom_loader.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/constants/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/intern_provider.dart';
import 'views/auth/login_screen.dart';
import 'views/auth/verify_email_screen.dart';
import 'views/auth/complete_profile_screen.dart';
import 'views/intern/intern_dashboard.dart';
import 'views/admin/admin_dashboard.dart';
import 'firebase_options.dart';

// Entry point of the app.
// Initializes Provider and applies light, dark and system theme support.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => themeProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => InternProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: "Intern Management System",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const AuthWrapper(),
      routes: {
        '/complete-profile': (_) => const CompleteProfileScreen(),
        '/intern-dashboard': (_) => const InternDashboard(),
        '/admin-dashboard': (_) => const AdminDashboard(),
      },
    );
  }
}

// Decides which screen to show based on auth state.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    // not logged in
    if (user == null) return const LoginScreen();

    // Logged in but email not verified
    if (!user.emailVerified) return const VerifyEmailScreen();

    // Verified - check role & profile status
    return FutureBuilder<String>(
      future: authProvider.getUserRole(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CustomLoader()));
        }
        if (snapshot.data == 'admin') return const AdminDashboard();

        // Check if intern profile is complete
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(authProvider.user!.uid)
              .get(),
          builder: (context, profileSnapshot) {
            if (!profileSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final data = profileSnapshot.data!.data() as Map<String, dynamic>;
            final phone = data["phone"] ?? "";
            if (phone.isEmpty) return const CompleteProfileScreen();
            return const InternDashboard();
          },
        );
      },
    );
  }
}
