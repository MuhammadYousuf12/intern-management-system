import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/intern_model.dart';
import '../../models/task_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/shimmer_loader.dart';

// Shows complete intern profile and real-time task progress.
// Uses StreamBuilder for live updates across all connected devices.
class InternDetailScreen extends StatelessWidget {
  final String internUid;
  const InternDetailScreen({super.key, required this.internUid});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Intern Details')),
      body: StreamBuilder<InternModel>(
        stream: firestoreService.getInternStream(internUid),
        builder: (context, internSnapshot) {
          if (!internSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final intern = internSnapshot.data!;

          return StreamBuilder<List<TaskModel>>(
            stream: firestoreService.getInternTasks(internUid),
            builder: (context, taskSnapshot) {
              final tasks = taskSnapshot.data ?? [];
              final completed = tasks
                  .where((t) => t.status == 'completed')
                  .length;
              final progress = tasks.isEmpty
                  ? 0
                  : ((completed / tasks.length) * 100).round();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Profile Card ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.2,
                            ),
                            child: Text(
                              intern.fullName.isNotEmpty
                                  ? intern.fullName[0].toUpperCase()
                                  : 'I',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            intern.fullName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            intern.email,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- Bio Data ---
                    _InfoTile(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: intern.phone,
                    ),
                    _InfoTile(
                      icon: Icons.location_on_outlined,
                      label: 'Address',
                      value: intern.address,
                    ),
                    _InfoTile(
                      icon: Icons.school_outlined,
                      label: 'Education',
                      value: intern.education,
                    ),
                    _InfoTile(
                      icon: Icons.code_outlined,
                      label: 'Skills',
                      value: intern.skills,
                    ),
                    const SizedBox(height: 20),

                    // --- Overall Progress (realtime) ---
                    Text(
                      'Overall Progress',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: tasks.isEmpty ? 0 : completed / tasks.length,
                        minHeight: 10,
                        backgroundColor: Colors.grey[200],
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$progress%',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- Tasks (realtime) ---
                    Text(
                      'Assigned Tasks',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    !taskSnapshot.hasData
                        ? const ShimmerList()
                        : tasks.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'No tasks assigned yet.',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: tasks.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              return _TaskTile(task: tasks[index]);
                            },
                          ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
              Text(
                value.isEmpty ? 'Not provided' : value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final TaskModel task;
  const _TaskTile({required this.task});

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'inProgress':
        return AppColors.accent;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'completed':
        return AppStrings.completed;
      case 'inProgress':
        return AppStrings.inProgress;
      default:
        return AppStrings.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (task.description.isNotEmpty)
                  Text(
                    task.description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor(task.status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _statusLabel(task.status),
              style: TextStyle(
                fontSize: 10,
                color: _statusColor(task.status),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
