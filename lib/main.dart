import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for SystemUiOverlayStyle
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/habit.dart';
import 'models/habit_status.dart';
import 'models/reward.dart'; // Import Reward model
import 'models/claimed_reward.dart'; // Import ClaimedReward model
import 'auth/auth_notifier.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/habit_detail_screen.dart'; // Import detail screen for navigation
import 'services/notification_service.dart'; // Import NotificationService
import 'package:flutter/services.dart'; // Import for MethodChannel
import 'package:collection/collection.dart'; // Import for firstWhereOrNull

// Add GlobalKey for Navigator
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
// Keep a reference to the ProviderContainer
ProviderContainer? providerContainer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure bindings are initialized
  await Firebase.initializeApp();
  await Hive.initFlutter();

  // Initialize Notification Service
  await NotificationService().init();

  // Register adapters
  Hive.registerAdapter(HabitAdapter());
  Hive.registerAdapter(HabitStatusAdapter());
  Hive.registerAdapter(RewardAdapter()); // Register Reward adapter
  Hive.registerAdapter(
    ClaimedRewardAdapter(),
  ); // Register ClaimedReward adapter

  // Open required boxes with correct types
  await Hive.openBox<Habit>('habits'); // Specify Habit type
  await Hive.openBox(
    'userProfile',
  ); // For points and achievements (assuming dynamic or simple types)
  await Hive.openBox<Reward>('rewards'); // Box for custom rewards
  await Hive.openBox<ClaimedReward>(
    'claimedRewards',
  ); // Box for claimed rewards

  // Create the ProviderContainer and store it
  providerContainer = ProviderContainer();
  // Setup channel handler *after* container is created
  _setupPlatformChannelHandler();

  runApp(
    ProviderScope(
      parent: providerContainer, // Use the created container
      child: const MyApp(),
    ),
  );
}

// --- Platform Channel Handler ---
void _setupPlatformChannelHandler() {
  // Use the same channel name as defined in MainActivity
  const platform = MethodChannel('com.habit_tracker.app/notifications');
  platform.setMethodCallHandler(_handlePlatformChannelCall);
}

Future<void> _handlePlatformChannelCall(MethodCall call) async {
  switch (call.method) {
    case 'handleNotificationTap':
      final String? habitId = call.arguments['habitId'];
      print("Dart received handleNotificationTap for habitId: $habitId");
      if (habitId != null && providerContainer != null) {
        // Use the stored container to read the provider
        final habitsAsync = providerContainer!.read(habitProvider);
        habitsAsync.whenData((habits) {
          // Use firstWhereOrNull from collection package
          final habit = habits.firstWhereOrNull((h) => h.id == habitId);
          if (habit != null) {
            print("Navigating to detail screen for habit: ${habit.name}");
            // Use navigatorKey to navigate
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => HabitDetailScreen(habit: habit),
              ),
            );
          } else {
            print("Habit with ID $habitId not found for navigation.");
          }
        });
      }
      break;
    default:
      print('Unrecognized platform method call: ${call.method}');
  }
}
// --- End Platform Channel Handler ---

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // Assign the global key
      title: 'Habit Tracker', // Changed title
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
        ), // Use teal as seed
        useMaterial3: true, // Enable Material 3
        appBarTheme: const AppBarTheme(
          // Consistent AppBar style
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          elevation: 2,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.pinkAccent, // Consistent FAB color
          foregroundColor: Colors.white,
        ),
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
