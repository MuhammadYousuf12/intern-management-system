import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/intern_model.dart';
import '../models/task_model.dart';

// Handles all Firestore database operations.
// All CRUD operations for intern and tasks are manages here.
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Save or update user profile (for both admin & inter) ---
  Future<void> saveUserProfile(InternModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(user.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      throw Exception("Failed to save profile: $e");
    }
  }

  // --- Get single intern by uid ---
  Future<InternModel> getIntern(String uid) async {
    DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
    return InternModel.fromFirestore(doc);
  }

  // --- Get all interns (admin olny) ---
  Stream<List<InternModel>> getAllInterns() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'intern')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => InternModel.fromFirestore(doc))
              .toList(),
        );
  }

  // --- Real-time stream for single intern profile updates ---
  Stream<InternModel> getInternStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => InternModel.fromFirestore(doc));
  }

  // --- Update task progress and note - (intern only) ---
  Future<void> updateTaskProgress(
    String taskId,
    String internUid,
    int progress,
    String note,
  ) async {
    String status = "pending";
    if (progress > 0 && progress < 100) status = "inProgress";
    if (progress == 100) status = "completed";

    // Step 1 - Update task
    await _firestore.collection('tasks').doc(taskId).update({
      'progress': progress,
      'progressNote': note,
      'status': status,
    });

    // Step 2 - Fetch all tasks for particular intern
    final tasksSnapshot = await _firestore
        .collection('tasks')
        .where('assignedTo', isEqualTo: internUid)
        .get();

    if (tasksSnapshot.docs.isEmpty) return;

    int totalProgress = 0;
    for (final doc in tasksSnapshot.docs) {
      // Use new progress for the updated task, old value for rest
      if (doc.id == taskId) {
        totalProgress += progress;
      } else {
        totalProgress += (doc['progress'] as num?)?.toInt() ?? 0;
      }
    }

    final overallProgress = (totalProgress / tasksSnapshot.docs.length).round();

    // Step 3 - Update intern's overall progress
    await _firestore.collection('users').doc(internUid).update({
      'progress': overallProgress,
    });
  }

  // --- Add new task (admin only) ---
  Future<void> addTask(TaskModel task) async {
    await _firestore.collection('tasks').add(task.toFirestore());
  }

  // --- Get all tasks - admin view with real-time updates ---
  Stream<List<TaskModel>> getAllTasks() {
    return _firestore.collection('tasks').snapshots().asyncMap((
      snapshot,
    ) async {
      final allTasks = snapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();

      // Group by title - show only unique tasks
      final Map<String, List<TaskModel>> grouped = {};
      for (final task in allTasks) {
        final key = task.taskGroupId.isEmpty ? task.taskId : task.taskGroupId;
        grouped.putIfAbsent(key, () => []).add(task);
      }
      return grouped.values.map((tasks) {
        // Calculate average progress accross all interns
        final avgProgress = tasks.isEmpty
            ? 0
            : (tasks.map((t) => t.progress).reduce((a, b) => a + b) /
                      tasks.length)
                  .round();

        // Pick first task as representative override progress with average
        final representative = tasks.first;
        return TaskModel(
          taskId: representative.taskId,
          taskGroupId: representative.taskGroupId,
          title: representative.title,
          description: representative.description,
          status: avgProgress == 0
              ? 'pending'
              : avgProgress == 100
              ? 'completed'
              : 'inprogress',
          assignedTo: representative.assignedTo,
          progress: avgProgress,
          progressNote: "",
          dueDate: representative.dueDate,
          createdAt: representative.createdAt,
          isCustomized: representative.isCustomized,
        );
      }).toList();
    });
  }

  // --- Update single task - marks customized - group update skip (admin only) ---
  Future<void> updateSingleTask(
    String taskId,
    String title,
    String description,
  ) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'title': title,
      'description': description,
      'isCustomized': true,
    });
  }

  // --- Update all non-customized tasks in a group ---
  Future<void> updateTaskGroup(
    String taskGroupId,
    String singleTaskId,
    String title,
    String description,
  ) async {
    if (taskGroupId.isEmpty) {
      await _firestore.collection('tasks').doc(singleTaskId).update({
        'title': title,
        'description': description,
      });
      return;
    }

    final snapshot = await _firestore
        .collection('tasks')
        .where('taskGroupId', isEqualTo: taskGroupId)
        .where('isCustomized', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'title': title, 'description': description});
    }
    await batch.commit();
  }

  // --- Get tasks for specific intern ---
  Stream<List<TaskModel>> getInternTasks(String uid) {
    return _firestore
        .collection('tasks')
        .where('assignedTo', isEqualTo: uid)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList(),
        );
  }

  // --- Update task status ---
  Future<void> updateTaskStatus(String taskId, String status) async {
    await _firestore.collection('tasks').doc(taskId).update({'status': status});
  }

  // --- Delete task from intern detail screen (admin only) ---
  Future<void> deleteSingleTask(String taskId) async {
    await _firestore.collection('tasks').doc(taskId).delete();
  }

  // --- Delete all tasks in a group from tasks tab ---
  Future<void> deleteTaskGroup(String taskGroupId, String singleTaskId) async {
    if (taskGroupId.isEmpty) {
      await _firestore.collection('tasks').doc(singleTaskId).delete();
      return;
    }
    final snapshot = await _firestore
        .collection('tasks')
        .where('taskGroupId', isEqualTo: taskGroupId)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
