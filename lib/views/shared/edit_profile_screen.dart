import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/intern_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/custom_loader.dart';

// Allows both admin and intern to update their profile details.
class EditProfileScreen extends StatefulWidget {
  final InternModel profile;
  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _educationController;
  late final TextEditingController _skillsController;
  bool _isLoading = false;
  final _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.profile.fullName);
    _phoneController = TextEditingController(text: widget.profile.phone);
    _addressController = TextEditingController(text: widget.profile.address);
    _educationController = TextEditingController(
      text: widget.profile.education,
    );
    _skillsController = TextEditingController(text: widget.profile.skills);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _educationController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Update display name in Firebase Auth
      await authProvider.user!.updateDisplayName(
        _fullNameController.text.trim(),
      );

      // Update Firestore profile
      await _firestoreService.saveUserProfile(
        InternModel(
          uid: authProvider.user!.uid,
          fullName: _fullNameController.text.trim(),
          email: widget.profile.email, // Non-Editable field
          role: widget.profile.role, // Non-Editable field
          progress: widget.profile.progress,
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          education: _educationController.text.trim(),
          skills: _skillsController.text.trim(),
          createdAt: widget.profile.createdAt,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully.")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update profile.")),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Column(
      children: [
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) => value == null || value.isEmpty
              ? AppStrings.errorEmptyField
              : null,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: widget.profile.email,
                enabled: false, // Read-only
                decoration: InputDecoration(
                  labelText: "Email Address",
                  prefixIcon: const Icon(Icons.email_outlined),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildField(
                AppStrings.fullName,
                _fullNameController,
                Icons.person_outlined,
              ),
              _buildField(
                AppStrings.phone,
                _phoneController,
                Icons.phone_outlined,
              ),
              _buildField(
                AppStrings.address,
                _addressController,
                Icons.location_on_outlined,
              ),
              _buildField(
                AppStrings.education,
                _educationController,
                Icons.school_outlined,
              ),
              _buildField(
                AppStrings.skills,
                _skillsController,
                Icons.code_outlined,
                maxLines: 3,
              ),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CustomLoader(color: Colors.white)
                      : const Text(
                          "Save Changes",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
