import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../models/habit_status.dart';
import '../auth/auth_notifier.dart';
import '../auth/auth_state.dart'; // Import AuthState for user info
import '../widgets/habit_card.dart';
import '../widgets/habit_graph_card.dart';
import 'add_edit_habit_screen.dart';
import 'habit_detail_screen.dart';
import 'habit_stats_screen.dart';
import '../providers/points_provider.dart';
import '../providers/achievement_provider.dart';
import '../providers/reward_provider.dart';
import '../models/reward.dart';
import '../models/achievement.dart';
import '../models/claimed_reward.dart';
import 'add_edit_reward_screen.dart';
import '../providers/claimed_reward_provider.dart';
import '../utils/habit_utils.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/notification_service.dart';
import 'premium_screen.dart'; // Import PremiumScreen
import 'about_screen.dart'; // Import AboutScreen
import '../services/backup_service.dart'; // Import BackupService
import '../services/user_activity_service.dart'; // Import UserActivityService

// --- Habit State Management ---
final habitProvider =
    StateNotifierProvider<HabitNotifier, AsyncValue<List<Habit>>>((ref) {
      // Pass AuthProvider and UserActivityService to the notifier
      final authState = ref.watch(authProvider);
      final userActivityService =
          UserActivityService(); // Or provide it if needed elsewhere
      return HabitNotifier(ref, authState, userActivityService);
    });

class HabitNotifier extends StateNotifier<AsyncValue<List<Habit>>> {
  final Ref _ref;
  final AuthState _authState; // Store AuthState
  final UserActivityService _userActivityService; // Store UserActivityService
  static const String _habitBoxName = 'habits';

  HabitNotifier(this._ref, this._authState, this._userActivityService)
    : super(const AsyncValue.loading()) {
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    if (!state.isLoading) {
      state = const AsyncValue.loading();
    }
    try {
      final box = await Hive.openBox<Habit>(_habitBoxName);
      List<Habit> loadedHabits = box.values.toList();
      List<Habit> habitsToSet = [];

      if (loadedHabits.isEmpty) {
        print("No habits found in Hive. Adding default dummy habits.");
        // Assign initial orderIndex when adding defaults
        for (int i = 0; i < _initialHabits.length; i++) {
          final habitWithIndex = _initialHabits[i].copyWith(orderIndex: i);
          habitsToSet.add(habitWithIndex);
          await _persistHabit(habitWithIndex);
          NotificationService().scheduleHabitReminders(habitWithIndex);
        }
      } else {
        // Sort loaded habits by orderIndex
        loadedHabits.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
        habitsToSet = loadedHabits;
        print(
          "Loaded and sorted ${habitsToSet.length} habits from Hive by orderIndex.",
        );
        // Reschedule reminders just in case
        for (final habit in habitsToSet) {
          NotificationService().scheduleHabitReminders(habit);
        }
      }
      state = AsyncValue.data(habitsToSet);
    } catch (e, stackTrace) {
      print("Error loading habits from Hive: $e. Adding default dummy habit.");
      final fallbackHabits = _initialHabits;
      try {
        for (final habit in fallbackHabits) {
          await _persistHabit(habit);
          NotificationService().scheduleHabitReminders(habit);
        }
        state = AsyncValue.error(e, stackTrace);
      } catch (persistError) {
        print("Error persisting fallback habits: $persistError");
        state = AsyncValue.error(e, stackTrace);
      }
    }
  }

