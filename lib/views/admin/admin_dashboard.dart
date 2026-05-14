import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../shared/theme_settings_screen.dart';
import '../../models/intern_model.dart';
import '../../models/task_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/shimmer_loader.dart';
import '../shared/edit_profile_screen.dart';
import '../shared/task_detail_screen.dart';
import 'intern_detail_screen.dart';
import 'add_task_screen.dart';

// Admin dashboard - two tabs: Interns list and Tasks management.
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  InternModel? _currentProfile;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAdminProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final firestoreService = FirestoreService();
    // Listen to admin profile stream
    firestoreService.getInternStream(authProvider.user!.uid).listen((profile) {
      if (mounted) setState(() => _currentProfile = profile);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.adminDashboard),
        actions: [
          // Edit profile - enabled when profile is loaded
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: _currentProfile == null
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          EditProfileScreen(profile: _currentProfile!),
                    ),
                  ),
          ),
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ThemeSettingsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.logout(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.lightTextSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.people_outline), text: "Interns"),
            Tab(icon: Icon(Icons.task_outlined), text: "Tasks"),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddTaskScreen()),
        ),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_task, color: Colors.white),
        label: const Text("Add Task", style: TextStyle(color: Colors.white)),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // --- Tab 1: Interns ---
          _InternsTab(firestoreService: firestoreService),

          // --- Tab 2: Tasks ---
          _TasksTab(firestoreService: firestoreService),
        ],
      ),
    );
  }
}

// Tab 1 - All interns with real-time progress.
class _InternsTab extends StatelessWidget {
  final FirestoreService firestoreService;
  const _InternsTab({required this.firestoreService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<InternModel>>(
      stream: firestoreService.getAllInterns(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: ShimmerList(itemCount: 5),
          );
        }
        if (snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              "No interns registered yet.",
              style: TextStyle(color: Colors.grey[500]),
            ),
          );
        }
        final interns = snapshot.data!;
        return Column(
          children: [
            // Stats header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: AppColors.primary,
              child: Row(
                children: [
                  _headerStat("${interns.length}", "Total Interns"),
                  const SizedBox(width: 24),
                  _headerStat(
                    "${interns.where((i) => i.progress == 100).length}",
                    "Completed",
                  ),
                ],
              ),
            ),
            // Interns list
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: interns.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return _InternTile(intern: interns[index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _headerStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

// Tab 2 - All tasks with edit and delete options.
class _TasksTab extends StatelessWidget {
  final FirestoreService firestoreService;
  const _TasksTab({required this.firestoreService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TaskModel>>(
      stream: firestoreService.getAllTasks(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: ShimmerList(itemCount: 5),
          );
        }
        if (snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              "No tasks created yet.",
              style: TextStyle(color: Colors.grey[500]),
            ),
          );
        }
        final tasks = snapshot.data!;
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            return _AdminTaskTile(task: tasks[index]);
          },
        );
      },
    );
  }
}

// Intern tile - clickable, shows progress.
class _InternTile extends StatelessWidget {
  final InternModel intern;
  const _InternTile({required this.intern});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InternDetailScreen(internUid: intern.uid),
        ),
      ),
      child: StreamBuilder<List<TaskModel>>(
        stream: FirestoreService().getInternTasks(intern.uid),
        builder: (context, taskSnapshot) {
          final tasks = taskSnapshot.data ?? [];
          final int progress = tasks.isEmpty
              ? 0
              : (tasks.map((t) => t.progress).reduce((a, b) => a + b) /
                        tasks.length)
                    .round();
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    intern.fullName.isNotEmpty
                        ? intern.fullName[0].toUpperCase()
                        : "I",
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        intern.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        intern.email,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress / 100,
                          minHeight: 6,
                          backgroundColor: Colors.grey[200],
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "$progress%",
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Admin task tile - shows task info with edit and delete options.
class _AdminTaskTile extends StatelessWidget {
  final TaskModel task;
  const _AdminTaskTile({required this.task});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TaskDetailScreen(
            task: task,
            isAdmin: true,
            isGroupEdit: true,
            isGroupDelete: true,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            if (task.description.isNotEmpty)
              Text(
                task.description,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 6),
            Text(
              "Due: ${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year}",
              style: TextStyle(
                fontSize: 11,
                color: AppColors.darkTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
