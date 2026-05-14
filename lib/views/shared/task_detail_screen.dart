import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/task_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/custom_loader.dart';

// Task detail screen - shows full task info.
// Intern can update progress, admin can delete task.
class TaskDetailScreen extends StatefulWidget {
  final TaskModel task;
  final bool isAdmin;
  final bool isGroupEdit;
  final bool isGroupDelete;
  final String? internUid;
  const TaskDetailScreen({
    super.key,
    required this.task,
    required this.isAdmin,
    this.isGroupEdit = false,
    this.isGroupDelete = false,
    this.internUid,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _firestoreService = FirestoreService();
  final _noteController = TextEditingController();
  double _progressValue = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load existing progress
    _progressValue = widget.task.progress.toDouble();
    _noteController.text = widget.task.progressNote;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _updateProgress() async {
    setState(() => _isLoading = true);
    try {
      await _firestoreService.updateTaskProgress(
        widget.task.taskId,
        widget.task.assignedTo,
        _progressValue.round(),
        _noteController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Progress updated successfully.")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showEditDialog(BuildContext context) {
    final titleController = TextEditingController(text: widget.task.title);
    final descController = TextEditingController(text: widget.task.description);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Edit Task"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: "Task Title",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: descController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              final desc = descController.text.trim();

              // Close dialog first
              Navigator.pop(dialogContext);

              try {
                if (widget.isGroupEdit) {
                  // Update for all non-customized intern
                  await FirestoreService().updateTaskGroup(
                    widget.task.taskGroupId,
                    widget.task.taskId,
                    title,
                    desc,
                  );
                } else {
                  await FirestoreService().updateSingleTask(
                    widget.task.taskId,
                    title,
                    desc,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to update task.")),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTask() async {
    final message = widget.isGroupDelete
        ? "This will delete this task for all intern. Are you sure?"
        : "This will delete this task for this intern only. Are you sure?";

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Task"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      if (widget.isGroupDelete) {
        // Delete for all interns
        await _firestoreService.deleteTaskGroup(
          widget.task.taskGroupId,
          widget.task.taskId,
        );
      } else {
        // Delete for this intern only
        await _firestoreService.deleteSingleTask(widget.task.taskId);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to delete task.")));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case "completed":
        return Colors.green;
      case "inProgress":
        return AppColors.accent;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case "completed":
        return AppStrings.completed;
      case "inProgress":
        return AppStrings.inProgress;
      default:
        return AppStrings.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Task Details"),
        actions: [
          // Admin can delete task
          if (widget.isAdmin) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _showEditDialog(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _isLoading ? null : _deleteTask,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Status Badge ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _statusColor(widget.task.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _statusLabel(widget.task.status),
                style: TextStyle(
                  color: _statusColor(widget.task.status),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- Title ---
            Text(
              widget.task.title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),

            // --- Description ---
            Text(
              "Description",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.task.description.isEmpty
                  ? "No description provided."
                  : widget.task.description,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 16),

            // --- Due Date ---
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  "Due: ${widget.task.dueDate.day}/${widget.task.dueDate.month}/${widget.task.dueDate.year}",
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- Progress Section ---
            Text(
              "Current Progress",
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _progressValue / 100,
                      minHeight: 10,
                      backgroundColor: Colors.grey[200],
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "${_progressValue.round()}%",
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            // --- Intern can update progress ---
            if (!widget.isAdmin) ...[
              const SizedBox(height: 16),
              Text(
                "Update Your Progress",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Slider(
                value: _progressValue,
                min: 0,
                max: 100,
                divisions: 20,
                activeColor: AppColors.primary,
                label: "${_progressValue.round()}%",
                onChanged: (value) => setState(() => _progressValue = value),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Progress Note",
                  hintText: "e.g. Completed basic structure...",
                  prefixIcon: const Icon(Icons.notes_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProgress,
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
                          "Save Progress",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],

            // --- Previous progress note ---
            if (widget.task.progressNote.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                "Last Update Note",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  widget.task.progressNote,
                  style: const TextStyle(fontSize: 13, height: 1.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