  static DateTime _normalizeDate(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  static final List<Habit> _initialHabits = [
    () {
      final today = DateTime.now();
      final startDate = _normalizeDate(
        today.subtract(const Duration(days: 35)),
      );
      final Map<DateTime, HabitStatus> dateStatus = {};
      final Map<DateTime, String> notes = {};
      for (int i = 0; i < 35; i++) {
        final date = _normalizeDate(today.subtract(Duration(days: i)));
        if (date.isBefore(startDate)) continue;
        if (date.weekday == DateTime.saturday) {
          dateStatus[date] = HabitStatus.skip;
        } else if (i % 10 == 0) {
          dateStatus[date] = HabitStatus.fail;
          notes[date] = 'Felt tired today.';
        } else if (i % 5 == 0) {
          if (dateStatus[date] == null) {
            dateStatus[date] = HabitStatus.skip;
          }
        } else {
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
        dateStatus: dateStatus,
        notes: notes,
        scheduleType: 'Fixed',
        selectedDays: [false, true, true, true, true, true, false],
        targetStreak: 14,
        isMastered: false,
      );
    }(),
  ];

  Future<bool> addHabit({
    // Correct return type to Future<bool>
    required String name,
    String? description,
    List<String>? reasons,
    required DateTime startDate,
    String scheduleType = 'Fixed',
    required List<bool> selectedDays,
    int targetStreak = 21,
    String reminderScheduleType = 'weekly',
    List<Map<String, dynamic>>? reminderTimes,
    DateTime? reminderSpecificDateTime,
  }) async {
    // Correct signature: Future<bool> methodName(...) async { ... }
    // Correct async signature returning Future<bool>
    // --- Premium Check ---
    final user = _authState.maybeWhen(
      authenticated: (u) => u,
      orElse: () => null,
    );
    if (user == null) {
      print("User not authenticated. Cannot add habit.");
      return false; // Indicate failure
    }

    final userActivity = await _userActivityService.getUserActivity(user.uid);
    final isPremium =
        userActivity?.paymentStatus !=
        'free'; // Assuming 'free' is the default non-premium status
    final currentHabits = state.asData?.value ?? [];

    if (!isPremium && currentHabits.length >= 5) {
      print("Non-premium user limit (5 habits) reached. Cannot add more.");
      // TODO: Show a message to the user in the UI layer (e.g., using a dialog or snackbar)
      // This could be done by returning a specific value, throwing an exception,
      // or managing a separate state for UI feedback.
      return false; // Indicate failure due to limit
    }
    // --- End Premium Check ---

    // Determine the next order index
    final nextOrderIndex = currentHabits.length;

    // Ensure parameters are passed correctly to the Habit constructor
    final newHabit = Habit(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name, // Use the parameter 'name'
      orderIndex: nextOrderIndex, // Assign the next index
      description: description, // Use the parameter 'description'
      reasons: reasons ?? [], // Use the parameter 'reasons'
      dateStatus: {},
      notes: {},
      startDate: _normalizeDate(startDate), // Use the parameter 'startDate'
      scheduleType: scheduleType, // Use the parameter 'scheduleType'
      selectedDays: selectedDays, // Use the parameter 'selectedDays'
      targetStreak: targetStreak, // Use the parameter 'targetStreak'
      isMastered: false,
      reminderScheduleType:
          reminderScheduleType, // Use the parameter 'reminderScheduleType'
      reminderTimes: reminderTimes, // Use the parameter 'reminderTimes'
      reminderSpecificDateTime:
          reminderSpecificDateTime, // Use the parameter 'reminderSpecificDateTime'
    );
    // Use await here since state.whenData((habits) async {
    // Use await here since state.whenData's callback is async
    // Also ensure the outer function returns Future<bool>
    await state.whenData((habits) async {
      state = AsyncValue.data([...habits, newHabit]);
      await _persistHabit(newHabit);
      NotificationService().scheduleHabitReminders(newHabit);
    });
    return true; // Indicate success
  }

  Future<void> editHabit(Habit updatedHabit) async {
    state.whenData((habits) async {
      final updatedList =
          habits
              .map((h) => h.id == updatedHabit.id ? updatedHabit : h)
              .toList();
      state = AsyncValue.data(updatedList);
      await _persistHabit(updatedHabit);
      NotificationService().scheduleHabitReminders(updatedHabit);
    });
  }

  Future<void> deleteHabit(String habitId) async {
    state.whenData((habits) async {
      await NotificationService().cancelHabitReminders(habitId);
      final updatedList = habits.where((habit) => habit.id != habitId).toList();
      state = AsyncValue.data(updatedList);
      await _deleteHabitFromPersistence(habitId);
    });
  }

  Future<void> _persistHabit(Habit habit) async {
    try {
      final box = await Hive.openBox<Habit>(_habitBoxName);
      await box.put(habit.id, habit);
      print("Persisted habit ${habit.id} to Hive.");
    } catch (e) {
      print("Error persisting habit ${habit.id} to Hive: $e");
    }
  }

  Future<void> _deleteHabitFromPersistence(String habitId) async {
    try {
      final box = await Hive.openBox<Habit>(_habitBoxName);
      await box.delete(habitId);
      print("Deleted habit $habitId from Hive.");
    } catch (e) {
      print("Error deleting habit $habitId from Hive: $e");
    }
  }

  // --- ADDED MISSING METHODS ---
  void updateStatus(String habitId, DateTime date, HabitStatus status) {
    state.whenData((habits) {
      final normalizedDate = _normalizeDate(date);
      Habit? originalHabit;
      List<Habit> newState = [];
      for (final habit in habits) {
        if (habit.id == habitId) {
          originalHabit = habit;
          final newStatusMap = Map<DateTime, HabitStatus>.from(
            habit.dateStatus,
          );
          if (status == HabitStatus.none) {
            newStatusMap.remove(normalizedDate);
          } else {
            newStatusMap[normalizedDate] = status;
          }
          newState.add(
            habit.copyWith(
              dateStatus: newStatusMap,
            ), // Use copyWith for immutability
          );
        } else {
          newState.add(habit);
        }
      }
      if (originalHabit != null) {
        final previousStatus = originalHabit.getStatusForDate(normalizedDate);
        if (status == HabitStatus.done && previousStatus != HabitStatus.done) {
          _ref.read(pointsProvider.notifier).addPoints(10);
        }
        final updatedHabitForCheck = newState.firstWhere(
          (h) => h.id == habitId,
        );
        int overallLongestStreakForCheck = _calculateOverallLongestStreak(
          updatedHabitForCheck,
        );
        _ref
            .read(unlockedAchievementsProvider.notifier)
            .checkAndUnlockAchievementsForHabit(
              updatedHabitForCheck,
              overallLongestStreakForCheck,
            );
        final updatedHabitIndex = newState.indexWhere((h) => h.id == habitId);
        if (updatedHabitIndex != -1) {
          final updatedHabit = newState[updatedHabitIndex];
          if (!updatedHabit.isMastered) {
            int overallLongestStreak = _calculateOverallLongestStreak(
              updatedHabit,
            );
            if (overallLongestStreak >= 21) {
              print("Habit ${updatedHabit.name} mastered!");
              newState[updatedHabitIndex] = updatedHabit.copyWith(
                isMastered: true,
              );
            }
          }
        }
      }
      state = AsyncValue.data(newState);
      final habitToPersist = newState.firstWhere((h) => h.id == habitId);
      _persistHabit(habitToPersist);
    });
  }

  int _calculateOverallLongestStreak(Habit habit) {
    int longestStreak = 0;
    int currentStreak = 0;
    final sortedDates = habit.dateStatus.keys.toList()..sort();
    if (sortedDates.isEmpty) return 0;
    DateTime checkDate = habit.startDate;
    DateTime lastDateToCheck = _normalizeDate(DateTime.now());
    if (sortedDates.isNotEmpty && sortedDates.last.isAfter(lastDateToCheck)) {
      lastDateToCheck = sortedDates.last;
    }
    while (!checkDate.isAfter(lastDateToCheck)) {
      final normalizedCheckDate = _normalizeDate(checkDate);
      final status = habit.dateStatus[normalizedCheckDate] ?? HabitStatus.none;
      if (status == HabitStatus.done) {
        currentStreak++;
      } else if (status == HabitStatus.skip) {
      } else {
        longestStreak =
            longestStreak > currentStreak ? longestStreak : currentStreak;
        currentStreak = 0;
      }
      checkDate = checkDate.add(const Duration(days: 1));
    }
    longestStreak =
        longestStreak > currentStreak ? longestStreak : currentStreak;
    return longestStreak;
  }

  void updateNote(String habitId, DateTime date, String note) {
    state.whenData((habits) {
      final normalizedDate = _normalizeDate(date);
      Habit? habitToPersist;
      final updatedList =
          habits.map((habit) {
            if (habit.id == habitId) {
              final newNotesMap = Map<DateTime, String>.from(habit.notes);
              if (note.isEmpty) {
                newNotesMap.remove(normalizedDate);
              } else {
                newNotesMap[normalizedDate] = note;
              }
              final updatedHabit = habit.copyWith(
                notes: newNotesMap,
              ); // Use copyWith
              habitToPersist = updatedHabit;
              return updatedHabit;
            }
            return habit;
          }).toList();
      state = AsyncValue.data(updatedList);
      if (habitToPersist != null) {
        _persistHabit(habitToPersist!);
      }
    });
  }

  void reorderHabits(int oldIndex, int newIndex) {
    state.whenData((habits) {
      // Adjust index if item is moved downwards
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final List<Habit> reorderedList = List.from(habits);
      final Habit item = reorderedList.removeAt(oldIndex);
      reorderedList.insert(newIndex, item);

      // Update orderIndex for all habits and prepare for persistence
      final List<Habit> habitsToPersist = [];
      for (int i = 0; i < reorderedList.length; i++) {
        final updatedHabit = reorderedList[i].copyWith(orderIndex: i);
        reorderedList[i] = updatedHabit; // Update list for state
        habitsToPersist.add(updatedHabit); // Add to list for saving
      }

      state = AsyncValue.data(reorderedList);

      // Persist all updated habits
      _persistReorderedHabits(habitsToPersist);
    });
  }

  // Helper function to persist the reordered list
  Future<void> _persistReorderedHabits(List<Habit> habits) async {
    try {
      final box = await Hive.openBox<Habit>(_habitBoxName);
      // Use a map for efficient batch update
      final Map<String, Habit> updates = {
        for (var habit in habits) habit.id: habit,
      };
      await box.putAll(updates);
      print("Persisted reordered habits to Hive.");
    } catch (e) {
      print("Error persisting reordered habits to Hive: $e");
    }
  }

  // --- END ADDED MISSING METHODS ---
}

// --- HomeScreen Widget ---
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 1;
  // State for FAB position using right/bottom offsets
  double _fabRightOffset = 20.0;
  double _fabBottomOffset = 20.0;
  final double _fabSize = 56.0; // Standard FAB size

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    _tabController.addListener(() {
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

  // Helper to build the FAB widget itself
  Widget _buildFab() {
    return FloatingActionButton(
      backgroundColor: Colors.pink,
      foregroundColor: Colors.white,
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const AddEditHabitScreen()),
        );
      },
      child: const Icon(Icons.add),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get current user info for the drawer
    final authState = ref.watch(authProvider);
    final user = authState.maybeWhen(
      authenticated: (user) => user,
      orElse: () => null,
    );
    final userEmail = user?.email ?? 'Not logged in';
    final userName =
        user?.displayName ??
        (user?.isAnonymous == true ? 'Anonymous User' : 'User');
    final userPhotoUrl = user?.photoURL;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor:
            Colors.white, // Ensure icons (like hamburger) are white
        // Title removed
        actions: const [
          // Removed all actions, they are now in the Drawer
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'REWARDS'),
            Tab(text: 'HABITS'),
            Tab(text: 'GRAPHS'),
          ],
        ),
      ),
      // Add the Drawer
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: Text(userName),
              accountEmail: Text(userEmail),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage:
                    userPhotoUrl != null ? NetworkImage(userPhotoUrl) : null,
                child:
                    userPhotoUrl == null
                        ? Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                          style: const TextStyle(fontSize: 40.0),
                        )
                        : null,
              ),
              decoration: const BoxDecoration(color: Colors.teal),
            ),
            ListTile(
              // Add Go Premium option
              leading: const Icon(Icons.workspace_premium_outlined),
              title: const Text('Go Premium'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PremiumScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_upload_outlined),
              title: const Text('Import Data'),
              onTap: () async {
                // Make async
                Navigator.pop(context); // Close drawer
                // Call the import function
                await ref.read(backupServiceProvider).importData(context);
                // --- Add this block to refresh UI after import ---
                if (context.mounted) {
                  ref.invalidate(habitProvider);
                  ref.invalidate(pointsProvider);
                  ref.invalidate(rewardProvider);
                  ref.invalidate(unlockedAchievementsProvider);
                  ref.invalidate(claimedRewardProvider);
                }
                // --- End of added block ---
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_download_outlined),
              title: const Text('Export Data'),
              onTap: () async {
                // Make async
                Navigator.pop(context); // Close drawer
                // Call the export function from the service
                await ref.read(backupServiceProvider).exportData(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                ref.read(authProvider.notifier).signOut();
              },
            ),
          ],
        ),
      ),
      // Use TabBarView directly as the body
      body: TabBarView(
        controller: _tabController,
        children: [_buildRewardsTab(), _buildHabitsTab(), _buildGraphsTab()],
      ),
      // Add the FAB back here using the standard property
      floatingActionButton:
          _currentTabIndex == 1
              ? _buildFab()
              : null, // Show FAB only on the Habits tab
    );
  }

  // --- Build Methods for Tabs ---

  Widget _buildRewardsTab() {
    final points = ref.watch(pointsProvider);
    final rewards = ref.watch(rewardProvider);
    final unlockedAchievementIds = ref.watch(unlockedAchievementsProvider);
    final allAchievements = ref.watch(predefinedAchievementsProvider);
    final claimedRewards = ref.watch(claimedRewardProvider);
    final habitsAsync = ref.watch(habitProvider);
    final Widget achievementListWidget = habitsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, _) => Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Error loading habits: $error"),
            ),
          ),
      data: (allHabits) {
        final List<Map<String, dynamic>> unlockedInstances = [];
        unlockedAchievementIds.forEach((achievementId, habitIdList) {
          final achievement = allAchievements.firstWhere(
            (a) => a.id == achievementId,
            orElse:
                () => const Achievement(
                  id: 'not_found',
                  name: 'Unknown',
                  description: '',
                  iconCodePoint: 0xe335,
                  criteria: {},
                ),
          );
          for (final habitId in habitIdList) {
            final habit = allHabits.firstWhere(
              (h) => h.id == habitId,
              orElse:
                  () => Habit(
                    id: habitId,
                    name: 'Deleted Habit',
                    dateStatus: {},
                    notes: {},
                    startDate: DateTime.now(),
                    selectedDays: [],
                  ),
            );
            unlockedInstances.add({
              'achievement': achievement,
              'habitName': habit.name,
            });
          }
        });
        if (unlockedInstances.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: Text(
                'Keep going to unlock achievements!',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        } else {
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: unlockedInstances.length,
            itemBuilder: (context, index) {
              final instance = unlockedInstances[index];
              final Achievement achievement = instance['achievement'];
              final String habitName = instance['habitName'];
              final String description = achievement.description.replaceAll(
                '{habitName}',
                "'$habitName'",
              );
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                elevation: 1,
                child: ListTile(
                  leading: Icon(
                    IconData(
                      achievement.iconCodePoint,
                      fontFamily: 'MaterialIcons',
                    ),
                    size: 30,
                    color: Colors.amber.shade700,
                  ),
                  title: Text(
                    achievement.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    description,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              );
            },
          );
        }
      },
    );
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, color: Colors.amber.shade700, size: 30),
                const SizedBox(width: 12),
                Text(
                  '$points Points',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Rewards', style: Theme.of(context).textTheme.titleLarge),
            IconButton(
              icon: const Icon(
                Icons.add_circle_outline,
                color: Colors.pinkAccent,
              ),
              tooltip: 'Add Custom Reward',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddEditRewardScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        const Divider(),
        if (rewards.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: Text(
                'Add some custom rewards!',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rewards.length,
            itemBuilder: (context, index) {
              final reward = rewards[index];
              final canAfford = points >= reward.pointCost;
              return ListTile(
                leading: Icon(
                  reward.iconCodePoint != null
                      ? IconData(
                        reward.iconCodePoint!,
                        fontFamily: 'MaterialIcons',
                      )
                      : Icons.card_giftcard,
                  color: Colors.teal,
                ),
                title: Text(reward.name),
                subtitle: Text(
                  '${reward.pointCost} Points ${reward.description != null ? "- ${reward.description}" : ""}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed:
                          canAfford
                              ? () {
                                _showClaimConfirmation(context, ref, reward);
                              }
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            canAfford ? Colors.amber.shade800 : Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      child: const Text('Claim'),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red.shade700,
                      ),
                      tooltip: 'Delete Reward',
                      onPressed: () {
                        _showDeleteRewardConfirmation(context, ref, reward);
                      },
                    ),
                  ],
                ),
                onLongPress: () {
                  print("Long press to edit ${reward.name} (TODO)");
                },
              );
            },
          ),
        const SizedBox(height: 24),
        Text('Achievements', style: Theme.of(context).textTheme.titleLarge),
        const Divider(),
        achievementListWidget,
        const SizedBox(height: 24),
        ExpansionTile(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Claimed Rewards',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (claimedRewards.isNotEmpty)
                IconButton(
                  icon: Icon(
                    Icons.delete_sweep_outlined,
                    color: Colors.grey.shade600,
                  ),
                  tooltip: 'Clear History',
                  onPressed: () {
                    _showClearHistoryConfirmation(context, ref);
                  },
                ),
            ],
          ),
          initiallyExpanded: false,
          children: <Widget>[
            if (claimedRewards.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Text(
                    'No rewards claimed yet.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: claimedRewards.length,
                itemBuilder: (context, index) {
                  final claim = claimedRewards[index];
                  final formattedDate = DateFormat.yMMMd().add_jm().format(
                    claim.claimTimestamp,
                  );
                  String subtitleText =
                      '$formattedDate - ${claim.pointCost} Points';
                  if (claim.claimReason != null &&
                      claim.claimReason!.isNotEmpty) {
                    subtitleText += '\nReason: ${claim.claimReason}';
                  }
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    elevation: 1,
                    child: ListTile(
                      leading: const Icon(
                        Icons.history,
                        color: Colors.blueGrey,
                      ),
                      title: Text(claim.rewardName),
                      subtitle: Text(subtitleText),
                      isThreeLine:
                          claim.claimReason != null &&
                          claim.claimReason!.isNotEmpty,
                    ),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _showClaimConfirmation(
    BuildContext context,
    WidgetRef ref,
    Reward reward,
  ) async {
    // Placeholder for claim confirmation logic
    print("Claiming reward ${reward.name}");
  }

  Future<void> _showDeleteRewardConfirmation(
    BuildContext context,
    WidgetRef ref,
    Reward reward,
  ) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Reward?'),
          content: Text(
            'Are you sure you want to delete the reward "${reward.name}"? This cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () {
                ref.read(rewardProvider.notifier).deleteReward(reward.id);
                Navigator.of(dialogContext).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Reward "${reward.name}" deleted.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showClearHistoryConfirmation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Clear History?'),
          content: const Text(
            'Are you sure you want to clear all claimed reward history? This cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Clear All'),
              onPressed: () async {
                await ref.read(claimedRewardProvider.notifier).clearHistory();
                Navigator.of(dialogContext).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Claimed reward history cleared.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildHabitsTab() {
    final habitsAsync = ref.watch(habitProvider);
    return habitsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, stackTrace) => Center(
            child: Text(
              'Error loading habits: $error\n$stackTrace',
              textAlign: TextAlign.center,
            ),
          ),
      data: (habits) {
        if (habits.isEmpty) {
          return const Center(
            child: Text(
              'No habits yet. Add one!',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }
        // Use ReorderableListView.builder for drag-and-drop
        return ReorderableListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: habits.length,
          itemBuilder: (context, index) {
            final habit = habits[index];
            // IMPORTANT: Each item needs a unique Key for ReorderableListView
            return HabitCard(key: ValueKey(habit.id), habit: habit);
          },
          onReorder: (int oldIndex, int newIndex) {
            // This callback handles the reordering logic
            ref
                .read<HabitNotifier>(habitProvider.notifier)
                .reorderHabits(oldIndex, newIndex);
          },
        );
      },
    );
  }

  Widget _buildGraphsTab() {
    final habitsAsync = ref.watch(habitProvider);
    return habitsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, stackTrace) => Center(
            child: Text(
              'Error loading habits: $error',
              textAlign: TextAlign.center,
            ),
          ),
      data: (habits) {
        if (habits.isEmpty) {
          return const Center(
            child: Text(
              'No habits to graph yet.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8.0, bottom: 80.0),
          itemCount: habits.length,
          itemBuilder: (context, index) {
            final habit = habits[index];
            return HabitGraphCard(
              habit: habit,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => HabitStatsScreen(habit: habit),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
