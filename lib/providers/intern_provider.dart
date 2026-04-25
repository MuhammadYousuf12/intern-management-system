import 'package:flutter/material.dart';
import '../models/intern_model.dart';
import '../models/task_model.dart';
import '../services/firestore_service.dart';

// Manages intern profile and task state across the app.
class InternProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  InternModel? _internProfile;
  List<TaskModel> _tasks = [];
  bool _isLoading = false;
  String? _errorMessage;

  InternModel? get internProfile => _internProfile;
  List<TaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // --- Load intern profile ---
  Future<void> loadInternProfile(String uid) async {
    _setLoading(true);
    try {
      _internProfile = await _firestoreService.getIntern(uid);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = "Failed to load profile.";
    } finally {
      _setLoading(false);
    }
  }

  // --- Listen to intern tasks in real time ---
  void listenToTasks(String uid) {
    _firestoreService.getInternTasks(uid).listen((tasks) {
      _tasks = tasks;
      notifyListeners();
    });
  }

  // --- Update task status ---
  Future<void> saveProfile(InternModel intern) async {
    _setLoading(true);
    try {
      await _firestoreService.saveInternProfile(intern);
      _internProfile = intern;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = "Failed to save profile.";
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
