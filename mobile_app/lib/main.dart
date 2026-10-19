import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'providers/admin_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with the existing project configuration
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDrhyNCKO5tzF-tiRQevk12kLM8hAkkr0w",
      appId: "1:197134642642:web:a112f2cbf9dc64d0096c0b",
      messagingSenderId: "197134642642",
      projectId: "reservations-e411a",
      storageBucket: "reservations-e411a.firebasestorage.app",
    ),
  );

  runApp(const AbuZahraApp());
}

class AbuZahraApp extends StatelessWidget {
  const AbuZahraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme(),
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: StreamBuilder<User?>(
        stream: AuthService().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: AppConstants.darkBg,
              body: Center(
                child: CircularProgressIndicator(color: AppConstants.primary),
              ),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            return ChangeNotifierProvider(
              create: (_) => AdminProvider(),
              child: const MainShell(),
            );
          }

          return const LoginScreen();
        },
      ),
    );
  }
}
