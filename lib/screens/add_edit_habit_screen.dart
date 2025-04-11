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

  bool get _isEditing => widget.habit != null;

  // Helper for day names
  final List<String> _dayNames = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.habit?.name ?? '');
    _descriptionController = TextEditingController(
      text: '',
    ); // TODO: Add description to Habit model
    _targetStreakController = TextEditingController(
      text: widget.habit?.targetStreak.toString() ?? '21',
    );
    if (_isEditing && widget.habit != null) {
      _descriptionController.text = widget.habit!.description ?? '';
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
    _reasonControllers[index].dispose();
    setState(() {
      _reasonControllers.removeAt(index);
      if (_reasonControllers.isEmpty) {
        _reasonControllers.add(TextEditingController());
      }
    });
  }

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
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;
      final description = _descriptionController.text;
      final reasons =
          _reasonControllers
              .map((c) => c.text)
              .where((r) => r.isNotEmpty)
              .toList();
      final targetStreak = int.tryParse(_targetStreakController.text) ?? 21;

      if (_isEditing) {
        // TODO: Implement editHabit in Notifier
        print('Editing habit (Not implemented yet)');
      } else {
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
            );
        print(
          'Adding habit: $name, Desc: $description, Reasons: $reasons, Start: $_startDate, Target: $targetStreak, Schedule: $_scheduleType, Days: $_selectedDays',
        );
      }
      Navigator.of(context).pop();
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
            // --- REMINDERS Tab Content (Placeholder) ---
            const Center(child: Text('Reminders settings (TODO)')),
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
}
