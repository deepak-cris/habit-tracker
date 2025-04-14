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
import 'screens/login_screen.dart'; // Keep for potential use
import 'screens/home_screen.dart'; // Keep for potential use
import 'screens/habit_detail_screen.dart'; // Import detail screen for navigation
import 'services/notification_service.dart'; // Import NotificationService
import 'package:flutter/services.dart'; // Import for MethodChannel
import 'package:collection/collection.dart'; // Import for firstWhereOrNull
import 'screens/splash_screen.dart'; // Import SplashScreen

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
        // Need to read the provider state safely
        try {
          final habitsAsync = providerContainer!.read(habitProvider);
          habitsAsync.whenData((habits) {
            final habit = habits.firstWhereOrNull((h) => h.id == habitId);
            if (habit != null) {
              print("Navigating to detail screen for habit: ${habit.name}");
              navigatorKey.currentState?.push(
                MaterialPageRoute(
                  builder: (context) => HabitDetailScreen(habit: habit),
                ),
              );
            } else {
              print("Habit with ID $habitId not found for navigation.");
            }
          });
        } catch (e) {
          print("Error reading habitProvider in notification handler: $e");
          // Handle cases where provider might not be ready yet
        }
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
      // Use nested Consumers to watch both splash and auth states
      home: Consumer(
        builder: (context, ref, _) {
          final splashFinished = ref.watch(splashFinishedProvider);

          if (!splashFinished) {
            // If splash hasn't finished, always show SplashScreen
            return const SplashScreen();
          } else {
            // If splash IS finished, then check auth state
            return Consumer(
              builder: (context, ref, _) {
                final authState = ref.watch(authProvider);
                print("Main Auth State Listener (after splash): $authState");
                return authState.when(
                  // Show Loading indicator for initial/loading *after* splash is done
                  initial:
                      () => const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      ),
                  loading:
                      () => const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      ),
                  // Navigate to HomeScreen if authenticated
                  authenticated: (user) => const HomeScreen(),
                  // Navigate to LoginScreen if unauthenticated or error
                  unauthenticated: () => const LoginScreen(),
                  error: (message) => LoginScreen(errorMessage: message),
                );
              },
            );
          }
        },
      ),
    );
  }
}
