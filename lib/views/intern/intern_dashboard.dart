import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/intern_model.dart';
import '../../models/task_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/shimmer_loader.dart';

// Intern dashboard - real-time tasks and progress via Firestore streams.
class InternDashboard extends StatelessWidget {
  const InternDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final firestoreService = FirestoreService();
    final uid = authProvider.user!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.internDashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              await auth.logout();
            },
          ),
        ],
      ),
      body: StreamBuilder<InternModel>(
        stream: firestoreService.getInternStream(uid),
        builder: (context, internSnapshot) {
          if (!internSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final profile = internSnapshot.data!;

          return StreamBuilder<List<TaskModel>>(
            stream: firestoreService.getInternTasks(uid),
            builder: (context, taskSnapshot) {
              if (!taskSnapshot.hasData) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildHeader(profile, 0, 0, 0),
                      const SizedBox(height: 24),
                      const ShimmerList(itemCount: 4),
                    ],
                  ),
                );
              }

              final tasks = taskSnapshot.data!;
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
                    // --- Header ---
                    _buildHeader(profile, tasks.length, completed, progress),
                    const SizedBox(height: 24),

                    // --- Progress Bar ---
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

                    // --- Tasks ---
                    Text(
                      AppStrings.internTasks,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    tasks.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
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
                              return _TaskCard(task: tasks[index]);
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

  Widget _buildHeader(
    InternModel profile,
    int total,
    int completed,
    int progress,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, ${profile.fullName} 👋',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statChip('$total', 'Tasks'),
              const SizedBox(width: 12),
              _statChip('$completed', 'Done'),
              const SizedBox(width: 12),
              _statChip('$progress%', 'Progress'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  const _TaskCard({required this.task});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
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
          if (task.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              task.description,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Due: ${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year}',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
