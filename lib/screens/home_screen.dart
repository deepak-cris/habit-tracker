import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../models/habit_status.dart';
import '../auth/auth_notifier.dart'; // Ensure this import is present
import '../widgets/habit_card.dart';
import '../widgets/habit_graph_card.dart';
import 'add_edit_habit_screen.dart';
import 'habit_detail_screen.dart'; // Import the Calendar/Details screen
import 'habit_stats_screen.dart';
import '../providers/points_provider.dart';
import '../providers/achievement_provider.dart';
import '../providers/reward_provider.dart';
import '../models/reward.dart';
import '../models/achievement.dart';
import '../models/claimed_reward.dart'; // Import ClaimedReward model
import 'add_edit_reward_screen.dart'; // Import the Add/Edit Reward screen
import '../providers/claimed_reward_provider.dart'; // Import provider
import '../utils/habit_utils.dart'; // Import habit utils for streak calculation
import 'package:intl/intl.dart'; // Import intl for date formatting

// --- Habit State Management ---
final habitProvider = StateNotifierProvider<HabitNotifier, List<Habit>>((ref) {
  // Pass ref to notifier so it can read other providers
  return HabitNotifier(ref);
});

class HabitNotifier extends StateNotifier<List<Habit>> {
  final Ref _ref; // Keep ref to read other providers

  HabitNotifier(this._ref) : super(_initialHabits) {
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
        isMastered: false, // Default to false
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
        isMastered: false, // Ensure new habits start as not mastered
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
    Habit? originalHabit; // Store original habit to check status change
    List<Habit> newState = []; // Build the new state list

    // First pass: Update the status and store the original habit
    for (final habit in state) {
      if (habit.id == habitId) {
        originalHabit = habit; // Store the original state before modification
        // Create a mutable copy of the map
        final newStatusMap = Map<DateTime, HabitStatus>.from(habit.dateStatus);
        // Update or remove the status for the normalized date
        if (status == HabitStatus.none) {
          newStatusMap.remove(normalizedDate); // Remove if setting back to none
        } else {
          newStatusMap[normalizedDate] = status;
        }
        // Add the updated habit (without isMastered change yet)
        newState.add(
          Habit(
            id: habit.id,
            name: habit.name,
            description: habit.description,
            reasons: habit.reasons,
            dateStatus: newStatusMap, // Use updated status map
            notes: habit.notes,
            startDate: habit.startDate,
            scheduleType: habit.scheduleType,
            selectedDays: habit.selectedDays,
            targetStreak: habit.targetStreak,
            isMastered:
                habit.isMastered, // Keep original mastered status for now
          ),
        );
      } else {
        newState.add(habit); // Add unchanged habits
      }
    }

    // --- Award Points & Check Achievements ---
    if (originalHabit != null) {
      final previousStatus = originalHabit!.getStatusForDate(normalizedDate);
      // Award points only when changing *to* Done from something else
      if (status == HabitStatus.done && previousStatus != HabitStatus.done) {
        _ref.read(pointsProvider.notifier).addPoints(10); // Award 10 points
      }
      // TODO: Consider if points should be deducted on changing *from* Done?

      // Check achievements after any status update
      // Calculate overall streak for the *updated* habit first
      final updatedHabitForCheck = newState.firstWhere((h) => h.id == habitId);
      int overallLongestStreakForCheck = _calculateOverallLongestStreak(
        updatedHabitForCheck,
      );
      // Call the per-habit check method in AchievementNotifier
      _ref
          .read(unlockedAchievementsProvider.notifier)
          .checkAndUnlockAchievementsForHabit(
            updatedHabitForCheck,
            overallLongestStreakForCheck,
          );

      // --- Check for Habit Mastered ---
      // Find the updated habit in the new state list
      final updatedHabitIndex = newState.indexWhere((h) => h.id == habitId);
      if (updatedHabitIndex != -1) {
        final updatedHabit = newState[updatedHabitIndex];
        if (!updatedHabit.isMastered) {
          // Only check if not already mastered
          // Calculate overall longest streak for *this* habit
          int overallLongestStreak = _calculateOverallLongestStreak(
            updatedHabit,
          );
          if (overallLongestStreak >= 21) {
            print("Habit ${updatedHabit.name} mastered!");
            // Mark as mastered - create a new instance and replace in the list
            newState[updatedHabitIndex] = Habit(
              id: updatedHabit.id,
              name: updatedHabit.name,
              description: updatedHabit.description,
              reasons: updatedHabit.reasons,
              dateStatus: updatedHabit.dateStatus,
              notes: updatedHabit.notes,
              startDate: updatedHabit.startDate,
              scheduleType: updatedHabit.scheduleType,
              selectedDays: updatedHabit.selectedDays,
              targetStreak: updatedHabit.targetStreak,
              isMastered: true, // Set the flag
            );
            // TODO: Persist this change too
          }
        }
      }
    }

    state = newState; // Assign the final updated list to the state
    // TODO: Persist changes to Hive later (consider saving points/achievements too)
  }

