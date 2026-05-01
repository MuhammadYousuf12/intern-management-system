import 'package:cloud_firestore/cloud_firestore.dart';

// Represent and intern's profile data stored in Firestore.
class InternModel {
  final String uid;
  final String fullName;
  final String email;
  final String role;
  final int progress;
  final String phone;
  final String address;
  final String education;
  final String skills;
  final DateTime createdAt;

  InternModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.role,
    required this.progress,
    required this.phone,
    required this.address,
    required this.education,
    required this.skills,
    required this.createdAt,
  });

  // Converts Firestore document into InternModel object
  factory InternModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return InternModel(
      uid: doc.id,
      fullName: data["fullName"] ?? "",
      email: data["email"] ?? "",
      role: data["role"] ?? "intern",
      progress: data["progress"] ?? 0,
      phone: data["phone"] ?? "",
      address: data["address"] ?? "",
      education: data["education"] ?? "",
      skills: data["skills"] ?? "",
      createdAt: (data["createdAt"] as Timestamp).toDate(),
    );
  }

  // Converts InternModel object into Map for saving to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      "fullName": fullName,
      "email": email,
      "role": role,
      "progress": progress,
      "phone": phone,
      "address": address,
      "education": education,
      "skills": skills,
      "createdAt": Timestamp.fromDate(createdAt),
    };
  }
}
