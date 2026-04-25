import 'package:cloud_firestore/cloud_firestore.dart';

// Represents a task assigned to an intern.
class TaskModel {
  final String taskId;
  final String title;
  final String description;
  final String status;
  final String assignedTo;
  final DateTime dueDate;
  final DateTime createdAt;

  TaskModel({
    required this.taskId,
    required this.title,
    required this.description,
    required this.status,
    required this.assignedTo,
    required this.dueDate,
    required this.createdAt,
  });

  // Converts Firestore document into TaskModel object
  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TaskModel(
      taskId: doc.id,
      title: data["title"] ?? "",
      description: data["description"] ?? "",
      status: data["status"] ?? "pending",
      assignedTo: data["assignedTo"] ?? "",
      dueDate: (data["dueDate"] as Timestamp).toDate(),
      createdAt: (data["createdAt"] as Timestamp).toDate(),
    );
  }

  // Converts TaskModel object into Map for saving to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      "title": title,
      "description": description,
      "status": status,
      "assignedTo": assignedTo,
      "dueDate": dueDate,
      "createdAt": createdAt,
    };
  }
}
