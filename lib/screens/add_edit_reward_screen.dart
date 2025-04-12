import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reward.dart';
import '../providers/reward_provider.dart';

class AddEditRewardScreen extends ConsumerStatefulWidget {
  final Reward? reward; // Optional reward for editing

  const AddEditRewardScreen({super.key, this.reward});

  @override
  ConsumerState<AddEditRewardScreen> createState() =>
      _AddEditRewardScreenState();
}

class _AddEditRewardScreenState extends ConsumerState<AddEditRewardScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _pointCostController;
  // TODO: Add icon selection state later

  bool get _isEditing => widget.reward != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.reward?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.reward?.description ?? '',
    );
    _pointCostController = TextEditingController(
      text: widget.reward?.pointCost.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _pointCostController.dispose();
    super.dispose();
  }

  void _saveReward() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;
      final description = _descriptionController.text;
      final pointCost = int.tryParse(_pointCostController.text);

      if (pointCost == null || pointCost <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid positive point cost.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final rewardNotifier = ref.read(rewardProvider.notifier);

      if (_isEditing) {
        // Update existing reward
        final updatedReward = Reward(
          id: widget.reward!.id, // Keep original ID
          name: name,
          description: description.isNotEmpty ? description : null,
          pointCost: pointCost,
          iconCodePoint:
              widget.reward!.iconCodePoint, // Keep original icon for now
        );
        rewardNotifier.editReward(updatedReward);
      } else {
        // Add new reward
        rewardNotifier.addReward(
          name: name,
          description: description.isNotEmpty ? description : null,
          pointCost: pointCost,
          iconCodePoint: null, // Add later
        );
      }
      Navigator.of(context).pop(); // Go back after saving
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Reward' : 'Add Reward'),
        actions: [
          TextButton(
            onPressed: _saveReward,
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // TODO: Add Icon Picker here later
              _buildTextField(
                controller: _nameController,
                labelText: 'Reward Name',
                hintText: 'e.g., Movie Night',
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Please enter a name'
                            : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                labelText: 'Description (Optional)',
                hintText: 'e.g., Relax and watch a favorite film',
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _pointCostController,
                labelText: 'Point Cost',
                hintText: 'e.g., 50',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Please enter a point cost';
                  if (int.tryParse(value) == null || int.parse(value) <= 0)
                    return 'Enter a positive number';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper for text fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    int? maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 15,
        ),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
    );
  }
}
