import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/intern_model.dart';
import '../models/task_model.dart';

// Handles all Firestore database operations.
// All CRUD operations for intern and tasks are manages here.
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Save or update intern profile ---
  Future<void> saveInternProfile(InternModel intern) async {
    await _firestore
        .collection('users')
        .doc(intern.uid)
        .set(intern.toFirestore(), SetOptions(merge: true));
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

  // --- Update intern progress ---
  Future<void> updateProgress(String uid, int progress) async {
    await _firestore.collection('users').doc(uid).update({
      'progress': progress,
    });
  }

  // --- Add new task (admin only) ---
  Future<void> addTask(TaskModel task) async {
    await _firestore.collection('tasks').add(task.toFirestore());
  }

  // ---Get tasks for specific intern ---
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

  // --- Delete task (admin only) ---
  Future<void> deleteTask(String taskId) async {
    await _firestore.collection('tasks').doc(taskId).delete();
  }
}
