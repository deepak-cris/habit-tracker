import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../models/habit_status.dart';
import '../auth/auth_notifier.dart';
import '../widgets/habit_card.dart';
import '../widgets/habit_graph_card.dart'; // Import the graph card
import 'add_edit_habit_screen.dart';
import 'habit_detail_screen.dart'; // Import the detail screen

// --- Habit State Management ---
final habitProvider = StateNotifierProvider<HabitNotifier, List<Habit>>(
  (ref) => HabitNotifier(),
);

class HabitNotifier extends StateNotifier<List<Habit>> {
  HabitNotifier() : super(_initialHabits);

  // Updated dummy data with all fields
  static final _initialHabits = [
    Habit(
      id: '1',
      name: 'Wake Up and Sleep',
      dateStatus: {},
      notes: {},
      startDate: DateTime.now(),
      selectedDays: List.filled(7, true),
    ),
    Habit(
      id: '2',
      name: 'No Smoking',
      dateStatus: {},
      notes: {},
      startDate: DateTime.now(),
      selectedDays: List.filled(7, true),
    ),
    Habit(
      id: '3',
      name: 'Exercise',
      dateStatus: {},
      notes: {},
      startDate: DateTime.now(),
      selectedDays: List.filled(7, true),
    ),
    Habit(
      id: '4',
      name: 'Meditation',
      dateStatus: {},
      notes: {},
      startDate: DateTime.now(),
      selectedDays: List.filled(7, true),
    ),
    Habit(
      id: '5',
      name: 'No Film',
      dateStatus: {},
      notes: {},
      targetStreak: 7,
      startDate: DateTime.now(),
      selectedDays: List.filled(7, true),
    ),
  ];

  // Update addHabit to accept all new fields
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
        startDate: startDate,
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

  // Update status for a specific date
  void updateStatus(String habitId, DateTime date, HabitStatus status) {
    final normalizedDate = DateTime.utc(date.year, date.month, date.day);

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

  // Add/Update note for a specific date
  void updateNote(String habitId, DateTime date, String note) {
    final normalizedDate = DateTime.utc(date.year, date.month, date.day);

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

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitProvider);
    // DateTime selectedDay = DateTime.now(); // No longer needed at this level

    // Use DefaultTabController for the TabBar
    return DefaultTabController(
      length: 3, // Number of tabs: REWARDS, HABITS, GRAPHS
      initialIndex: 1, // Start with the HABITS tab selected
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.teal, // Match image color
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
          bottom: const TabBar(
            labelColor: Colors.white, // Selected tab text color
            unselectedLabelColor: Colors.white70, // Unselected tab text color
            indicatorColor: Colors.white, // Underline color for selected tab
            tabs: [
              Tab(text: 'REWARDS'),
              Tab(text: 'HABITS'),
              Tab(text: 'GRAPHS'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // --- REWARDS Tab ---
            const Center(child: Text('Rewards Screen (TODO)')),

            // --- HABITS Tab ---
            ListView.builder(
              padding: const EdgeInsets.all(8.0), // Add some padding
              itemCount: habits.length,
              itemBuilder: (context, index) {
                final habit = habits[index];
                // Use the new HabitCard widget
                return HabitCard(habit: habit);
              },
            ),

            // --- GRAPHS Tab ---
            ListView.builder(
              padding: const EdgeInsets.only(
                top: 8.0,
                bottom: 80.0,
              ), // Add padding, especially bottom for FAB
              itemCount: habits.length,
              itemBuilder: (context, index) {
                final habit = habits[index];
                return HabitGraphCard(
                  habit: habit,
                  onTap: () {
                    // Navigate to detail screen on tap
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => HabitDetailScreen(habit: habit),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.pink,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
          onPressed: () {
            // Navigate to the new screen instead of showing dialog
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AddEditHabitScreen(),
              ),
            );
          },
        ),
      ),
    );
  }

  // Removed _showAddHabitDialog method
}
