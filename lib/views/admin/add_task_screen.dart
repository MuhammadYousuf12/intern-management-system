import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/task_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/custom_loader.dart';

// Admin screen to add a new task — assigned to all interns automatically.
class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _isLoading = false;
  final _firestoreService = FirestoreService();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleAddTask() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // Fetch all interns
      final snapshot = await FirebaseFirestore.instance
          .collection("users")
          .where("role", isEqualTo: "intern")
          .get();

      // Assign task to every intern
      for (final doc in snapshot.docs) {
        final task = TaskModel(
          taskId: "",
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          status: "pending",
          assignedTo: doc.id,
          dueDate: _dueDate,
          createdAt: DateTime.now(),
        );
        await _firestoreService.addTask(task);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to add task.")));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Task")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Assign to all interns",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // --- Task Title ---
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: "Task Title",
                  prefixIcon: const Icon(Icons.task_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? AppStrings.errorEmptyField
                    : null,
              ),
              const SizedBox(height: 16),

              // --- Description ---
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Task Description",
                  prefixIcon: const Icon(Icons.description_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? AppStrings.errorEmptyField
                    : null,
              ),
              const SizedBox(height: 16),

              // --- Due Date ---
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.primary,
                ),
                title: Text(
                  "Due: ${_dueDate.day}/${_dueDate.month}/${_dueDate.year}",
                ),
                trailing: TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dueDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setState(() => _dueDate = picked);
                  },
                  child: const Text(
                    "Change",
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // --- Add Task Button ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleAddTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CustomLoader(color: Colors.white)
                      : const Text(
                          "Assign to All Interns",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
