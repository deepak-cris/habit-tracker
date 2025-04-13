import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/habit.dart';
import '../screens/home_screen.dart'; // For habitProvider

class HabitRemindersScreen extends ConsumerStatefulWidget {
  final Habit habit;

  const HabitRemindersScreen({super.key, required this.habit});

  @override
  ConsumerState<HabitRemindersScreen> createState() =>
      _HabitRemindersScreenState();
}

class _HabitRemindersScreenState extends ConsumerState<HabitRemindersScreen> {
  // State variables moved from AddEditHabitScreen
  late String _reminderScheduleType;
  late DateTime? _reminderSpecificDateTime;
  late List<Map<String, dynamic>> _reminderTimes;
  late List<bool> _selectedDays; // Needed for weekly schedule UI

  // Helper for day names
  final List<String> _dayNames = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

  @override
  void initState() {
    super.initState();
    // Initialize state from the passed habit
    _reminderScheduleType = widget.habit.reminderScheduleType;
    _reminderSpecificDateTime = widget.habit.reminderSpecificDateTime;
    _reminderTimes = List<Map<String, dynamic>>.from(
      widget.habit.reminderTimes?.map((e) => Map<String, dynamic>.from(e)) ??
          [],
    );
    // Initialize selectedDays based on habit, default if needed for weekly view consistency
    _selectedDays =
        widget.habit.selectedDays.length == 7
            ? List.from(widget.habit.selectedDays)
            : List.filled(7, false); // Default if habit data is inconsistent
  }

