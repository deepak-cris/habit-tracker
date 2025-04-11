import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/habit.dart';
import 'models/habit_status.dart'; // Import HabitStatus
import 'auth/auth_notifier.dart'; // Corrected import path
import 'screens/login_screen.dart'; // Corrected import path
import 'screens/home_screen.dart'; // Corrected import path

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Hive.initFlutter();

  // Register both adapters
  Hive.registerAdapter(HabitAdapter());
  Hive.registerAdapter(HabitStatusAdapter()); // Register the new adapter

  await Hive.openBox(
    'habits',
  ); // Consider opening separate boxes if needed later
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: Consumer(
        builder: (context, ref, _) {
          final authState = ref.watch(authProvider);
          return authState.when(
            initial:
                () => const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
            authenticated: (user) => const HomeScreen(),
            unauthenticated: () => const LoginScreen(),
            loading:
                () => const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
            error: (message) => LoginScreen(errorMessage: message),
          );
        },
      ),
    );
  }
}
