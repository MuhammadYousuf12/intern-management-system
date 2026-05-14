import 'package:cloud_firestore/cloud_firestore.dart';

// Represents a task assigned to an intern.
class TaskModel {
  final String taskId;
  final String taskGroupId;
  final String title;
  final String description;
  final String status;
  final String assignedTo;
  final int progress;
  final String progressNote;
  final DateTime dueDate;
  final DateTime createdAt;
  final bool isCustomized;

  TaskModel({
    required this.taskId,
    required this.taskGroupId,
    required this.title,
    required this.description,
    required this.status,
    required this.assignedTo,
    required this.progress,
    required this.progressNote,
    required this.dueDate,
    required this.createdAt,
    required this.isCustomized,
  });

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TaskModel(
      taskId: doc.id,
      taskGroupId: data["taskGroupId"] ?? "",
      title: data["title"] ?? "",
      description: data["description"] ?? "",
      status: data["status"] ?? "pending",
      assignedTo: data["assignedTo"] ?? "",
      progress: data["progress"] ?? 0,
      progressNote: data["progressNote"] ?? "",
      dueDate: (data["dueDate"] as Timestamp).toDate(),
      createdAt: (data["createdAt"] as Timestamp).toDate(),
      isCustomized: data["isCustomized"] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "taskGroupId": taskGroupId,
      "title": title,
      "description": description,
      "status": status,
      "assignedTo": assignedTo,
      "progress": progress,
      "progressNote": progressNote,
      "dueDate": dueDate,
      "createdAt": createdAt,
      "isCustomized": isCustomized,
    };
  }
}
