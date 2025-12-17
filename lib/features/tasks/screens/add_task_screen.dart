import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/task_provider.dart';
import '../models/task.dart';

/// Add task screen dengan form validation
///
/// Features:
/// - Date picker (no past dates)
/// - Category dropdown dengan color indicators
/// - Adaptive priority selection (LayoutBuilder)
/// - Rich text editor (flutter_quill)
/// - Connected to TaskProvider for API calls
class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  // Form key untuk validation
  final _formKey = GlobalKey<FormState>();

  // Text editing controllers
  final _titleController = TextEditingController();
  late quill.QuillController _descriptionController;

  // Form state
  DateTime? _selectedDate;
  TaskCategory? _selectedCategory;
  TaskPriority _selectedPriority = TaskPriority.medium;
  bool _isLoading = false;
  bool _showDescriptionError = false;

  @override
  void initState() {
    super.initState();
    // Initialize QuillController dengan empty document
    _descriptionController = quill.QuillController.basic();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.addTask),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: AppStrings.taskTitle,
                  hintText: 'Misal: Mengerjakan PR Matematika',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: Validators.taskTitle,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),

              const SizedBox(height: 16),

              // Rich Text Editor (flutter_quill)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.taskDescription,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.onSurface.withOpacity(0.7),
                        ),
                  ),
                  const SizedBox(height: 8),

                  // Quill Toolbar
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                    ),
                    child: quill.QuillToolbar.simple(
                      configurations: quill.QuillSimpleToolbarConfigurations(
                        controller: _descriptionController,
                        sharedConfigurations: const quill.QuillSharedConfigurations(),
                      ),
                    ),
                  ),

                  // Quill Editor
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.outline),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(8),
                      ),
                    ),
                    child: quill.QuillEditor.basic(
                      configurations: quill.QuillEditorConfigurations(
                        controller: _descriptionController,
                        padding: const EdgeInsets.all(16),
                        placeholder: 'Jelaskan tugasmu secara detail...',
                        sharedConfigurations: const quill.QuillSharedConfigurations(),
                      ),
                    ),
                  ),

                  // Validation error message
                  if (_showDescriptionError)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 12),
                      child: Text(
                        AppStrings.descriptionMinLength,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.error,
                            ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Date Picker Field
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(4),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: AppStrings.taskDueDate,
                    hintText: AppStrings.selectDate,
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: const OutlineInputBorder(),
                    errorText: _selectedDate == null ? AppStrings.selectValidDate : null,
                  ),
                  child: Text(
                    _selectedDate == null
                        ? AppStrings.selectDate
                        : DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(_selectedDate!),
                    style: TextStyle(
                      color: _selectedDate == null
                          ? Theme.of(context).hintColor
                          : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Category Dropdown
              DropdownButtonFormField<TaskCategory>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: AppStrings.taskCategory,
                  hintText: AppStrings.selectCategory,
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: TaskCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _getCategoryColor(category),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(_getCategoryLabel(category)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
                },
                validator: (value) {
                  if (value == null) return AppStrings.selectValidCategory;
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Priority Selection Label
              Text(
                AppStrings.taskPriority,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.onSurface.withOpacity(0.7),
                    ),
              ),
              const SizedBox(height: 8),

              // Adaptive Priority Radio Buttons
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWideScreen = constraints.maxWidth > 600;

                  if (isWideScreen) {
                    return Row(
                      children: [
                        _buildPriorityRadio(TaskPriority.high, isWideScreen),
                        const SizedBox(width: 8),
                        _buildPriorityRadio(TaskPriority.medium, isWideScreen),
                        const SizedBox(width: 8),
                        _buildPriorityRadio(TaskPriority.low, isWideScreen),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPriorityRadio(TaskPriority.high, isWideScreen),
                      const SizedBox(height: 8),
                      _buildPriorityRadio(TaskPriority.medium, isWideScreen),
                      const SizedBox(height: 8),
                      _buildPriorityRadio(TaskPriority.low, isWideScreen),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveTask,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        AppStrings.save,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() => _selectedDate = pickedDate);
    }
  }

  Widget _buildPriorityRadio(TaskPriority priority, bool isWideScreen) {
    final isSelected = _selectedPriority == priority;
    final color = _getPriorityColor(priority);

    final child = InkWell(
      onTap: () => setState(() => _selectedPriority = priority),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : AppColors.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
                color: isSelected ? color : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 6),
            Text(
              _getPriorityLabel(priority),
              style: TextStyle(
                color: isSelected ? color : AppColors.onSurface.withOpacity(0.7),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );

    return isWideScreen ? Expanded(child: child) : child;
  }

  Color _getCategoryColor(TaskCategory category) {
    switch (category) {
      case TaskCategory.study:
        return AppColors.categoryStudy;
      case TaskCategory.assignment:
        return AppColors.categoryAssignment;
      case TaskCategory.project:
        return AppColors.categoryProject;
      case TaskCategory.personal:
        return AppColors.categoryPersonal;
    }
  }

  String _getCategoryLabel(TaskCategory category) {
    switch (category) {
      case TaskCategory.study:
        return AppStrings.categoryStudy;
      case TaskCategory.assignment:
        return AppStrings.categoryAssignment;
      case TaskCategory.project:
        return AppStrings.categoryProject;
      case TaskCategory.personal:
        return AppStrings.categoryPersonal;
    }
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return AppColors.priorityHigh;
      case TaskPriority.medium:
        return AppColors.priorityMedium;
      case TaskPriority.low:
        return AppColors.priorityLow;
    }
  }

  String _getPriorityLabel(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return AppStrings.priorityHigh;
      case TaskPriority.medium:
        return AppStrings.priorityMedium;
      case TaskPriority.low:
        return AppStrings.priorityLow;
    }
  }

  void _saveTask() async {
    // Validate date
    if (_selectedDate == null) {
      setState(() {});
      return;
    }

    // Validate category
    if (_selectedCategory == null) {
      setState(() {});
      return;
    }

    // Validate rich text description
    final descriptionPlainText =
        _descriptionController.document.toPlainText().trim();
    if (descriptionPlainText.isEmpty || descriptionPlainText.length < 10) {
      setState(() => _showDescriptionError = true);
      return;
    } else {
      setState(() => _showDescriptionError = false);
    }

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Show loading state
    setState(() => _isLoading = true);

    // Get description as plain text for API
    final description = descriptionPlainText;

    // Call provider to add task
    final taskProvider = context.read<TaskProvider>();
    final success = await taskProvider.addTask(
      title: _titleController.text.trim(),
      description: description,
      priority: _selectedPriority,
      category: _selectedCategory!,
      dueDate: _selectedDate!,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.taskCreated),
          backgroundColor: AppColors.statusCompleted,
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate back
      Navigator.pop(context, true);
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(taskProvider.errorMessage ?? 'Gagal menambah task'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
