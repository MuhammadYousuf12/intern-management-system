import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

// Custom animated loader to replace default CircularProgressIndicator.
class CustomLoader extends StatelessWidget {
  final Color color;
  const CustomLoader({super.key, this.color = AppColors.primary});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}
