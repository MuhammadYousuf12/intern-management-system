import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/intern_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/intern_provider.dart';
import '../../widgets/custom_loader.dart';

// Profile complition screen shown after email verification.
// Intern fills in contact, address, education and skills before accessing dashboard.
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _educationController = TextEditingController();
  final _skillsController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    _educationController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final internProvider = Provider.of<InternProvider>(context, listen: false);

    final intern = InternModel(
      uid: authProvider.user!.uid,
      fullName:
          authProvider.user!.displayName ??
          authProvider.user!.email!.split("@")[0],
      email: authProvider.user!.email ?? "",
      role: "intern",
      progress: 0,
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      education: _educationController.text.trim(),
      skills: _skillsController.text.trim(),
      createdAt: DateTime.now(),
    );

    await internProvider.saveProfile(intern);

    if (mounted && internProvider.errorMessage == null) {
      Navigator.pushReplacementNamed(context, "/intern-dashboard");
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(internProvider.errorMessage ?? AppStrings.errorGeneral),
        ),
      );
    }
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon,
    String hint, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
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
    final internProvider = Provider.of<InternProvider>(context);
    final isTabletOrDesktop = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.completeProfile),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isTabletOrDesktop
                  ? MediaQuery.of(context).size.width * 0.25
                  : 24,
              vertical: 24,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Almost there!",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Complete your profile to get started.",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildField(
                    AppStrings.phone,
                    _phoneController,
                    Icons.phone_outlined,
                    "+92 300 0000000",
                  ),
                  _buildField(
                    AppStrings.address,
                    _addressController,
                    Icons.location_on_outlined,
                    "Karachi, Pakistan",
                  ),
                  _buildField(
                    AppStrings.education,
                    _educationController,
                    Icons.school_outlined,
                    "BS Computer Science",
                  ),
                  _buildField(
                    AppStrings.skills,
                    _skillsController,
                    Icons.code_outlined,
                    "Flutter, Dart, Firebase",
                    maxLines: 3,
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: internProvider.isLoading
                          ? null
                          : _handleSaveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: internProvider.isLoading
                          ? const CustomLoader(color: Colors.white)
                          : Text(
                              AppStrings.saveProfile,
                              style: const TextStyle(
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
        ),
      ),
    );
  }
}