  // Helper function to calculate the overall longest streak for a single habit
  int _calculateOverallLongestStreak(Habit habit) {
    int longestStreak = 0;
    int currentStreak = 0;
    // Get all status dates and sort them
    final sortedDates = habit.dateStatus.keys.toList()..sort();

    if (sortedDates.isEmpty) return 0;

    // Iterate from start date up to the last recorded date or today, whichever is later
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
        // Skips don't break the streak, but don't increment it either
      } else {
        // Fail or None breaks the streak
        longestStreak =
            longestStreak > currentStreak ? longestStreak : currentStreak;
        currentStreak = 0;
      }
      checkDate = checkDate.add(const Duration(days: 1));
    }
    // Final check in case the streak ended on the last day checked
    longestStreak =
        longestStreak > currentStreak ? longestStreak : currentStreak;
    return longestStreak;
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
              isMastered: habit.isMastered, // Include isMastered
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
          _buildRewardsTab(), // REWARDS Tab (New build method)
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

  // --- Build Method for REWARDS Tab ---
  Widget _buildRewardsTab() {
    final points = ref.watch(pointsProvider);
    final rewards = ref.watch(rewardProvider);
    final unlockedAchievementIds = ref.watch(unlockedAchievementsProvider);
    final allAchievements = ref.watch(predefinedAchievementsProvider);
    final claimedRewards = ref.watch(
      claimedRewardProvider,
    ); // Watch claimed rewards

    // --- Prepare Data for Achievement List ---
    final allHabits = ref.watch(habitProvider); // Need habits to get names
    final List<Map<String, dynamic>> unlockedInstances = [];

    unlockedAchievementIds.forEach((achievementId, habitIdList) {
      // Find the achievement definition
      final achievement = allAchievements.firstWhere(
        (a) => a.id == achievementId,
        orElse:
            () => const Achievement(
              id: 'not_found',
              name: 'Unknown',
              description: '',
              iconCodePoint: 0xe335,
              criteria: {},
            ), // Placeholder if not found
      );

      for (final habitId in habitIdList) {
        // Find the habit name
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
              ), // Placeholder if habit deleted
        );
        unlockedInstances.add({
          'achievement': achievement,
          'habitName': habit.name,
        });
      }
    });
    // Optional: Sort the instances, e.g., by achievement name then habit name
    // unlockedInstances.sort((a, b) => ...);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // --- Points Display ---
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

        // --- Custom Rewards Section ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Rewards',
              style: Theme.of(context).textTheme.titleLarge,
            ), // Renamed title
            IconButton(
              icon: const Icon(
                Icons.add_circle_outline,
                color: Colors.pinkAccent,
              ),
              tooltip: 'Add Custom Reward',
              onPressed: () {
                // Navigate to AddEditRewardScreen
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            const AddEditRewardScreen(), // Navigate to add/edit screen
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
                  // Use Row for multiple trailing widgets
                  mainAxisSize:
                      MainAxisSize.min, // Prevent Row from taking full width
                  children: [
                    ElevatedButton(
                      onPressed:
                          canAfford
                              ? () {
                                // Show confirmation dialog before claiming
                                _showClaimConfirmation(context, ref, reward);
                              }
                              : null, // Disable if cannot afford
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
                    const SizedBox(width: 4), // Add spacing
                    IconButton(
                      // Add delete button
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red.shade700,
                      ),
                      tooltip: 'Delete Reward',
                      onPressed: () {
                        // Show delete confirmation
                        _showDeleteRewardConfirmation(context, ref, reward);
                      },
                    ),
                  ],
                ),
                onLongPress: () {
                  // Keep long press for potential future edit action
                  // TODO: Show edit options
                  print("Long press to edit ${reward.name} (TODO)");
                },
              );
            },
          ),
        const SizedBox(height: 24),

        // --- Achievements Section ---
        Text('Achievements', style: Theme.of(context).textTheme.titleLarge),
        const Divider(),
        if (unlockedInstances.isEmpty) // Use the correct variable name here
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: Text(
                'Keep going to unlock achievements!',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          // Build ListView from the flattened list of unlocked instances
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount:
                unlockedInstances.length, // Use the correct variable name here
            itemBuilder: (context, index) {
              final instance =
                  unlockedInstances[index]; // Use the correct variable name here
              final Achievement achievement = instance['achievement'];
              final String habitName = instance['habitName'];

              // Replace placeholder in description
              final String description = achievement.description.replaceAll(
                '{habitName}',
                "'$habitName'",
              );

              return Card(
                // Wrap ListTile in a Card for similar look
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
                  // isThreeLine: true, // Allow more space if descriptions are long
                ),
              );
            },
          ),
        const SizedBox(height: 24), // Add spacing before claimed rewards
        // --- Claimed Rewards History Section ---
        ExpansionTile(
          title: Row(
            // Use Row for title and clear button
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Claimed Rewards',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (claimedRewards
                  .isNotEmpty) // Show button only if list is not empty
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
          initiallyExpanded: false, // Start collapsed
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
                physics:
                    const NeverScrollableScrollPhysics(), // Prevent nested scrolling issues
                itemCount: claimedRewards.length,
                itemBuilder: (context, index) {
                  final claim = claimedRewards[index];
                  final formattedDate = DateFormat.yMMMd().add_jm().format(
                    claim.claimTimestamp,
                  ); // Example format
                  String subtitleText =
                      '$formattedDate - ${claim.pointCost} Points';
                  if (claim.claimReason != null &&
                      claim.claimReason!.isNotEmpty) {
                    subtitleText += '\nReason: ${claim.claimReason}';
                  }

                  return Card(
                    // Wrap ListTile in a Card
                    margin: const EdgeInsets.symmetric(
                      vertical: 4.0,
                    ), // Add margin like achievements
                    elevation: 1, // Add elevation like achievements
                    child: ListTile(
                      leading: const Icon(
                        Icons.history,
                        color: Colors.blueGrey,
                      ),
                      title: Text(claim.rewardName),
                      subtitle: Text(subtitleText),
                      isThreeLine:
                          claim.claimReason != null &&
                          claim
                              .claimReason!
                              .isNotEmpty, // Adjust layout for reason
                      // trailing: Text('${claim.pointCost} Pts', style: TextStyle(fontWeight: FontWeight.bold)), // Optional trailing points
                    ),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }

  // --- Confirmation Dialog for Claiming Reward ---
  Future<void> _showClaimConfirmation(
    BuildContext context,
    WidgetRef ref,
    Reward reward,
  ) async {
    final reasonController =
        TextEditingController(); // Controller for the reason
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Claim Reward?'),
          content: SingleChildScrollView(
            // Wrap in case of small screens
            child: ListBody(
              children: <Widget>[
                Text('Claim "${reward.name}" for ${reward.pointCost} points?'),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    hintText: 'Reason for claiming (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Claim'),
              onPressed: () {
                bool claimed = ref
                    .read(rewardProvider.notifier)
                    .claimReward(
                      reward.id,
                      reasonController.text.trim(),
                    ); // Pass reason
                Navigator.of(dialogContext).pop(); // Close dialog first
                if (!claimed && mounted) {
                  // Check if widget is still mounted
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Not enough points!'),
                      backgroundColor: Colors.redAccent,
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

  // --- Confirmation Dialog for Deleting Reward ---
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
                Navigator.of(dialogContext).pop(); // Close dialog
                // Show feedback (optional but good UX)
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Reward "${reward.name}" deleted.'),
                      backgroundColor: Colors.green, // Use a success color
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

  // --- Confirmation Dialog for Clearing History ---
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
                // Make async for the provider call
                await ref.read(claimedRewardProvider.notifier).clearHistory();
                Navigator.of(dialogContext).pop(); // Close dialog
                // Show feedback (optional but good UX)
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Claimed reward history cleared.'),
                      backgroundColor: Colors.green, // Use a success color
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
}