  // --- Save Logic ---
  void _saveReminders() {
    // Prepare reminder data based on current state
    List<Map<String, dynamic>>? finalReminderTimes;
    DateTime? finalSpecificDateTime;

    switch (_reminderScheduleType) {
      case 'daily':
      case 'weekly':
        finalReminderTimes = List<Map<String, dynamic>>.from(_reminderTimes);
        break;
      case 'specific_date':
        finalSpecificDateTime = _reminderSpecificDateTime;
        break;
      case 'none':
      default:
        // Clear reminder data
        finalReminderTimes = null;
        finalSpecificDateTime = null;
        break;
    }

    // Create updated habit object with only reminder fields changed
    final updatedHabit = Habit(
      // Copy all non-reminder fields from original habit
      id: widget.habit.id,
      name: widget.habit.name,
      description: widget.habit.description,
      reasons: widget.habit.reasons,
      startDate: widget.habit.startDate,
      scheduleType: widget.habit.scheduleType,
      selectedDays:
          widget.habit.selectedDays, // Keep original habit schedule days
      targetStreak: widget.habit.targetStreak,
      dateStatus: widget.habit.dateStatus,
      notes: widget.habit.notes,
      isMastered: widget.habit.isMastered,
      // Apply updated reminder fields
      reminderScheduleType: _reminderScheduleType,
      reminderTimes: finalReminderTimes,
      reminderSpecificDateTime: finalSpecificDateTime,
    );

    ref.read(habitProvider.notifier).editHabit(updatedHabit);

    // Show confirmation and pop
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reminders for "${updatedHabit.name}" updated.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  // --- Reminder Time Picker Logic (Copied from AddEditHabitScreen) ---
  Future<void> _selectReminderTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final String? note = await _showAddReminderNoteDialog(context);
      final newReminder = {
        'hour': picked.hour,
        'minute': picked.minute,
        'note': note,
      };
      bool exists = _reminderTimes.any(
        (t) =>
            t['hour'] == newReminder['hour'] &&
            t['minute'] == newReminder['minute'] &&
            t['note'] == newReminder['note'],
      );

      if (!exists) {
        setState(() {
          _reminderTimes.add(newReminder);
          _reminderTimes.sort((a, b) {
            final timeA = TimeOfDay(
              hour: a['hour'] as int,
              minute: a['minute'] as int,
            );
            final timeB = TimeOfDay(
              hour: b['hour'] as int,
              minute: b['minute'] as int,
            );
            final now = DateTime.now();
            final dtA = DateTime(
              now.year,
              now.month,
              now.day,
              timeA.hour,
              timeA.minute,
            );
            final dtB = DateTime(
              now.year,
              now.month,
              now.day,
              timeB.hour,
              timeB.minute,
            );
            return dtA.compareTo(dtB);
          });
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reminder time added.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This reminder time and note already exists.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  Future<String?> _showAddReminderNoteDialog(BuildContext context) async {
    final noteController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Reminder Note (Optional)'),
          content: TextField(
            controller: noteController,
            decoration: const InputDecoration(hintText: 'Enter note...'),
            autofocus: true,
            maxLines: null,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final note = noteController.text.trim();
                Navigator.pop(context, note.isNotEmpty ? note : null);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _removeReminderTime(int index) {
    setState(() {
      _reminderTimes.removeAt(index);
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reminder time removed.'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // --- Specific Date/Time Picker Logic (Copied from AddEditHabitScreen) ---
  Future<void> _selectSpecificDateTime(BuildContext context) async {
    final DateTime initialDate = _reminderSpecificDateTime ?? DateTime.now();
    final TimeOfDay initialTime =
        _reminderSpecificDateTime != null
            ? TimeOfDay.fromDateTime(_reminderSpecificDateTime!)
            : TimeOfDay.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate == null) return;

    if (!context.mounted) return;
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (pickedTime == null) return;

    setState(() {
      _reminderSpecificDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Specific reminder date/time set.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Text(
          'Reminders: ${widget.habit.name}',
          style: const TextStyle(color: Colors.white),
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: _saveReminders, // Use the new save method
            child: const Text(
              'SAVE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _buildRemindersTabContent(), // Use the reminder tab builder method
    );
  }

  // --- Build Method for Reminders Tab Content (Copied and adapted from AddEditHabitScreen) ---
  Widget _buildRemindersTabContent() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(
          'Reminder Schedule',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        _buildSectionContainer(
          child: DropdownButtonFormField<String>(
            value: _reminderScheduleType,
            items: const [
              DropdownMenuItem(value: 'none', child: Text('None')),
              DropdownMenuItem(value: 'daily', child: Text('Daily')),
              DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
              DropdownMenuItem(
                value: 'specific_date',
                child: Text('Specific Date'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _reminderScheduleType = value;
                  if (value != 'specific_date')
                    _reminderSpecificDateTime = null;
                });
              }
            },
            decoration: const InputDecoration(
              labelText: 'Schedule Type',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_reminderScheduleType != 'none') ...[
          if (_reminderScheduleType == 'daily' ||
              _reminderScheduleType == 'weekly') ...[
            Text(
              'Reminder Times',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (_reminderTimes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Text(
                    'No reminder times set.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _reminderTimes.length,
                itemBuilder: (context, index) {
                  final timeMap = _reminderTimes[index];
                  final time = TimeOfDay(
                    hour: timeMap['hour'] as int,
                    minute: timeMap['minute'] as int,
                  );
                  final formattedTime = time.format(context);
                  final note = timeMap['note'] as String?;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ListTile(
                      leading: const Icon(Icons.alarm, color: Colors.teal),
                      title: Text(formattedTime),
                      subtitle:
                          note != null && note.isNotEmpty ? Text(note) : null,
                      isThreeLine: note != null && note.isNotEmpty,
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        tooltip: 'Remove Reminder Time',
                        onPressed: () => _removeReminderTime(index),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_alarm),
                label: const Text('Add Reminder Time'),
                onPressed: () => _selectReminderTime(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_reminderScheduleType == 'weekly') ...[
            Text(
              'Reminder Days',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildSectionContainer(child: _buildDaySelector()),
            const SizedBox(height: 16),
          ],
          if (_reminderScheduleType == 'specific_date') ...[
            _buildSectionContainer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _reminderSpecificDateTime == null
                        ? 'Select Date & Time'
                        : DateFormat(
                          'yyyy-MM-dd HH:mm',
                        ).format(_reminderSpecificDateTime!),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton(
                    onPressed: () => _selectSpecificDateTime(context),
                    child: Text(
                      _reminderSpecificDateTime == null ? 'SELECT' : 'CHANGE',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ],
    );
  }

  // --- Helper Widgets (Copied from AddEditHabitScreen) ---
  Widget _buildSectionContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildDaySelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: List.generate(7, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: ChoiceChip(
              label: Text(_dayNames[index]),
              selected: _selectedDays[index],
              onSelected: (selected) {
                setState(() {
                  _selectedDays[index] = selected;
                });
              },
              selectedColor: Colors.teal,
              labelStyle: TextStyle(
                color: _selectedDays[index] ? Colors.white : Colors.black54,
                fontSize: 12,
              ),
              backgroundColor: Colors.grey.shade200,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(6),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              showCheckmark: false,
            ),
          );
        }),
      ),
    );
  }
}
