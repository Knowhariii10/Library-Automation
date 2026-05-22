import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/premium_card.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _currentStep = 0; // 0: Enter Email, 1: Enter OTP, 2: New Password

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRequestOtp() async {
    if (_emailController.text.isEmpty) {
      _showError('Please enter your email');
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final result = await userProvider.forgotPassword(_emailController.text);

    if (!mounted) return;

    if (result != null && (result['success'] as bool? ?? false)) {
      setState(() => _currentStep = 1);
      _showSuccess('OTP sent to your email');
    } else {
      _showError(result?['error'] ?? 'Failed to request OTP');
    }
  }

  void _handleVerifyOtp() async {
    if (_otpController.text.length != 6) {
      _showError('Please enter a valid 6-digit OTP');
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final result = await userProvider.verifyOtp(
      _emailController.text,
      _otpController.text,
    );

    if (!mounted) return;

    if (result != null && result['success'] == true) {
      setState(() => _currentStep = 2);
      _showSuccess('OTP verified! Enter your new password.');
    } else {
      _showError(result?['error'] ?? 'Invalid or expired OTP');
    }
  }

  void _handleResetPassword() async {
    if (_otpController.text.length != 6) {
      _showError('Please enter a valid 6-digit OTP');
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return;
    }
    if (_newPasswordController.text.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final result = await userProvider.resetPassword(
      _emailController.text,
      _otpController.text,
      _newPasswordController.text,
    );

    if (!mounted) return;

    if (result != null && result['success'] == true) {
      _showSuccess('Password reset successfully! Please login.');
      Navigator.pop(context);
    } else {
      _showError(result?['error'] ?? 'Failed to reset password');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  InputDecoration _getInputDecoration(
    BuildContext context,
    String label,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.getAccentColor(theme.brightness)),
      filled: true,
      fillColor: AppColors.getSurfaceColor(theme.brightness),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.getAccentColor(theme.brightness),
          width: 2,
        ),
      ),
      labelStyle: TextStyle(
        color: AppColors.getTextSecondary(theme.brightness),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<UserProvider>(context).isLoading;
    final theme = Theme.of(context);

    // Dynamic title based on step
    String title = 'Forgot Password';
    if (_currentStep == 1) title = 'Verify OTP';
    if (_currentStep == 2) title = 'Reset Password';

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(
            color: AppColors.getTextPrimary(theme.brightness),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.getSurfaceColor(
                theme.brightness,
              ).withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back,
              color: AppColors.getTextPrimary(theme.brightness),
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.getBackground(context).withOpacity(0.9),
                AppColors.getBackground(context).withOpacity(0.0),
              ],
            ),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon illustration
              Container(
                margin: const EdgeInsets.only(bottom: 32),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.getAccentColor(
                    theme.brightness,
                  ).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _currentStep == 0
                      ? Icons.lock_reset
                      : _currentStep == 1
                      ? Icons.phonelink_lock
                      : Icons.password,
                  size: 64,
                  color: AppColors.getAccentColor(theme.brightness),
                ),
              ),

              PremiumCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_currentStep == 0) ...[
                      Text(
                        'Forgot Password?',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextPrimary(theme.brightness),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Enter your registered email address below to receive a 6-digit OTP code.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.getTextSecondary(theme.brightness),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _emailController,
                        style: TextStyle(
                          color: AppColors.getTextPrimary(theme.brightness),
                        ),
                        decoration: _getInputDecoration(
                          context,
                          'Email Address',
                          Icons.email_outlined,
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: isLoading ? null : _handleRequestOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.getAccentColor(
                            theme.brightness,
                          ),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'SEND OTP',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ] else if (_currentStep == 1) ...[
                      Text(
                        'Verification',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextPrimary(theme.brightness),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Enter the 6-digit OTP sent to',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.getTextSecondary(theme.brightness),
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _emailController.text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.getTextPrimary(theme.brightness),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _otpController,
                        decoration: _getInputDecoration(
                          context,
                          'Enter OTP',
                          Icons.lock_clock_outlined,
                        ),
                        style: TextStyle(
                          letterSpacing: 4,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextPrimary(theme.brightness),
                        ),
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () => setState(() => _currentStep = 0),
                        child: Text(
                          'Change Email',
                          style: TextStyle(
                            color: AppColors.getAccentColor(theme.brightness),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: isLoading ? null : _handleVerifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.getAccentColor(
                            theme.brightness,
                          ),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'VERIFY OTP',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ] else ...[
                      Text(
                        'Reset Password',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextPrimary(theme.brightness),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Create a new strong password for your account.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.getTextSecondary(theme.brightness),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _newPasswordController,
                        style: TextStyle(
                          color: AppColors.getTextPrimary(theme.brightness),
                        ),
                        decoration: _getInputDecoration(
                          context,
                          'New Password',
                          Icons.lock_outlined,
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _confirmPasswordController,
                        style: TextStyle(
                          color: AppColors.getTextPrimary(theme.brightness),
                        ),
                        decoration: _getInputDecoration(
                          context,
                          'Confirm Password',
                          Icons.lock_reset_outlined,
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: isLoading ? null : _handleResetPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.getAccentColor(
                            theme.brightness,
                          ),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'RESET PASSWORD',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
