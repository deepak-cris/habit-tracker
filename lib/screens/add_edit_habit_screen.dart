import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // Import intl package
import '../models/habit.dart';
import 'home_screen.dart'; // To access habitProvider

class AddEditHabitScreen extends ConsumerStatefulWidget {
  final Habit? habit; // Optional habit for editing

  const AddEditHabitScreen({super.key, this.habit});

  @override
  ConsumerState<AddEditHabitScreen> createState() => _AddEditHabitScreenState();
}

class _AddEditHabitScreenState extends ConsumerState<AddEditHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _targetStreakController;
  List<TextEditingController> _reasonControllers = [
    TextEditingController(),
  ]; // Start with one reason field
  DateTime _startDate = DateTime.now();
  String _scheduleType = 'Fixed'; // Default schedule type
  List<bool> _selectedDays = List.filled(
    7,
    true,
  ); // Default to all days selected for Fixed
  // Updated state to hold dynamic map for note
  List<Map<String, dynamic>> _reminderTimes = []; // State for reminder times

  bool get _isEditing => widget.habit != null;

  // Helper for day names
  final List<String> _dayNames = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.habit?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.habit?.description ?? '', // Load description if editing
    );
    _targetStreakController = TextEditingController(
      text: widget.habit?.targetStreak.toString() ?? '21',
    );
    if (_isEditing && widget.habit != null) {
      _reasonControllers =
          widget.habit!.reasons
              .map((r) => TextEditingController(text: r))
              .toList();
      if (_reasonControllers.isEmpty) {
        _reasonControllers.add(
          TextEditingController(),
        ); // Ensure at least one if editing and reasons were empty
      }
      _startDate = widget.habit!.startDate;
      _scheduleType = widget.habit!.scheduleType;
      _selectedDays = List.from(widget.habit!.selectedDays); // Copy list
      // Initialize reminder times if editing (ensure type compatibility)
      _reminderTimes = List<Map<String, dynamic>>.from(
        widget.habit!.reminderTimes?.map((e) => Map<String, dynamic>.from(e)) ??
            [],
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _targetStreakController.dispose();
    for (var controller in _reasonControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addReasonField() {
    setState(() {
      _reasonControllers.add(TextEditingController());
    });
  }

  void _removeReasonField(int index) {
    // Dispose the controller before removing
    if (index < _reasonControllers.length) {
      _reasonControllers[index].dispose();
    }
    setState(() {
      if (index < _reasonControllers.length) {
        _reasonControllers.removeAt(index);
      }
      if (_reasonControllers.isEmpty) {
        _reasonControllers.add(TextEditingController());
      }
    });
  }

  // --- Reminder Time Picker ---
  Future<void> _selectReminderTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      // Show dialog to add optional note
      final String? note = await _showAddReminderNoteDialog(context);

      final newReminder = {
        'hour': picked.hour,
        'minute': picked.minute,
        'note': note, // Add the note (can be null)
      };

      // Check for duplicate time only (allow same time with different notes if desired, though maybe not ideal UX)
      // Let's prevent exact duplicates (time + note) for now.
      bool exists = _reminderTimes.any(
        (t) =>
            t['hour'] == newReminder['hour'] &&
            t['minute'] == newReminder['minute'] &&
            t['note'] == newReminder['note'],
      );

      if (!exists) {
        // Check if time already exists, regardless of note, to potentially warn user or replace?
        // For simplicity now, just add if the exact combo (time+note) doesn't exist.
        // A better UX might involve updating the note if the time exists.
        setState(() {
          _reminderTimes.add(newReminder);
          // Sort reminders after adding
          _reminderTimes.sort((a, b) {
            // Handle potential nulls if needed, though 'hour'/'minute' should always exist
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
        // Show confirmation message for adding reminder locally
        if (mounted) {
          // Check if mounted before showing Snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reminder added. Press SAVE to confirm changes.'),
              duration: Duration(seconds: 2), // Shorter duration
            ),
          );
        }
      } else {
        // Optional: Show message if reminder already exists
        if (mounted) {
          // Check if mounted before showing Snackbar
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

  // --- Dialog for Reminder Note ---
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
            maxLines: null, // Allow multiple lines
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Return null (no note)
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
    // Show confirmation message for removing reminder locally
    if (mounted) {
      // Check if mounted before showing Snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reminder removed. Press SAVE to confirm changes.'),
          duration: Duration(seconds: 2), // Shorter duration
          backgroundColor: Colors.orange, // Indicate removal
        ),
      );
    }
  }
  // --- End Reminder Time Picker ---

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  void _saveHabit() {
    print("SAVE button pressed - _saveHabit called");
    // Check if the form state exists and validate *if* it exists
    final formState = _formKey.currentState;
    bool isFormValid =
        formState?.validate() ?? false; // Validate if formState is not null

    // Also check if the required name field is filled, regardless of tab
    final name = _nameController.text;
    if (name.isEmpty) {
      print("Validation failed: Name is empty.");
      // Optionally show a message to the user to fill the name field
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a habit name on the HABIT tab.'),
          backgroundColor: Colors.red,
        ),
      );
      return; // Stop saving if name is empty
    }

    // Proceed if the name is not empty AND (either the form is valid OR the form doesn't exist because we are on the Reminders tab)
    if (formState == null || isFormValid) {
      print("Proceeding with save...");
      // final name = _nameController.text; // Already got name
      final description = _descriptionController.text;
      final reasons =
          _reasonControllers
              .map((c) => c.text)
              .where((r) => r.isNotEmpty)
              .toList();
      final targetStreak = int.tryParse(_targetStreakController.text) ?? 21;
      // Ensure the list being passed is of the correct type
      final reminderTimes = List<Map<String, dynamic>>.from(_reminderTimes);

      if (_isEditing && widget.habit != null) {
        // Create updated habit object
        final updatedHabit = Habit(
          id: widget.habit!.id, // Keep original ID
          name: name,
          description: description.isNotEmpty ? description : null,
          reasons: reasons,
          startDate: _startDate,
          scheduleType: _scheduleType,
          selectedDays: _selectedDays,
          targetStreak: targetStreak,
          dateStatus: widget.habit!.dateStatus, // Keep original status map
          notes: widget.habit!.notes, // Keep original notes map
          isMastered: widget.habit!.isMastered, // Keep original mastered status
          reminderTimes:
              reminderTimes.isNotEmpty
                  ? reminderTimes
                  : null, // Pass updated reminders
        );
        ref.read(habitProvider.notifier).editHabit(updatedHabit);
        // Show confirmation message for edit
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Habit "${updatedHabit.name}" updated.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Adding a new habit
        ref
            .read(habitProvider.notifier)
            .addHabit(
              name: name,
              description: description.isNotEmpty ? description : null,
              reasons: reasons,
              startDate: _startDate,
              scheduleType: _scheduleType,
              selectedDays: _selectedDays,
              targetStreak: targetStreak,
              reminderTimes:
                  reminderTimes.isNotEmpty
                      ? reminderTimes
                      : null, // Pass reminders
            );
        // Show confirmation message for add
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Habit "$name" added.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
      // Pop after showing snackbar, adding a slight delay for visibility
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          // Check if the widget is still in the tree
          Navigator.of(context).pop();
        }
      });
    } else {
      // This else block now specifically means form validation failed (formState was not null, but validate returned false)
      print("Form validation failed.");
      // Optionally show a generic validation error message if specific field errors aren't visible
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('Please fix errors on the HABIT tab.'), backgroundColor: Colors.red),
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[100], // Background for the whole screen
        appBar: AppBar(
          backgroundColor: Colors.teal, // Teal AppBar
          title: Text(
            _isEditing ? 'Edit Habit' : 'Add New Habit',
            style: const TextStyle(color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'CANCEL',
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: _saveHabit,
              child: const Text(
                'SAVE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          bottom: const TabBar(
            tabs: [Tab(text: 'HABIT'), Tab(text: 'REMINDERS')],
            labelColor: Colors.white,
            indicatorColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: TabBarView(
          children: [
            // --- HABIT Tab Content ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _buildTextFieldSection(
                      label: 'Give this habit a name',
                      controller: _nameController,
                      hint: 'Habit',
                      validator:
                          (value) =>
                              value == null || value.isEmpty
                                  ? 'Please enter a habit name'
                                  : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextFieldSection(
                      label: 'Give it a description (optional)',
                      controller: _descriptionController,
                      hint: 'Description',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Reasons',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ..._buildReasonFields(),
                    Center(
                      child: IconButton(
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: Colors.pink,
                        ),
                        onPressed: _addReasonField,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionContainer(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Start Date'),
                          TextButton(
                            onPressed: () => _selectStartDate(context),
                            child: Text(
                              DateFormat('dd-MM-yyyy').format(_startDate),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select a schedule',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          DropdownButtonFormField<String>(
                            value: _scheduleType,
                            items:
                                ['Fixed', 'Flexible']
                                    .map(
                                      (label) => DropdownMenuItem(
                                        value: label,
                                        child: Text(label),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              setState(() {
                                _scheduleType = value!;
                              });
                            },
                            decoration: const InputDecoration(
                              border: UnderlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(vertical: 4),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'When do you want to perform the habit ?',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          _buildDaySelector(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextFieldSection(
                      label: 'Target Streak',
                      controller: _targetStreakController,
                      hint: '21 days',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value != null &&
                            value.isNotEmpty &&
                            (int.tryParse(value) == null ||
                                int.parse(value) <= 0)) {
                          return 'Please enter a valid positive number';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            // --- REMINDERS Tab Content ---
            _buildRemindersTab(),
          ],
        ),
      ),
    );
  }

  // Helper for Text Field sections
  Widget _buildTextFieldSection({
    required String label,
    required TextEditingController controller,
    required String hint,
    int? maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
        ),
      ],
    );
  }

  // Helper to build dynamic reason fields
  List<Widget> _buildReasonFields() {
    return List.generate(_reasonControllers.length, (index) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _reasonControllers[index],
                decoration: InputDecoration(
                  hintText: 'Reason ${index + 1}',
                  filled: true,
                  fillColor: Colors.white,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ),
            if (_reasonControllers.length > 1)
              IconButton(
                icon: const Icon(
                  Icons.remove_circle_outline,
                  size: 20,
                  color: Colors.red,
                ),
                onPressed: () => _removeReasonField(index),
              ),
          ],
        ),
      );
    });
  }

  // Helper to build the day selector buttons - wrapped in ScrollView
  Widget _buildDaySelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: List.generate(7, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 2.0,
            ), // Reduced horizontal padding
            child: ChoiceChip(
              label: Text(_dayNames[index]),
              selected: _selectedDays[index],
              onSelected: (selected) {
                // Corrected: Removed duplicate onSelected
                setState(() {
                  _selectedDays[index] = selected;
                });
              },
              selectedColor:
                  Colors.teal, // Corrected: Removed duplicate selectedColor
              labelStyle: TextStyle(
                color: _selectedDays[index] ? Colors.white : Colors.black54,
                fontSize: 12,
              ),
              backgroundColor: Colors.grey.shade200,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(6),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              showCheckmark: false, // Hide the default checkmark
            ),
          );
        }),
      ),
    );
  }

  // Helper to wrap sections in a styled container
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

  // --- Build Method for Reminders Tab ---
  Widget _buildRemindersTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(
          'Set Reminder Times',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        if (_reminderTimes.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: Text(
                'No reminders set.',
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
                hour: timeMap['hour'] as int, // Cast as int
                minute: timeMap['minute'] as int, // Cast as int
              );
              final formattedTime = time.format(context); // Localized format
              final note = timeMap['note'] as String?; // Get optional note

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                child: ListTile(
                  leading: const Icon(Icons.alarm, color: Colors.teal),
                  title: Text(formattedTime),
                  subtitle:
                      note != null && note.isNotEmpty
                          ? Text(note)
                          : null, // Display note if exists
                  isThreeLine:
                      note != null &&
                      note.isNotEmpty, // Adjust height if note exists
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Remove Reminder',
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
            label: const Text('Add Reminder'),
            onPressed: () => _selectReminderTime(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // --- End Build Method for Reminders Tab ---
}
