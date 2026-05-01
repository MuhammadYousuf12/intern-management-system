// All static text used across the app.
// Update text here instead of hunting through individual screens.
class AppStrings {
  // --- App ---
  static const String appName = "Intern Management System";

  // --- Auth ---
  static const String login = "Login";
  static const String register = "Register";
  static const String logout = "Logout";
  static const String email = "Email Address";
  static const String password = "Password";
  static const String confirmPassword = "Confirm Password";
  static const String fullName = "Full Name";
  static const String forgotPassword = "Forgot Password";
  static const String noAccount = "Don't have an account?";
  static const String alreadyAccount = "Already have an account?";
  static const String signUp = "Sign Up";
  static const String signIn = "Sign In";

  // --- Email Varification ---
  static const String verifyEmail = "Verify Your Email";
  static const String verifyEmailMessage =
      "A verification email has been sent to your email address. Please verify to continue.";
  static const String resendEmail = "Resend Email";
  static const String checkingVerification = "Checking verification...";

  // --- Profile ---
  static const String completeProfile = "Complete Your Profile";
  static const String phone = "Phone Number";
  static const String address = "Address";
  static const String education = "Education";
  static const String skills = "Skills";
  static const String saveProfile = "Save Profile";

  // --- Dashboard ---
  static const String adminDashboard = "Admin Dashboard";
  static const String internDashboard = "Intern Dashboard";
  static const String internTasks = "Intern Tasks";
  static const String allInterns = "All Interns";
  static const String addTask = "Add Task";

  // --- Task Status ---
  static const String pending = "Pending";
  static const String inProgress = "In Progress";
  static const String completed = "Completed";

  // --- Errors ---
  static const String errorGeneral = "Something went wrong. Please try again.";
  static const String errorInvalidEmail = "Please enter a valid email address.";
  static const String errorWeakPassword =
      "Password must be at least 8 characters.";
  static const String errorPasswordMismatch = "Password do not match.";
  static const String errorEmptyField = "This field cannot be empty.";
}
