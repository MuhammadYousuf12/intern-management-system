import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/intern_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/custom_loader.dart';
import 'intern_detail_screen.dart';
import 'add_task_screen.dart';

// Admin dashboard — manage interns, view progress, assign tasks.
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.adminDashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddTaskScreen()),
        ),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text(
          AppStrings.addTask,
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: StreamBuilder<List<InternModel>>(
        stream: firestoreService.getAllInterns(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CustomLoader());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
              // --- Stats Header ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: AppColors.primary,
                child: Row(
                  children: [
                    _headerStat("${interns.length}", "Total Interns"),
                    const SizedBox(width: 16),
                    _headerStat(
                      "${interns.where((i) => i.progress == 100).length}",
                      "Completed",
                    ),
                  ],
                ),
              ),
              // --- Interns List ---
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
      ),
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
      child: Container(
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
                      value: intern.progress / 100,
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
              "${intern.progress}%",
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
