import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../models/habit_status.dart';
import '../auth/auth_notifier.dart';
import '../widgets/habit_card.dart';
import '../widgets/habit_graph_card.dart'; // Import the graph card
import 'add_edit_habit_screen.dart';
import 'habit_detail_screen.dart'; // Import the Calendar/Details screen
import 'habit_stats_screen.dart'; // Import the Statistics screen

// --- Habit State Management ---
final habitProvider = StateNotifierProvider<HabitNotifier, List<Habit>>(
  (ref) => HabitNotifier(),
);

class HabitNotifier extends StateNotifier<List<Habit>> {
  HabitNotifier() : super(_initialHabits) {
    // Ensure initial habits have normalized dates in maps
    _initialHabits.forEach((habit) {
      // This part is tricky as the state is final.
      // Ideally, normalization happens when adding/updating, not here.
      // For dummy data, we'll pre-normalize the keys.
    });
  }

  // Helper to normalize date keys - IMPORTANT: Use when adding/updating status/notes
  static DateTime _normalizeDate(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  // Single dummy habit with detailed info and status history
  static final List<Habit> _initialHabits = [
    () {
      final today = DateTime.now();
      final startDate = _normalizeDate(
        today.subtract(const Duration(days: 35)),
      ); // Start 5 weeks ago
      final Map<DateTime, HabitStatus> dateStatus = {};
      final Map<DateTime, String> notes = {};

      // Populate some history for the last 5 weeks
      for (int i = 0; i < 35; i++) {
        final date = _normalizeDate(today.subtract(Duration(days: i)));
        if (date.isBefore(startDate))
          continue; // Don't add status before start date

        // Example pattern: Mostly done, some skips, occasional fails
        if (date.weekday == DateTime.saturday) {
          // Skip Saturdays
          dateStatus[date] = HabitStatus.skip;
        } else if (i % 10 == 0) {
          // Fail every 10 days back
          dateStatus[date] = HabitStatus.fail;
          notes[date] = 'Felt tired today.';
        } else if (i % 5 == 0) {
          // Skip every 5 days back (unless already failed)
          if (dateStatus[date] == null) {
            dateStatus[date] = HabitStatus.skip;
          }
        } else {
          // Mark as done otherwise
          dateStatus[date] = HabitStatus.done;
          if (i == 2) notes[date] = 'Good session!';
        }
      }

      return Habit(
        id: 'dummy_exercise',
        name: 'Morning Exercise',
        description: '30 minutes of cardio or strength training.',
        reasons: ['Improve health', 'Boost energy', 'Reduce stress'],
        startDate: startDate,
        dateStatus: dateStatus, // Pre-populated status
        notes: notes, // Pre-populated notes
        scheduleType: 'Fixed',
        // Example: Weekdays only
        selectedDays: [
          false,
          true,
          true,
          true,
          true,
          true,
          false,
        ], // Su, Mo, Tu, We, Th, Fr, Sa
        targetStreak: 14, // Example target streak
      );
    }(), // Immediately invoke the function to create the habit
  ];

  // Update addHabit to accept all new fields and normalize dates
  void addHabit({
    required String name,
    String? description,
    List<String>? reasons,
    required DateTime startDate,
    String scheduleType = 'Fixed',
    required List<bool> selectedDays,
    int targetStreak = 21,
  }) {
    state = [
      ...state,
      Habit(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        description: description,
        reasons: reasons ?? [],
        dateStatus: {},
        notes: {},
        startDate: _normalizeDate(startDate), // Normalize start date
        scheduleType: scheduleType,
        selectedDays: selectedDays,
        targetStreak: targetStreak,
      ),
    ];
  }

  void deleteHabit(String habitId) {
    state = state.where((habit) => habit.id != habitId).toList();
    // TODO: Also delete from Hive persistence later
  }

  // Update status for a specific date (using helper)
  void updateStatus(String habitId, DateTime date, HabitStatus status) {
    final normalizedDate = _normalizeDate(date); // Use helper

    state =
        state.map((habit) {
          if (habit.id == habitId) {
            // Create a mutable copy of the map
            final newStatusMap = Map<DateTime, HabitStatus>.from(
              habit.dateStatus,
            );
            // Update or remove the status for the normalized date
            if (status == HabitStatus.none) {
              newStatusMap.remove(
                normalizedDate,
              ); // Remove if setting back to none
            } else {
              newStatusMap[normalizedDate] = status;
            }
            // Return a new Habit object with the updated status map and all other fields
            return Habit(
              id: habit.id,
              name: habit.name,
              description: habit.description,
              reasons: habit.reasons,
              dateStatus: newStatusMap,
              notes: habit.notes,
              startDate: habit.startDate,
              scheduleType: habit.scheduleType,
              selectedDays: habit.selectedDays,
              targetStreak: habit.targetStreak,
            );
          }
          return habit;
        }).toList();
    // TODO: Persist changes to Hive later
  }

  // Add/Update note for a specific date (using helper)
  void updateNote(String habitId, DateTime date, String note) {
    final normalizedDate = _normalizeDate(date); // Use helper

    state =
        state.map((habit) {
          if (habit.id == habitId) {
            final newNotesMap = Map<DateTime, String>.from(habit.notes);
            if (note.isEmpty) {
              newNotesMap.remove(normalizedDate); // Remove if note is empty
            } else {
              newNotesMap[normalizedDate] = note;
            }
            // Return a new Habit object with the updated notes map and all other fields
            return Habit(
              id: habit.id,
              name: habit.name,
              description: habit.description,
              reasons: habit.reasons,
              dateStatus: habit.dateStatus,
              notes: newNotesMap,
              startDate: habit.startDate,
              scheduleType: habit.scheduleType,
              selectedDays: habit.selectedDays,
              targetStreak: habit.targetStreak,
            );
          }
          return habit;
        }).toList();
    // TODO: Persist changes to Hive later
  }
}
// --- End Habit State Management ---

// Convert to ConsumerStatefulWidget to manage TabController state
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 1; // Start with HABITS tab selected

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    _tabController.addListener(() {
      // Update state when tab changes to show/hide FAB
      if (_tabController.index != _currentTabIndex) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // No longer need to watch habits here if HabitCard handles its own data/navigation
    // final habits = ref.watch(habitProvider);

    // Remove DefaultTabController, use the state's _tabController
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white), // Hamburger icon
          onPressed: () {
            // TODO: Implement drawer or menu action
          },
        ),
        title: const Text(
          'All', // Match image title
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: false, // Align title left
        actions: [
          IconButton(
            icon: const Icon(
              Icons.emoji_events_outlined,
              color: Colors.white,
            ), // Crown icon placeholder
            onPressed: () {
              // TODO: Implement rewards action
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.cloud_outlined,
              color: Colors.white,
            ), // Cloud icon placeholder
            onPressed: () {
              // TODO: Implement cloud/sync action
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.more_vert,
              color: Colors.white,
            ), // Three-dot menu
            onPressed: () {
              // TODO: Implement more options menu
            },
          ),
          // Add the original logout button for now
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => ref.read(authProvider.notifier).signOut(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController, // Assign controller
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            // Keep tabs const
            Tab(text: 'REWARDS'),
            Tab(text: 'HABITS'),
            Tab(text: 'GRAPHS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController, // Assign controller
        children: [
          const Center(child: Text('Rewards Screen (TODO)')), // REWARDS Tab

          _buildHabitsTab(), // HABITS Tab
          _buildGraphsTab(), // GRAPHS Tab
        ],
      ),
      // Conditionally display FAB based on the current tab index
      floatingActionButton:
          _currentTabIndex ==
                  1 // Show only on HABITS tab (index 1)
              ? FloatingActionButton(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
                onPressed: () {
                  // Added missing onPressed parameter
                  // Navigate to the AddEditHabitScreen
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AddEditHabitScreen(),
                    ),
                  );
                }, // Added missing closing parenthesis for onPressed
                child: const Icon(Icons.add),
              )
              : null, // Return null if not on the HABITS tab
    );
  }

  // Extracted build methods for tabs for clarity
  Widget _buildHabitsTab() {
    final habits = ref.watch(
      habitProvider,
    ); // Watch habits specifically for this tab
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: habits.length,
      itemBuilder: (context, index) {
        final habit = habits[index];
        // HabitCard handles its own tap navigation internally now
        return HabitCard(habit: habit);
      },
    );
  }

  Widget _buildGraphsTab() {
    final habits = ref.watch(
      habitProvider,
    ); // Watch habits specifically for this tab
    return ListView.builder(
      padding: const EdgeInsets.only(
        top: 8.0,
        bottom: 80.0,
      ), // Padding for FAB overlap
      itemCount: habits.length,
      itemBuilder: (context, index) {
        final habit = habits[index];
        return HabitGraphCard(
          habit: habit,
          onTap: () {
            // Navigate to stats screen on tap
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => HabitStatsScreen(habit: habit),
              ),
            );
          },
        );
      },
    );
  }
}
