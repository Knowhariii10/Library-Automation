import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../home/home_screen.dart';
import 'forgot_password_screen.dart';
import 'guest_qr_screen.dart';
import '../../providers/book_provider.dart';
import '../../providers/rental_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/reservation_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/fine_provider.dart';
import '../../services/sync_service.dart';
import '../../theme/app_colors.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  // State variables (Original Logic Preserved)
  bool isLogin = true;
  bool isStudent = true;
  bool showInitial = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String? _selectedDept;
  String? _selectedYear;

  final List<String> _departments = [
    'CSE',
    'ECE',
    'EEE',
    'CIVIL',
    'MECH',
    'IT',
  ];
  final List<String> _years = ['I', 'II', 'III', 'IV'];

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  final _guestNameController = TextEditingController();
  final _guestEmailController = TextEditingController();
  final _guestPurposeController = TextEditingController();

  // Animation Controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _studentIdController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _guestNameController.dispose();
    _guestEmailController.dispose();
    _guestPurposeController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // --- Original Logic Methods ---

  void _handleLogin() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    final success = await userProvider.login(email, password);

    if (success && mounted) {
      // Trigger initial sync for student
      if (userProvider.isStudent) {
        final bookProvider = Provider.of<BookProvider>(context, listen: false);
        final rentalProvider = Provider.of<RentalProvider>(
          context,
          listen: false,
        );
        final txProvider = Provider.of<TransactionProvider>(
          context,
          listen: false,
        );
        final resProvider = Provider.of<ReservationProvider>(
          context,
          listen: false,
        );
        final notifProvider = Provider.of<NotificationProvider>(
          context,
          listen: false,
        );
        final fineProvider = Provider.of<FineProvider>(context, listen: false);

        // Show a loading indicator during initial sync
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        await SyncService().syncData(
          userProvider,
          bookProvider,
          rentalProvider: rentalProvider,
          txProvider: txProvider,
          resProvider: resProvider,
          notifProvider: notifProvider,
          fineProvider: fineProvider,
        );

        // Generate recommendations immediately for the student
        if (userProvider.user != null) {
          await bookProvider.generateRecommendations(userProvider.user!);
        }

        if (mounted) Navigator.pop(context); // Close loading dialog
      }

      if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed. Check credentials.')),
      );
    }
  }

  void _handleRegister() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _studentIdController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match.')));
      return;
    }

    if (_selectedDept == null || _selectedYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Department and Year.')),
      );
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userData = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
      'student_id': _studentIdController.text.trim(),
      'department': _selectedDept,
      'year': _selectedYear,
      'phone': _phoneController.text.trim(),
    };

    final error = await userProvider.register(userData);

    if (error == null && mounted) {
      // Trigger initial sync
      final bookProvider = Provider.of<BookProvider>(context, listen: false);
      final rentalProvider = Provider.of<RentalProvider>(
        context,
        listen: false,
      );
      final txProvider = Provider.of<TransactionProvider>(
        context,
        listen: false,
      );
      final resProvider = Provider.of<ReservationProvider>(
        context,
        listen: false,
      );
      final notifProvider = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );
      final fineProvider = Provider.of<FineProvider>(context, listen: false);

      // Show a loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await SyncService().syncData(
        userProvider,
        bookProvider,
        rentalProvider: rentalProvider,
        txProvider: txProvider,
        resProvider: resProvider,
        notifProvider: notifProvider,
        fineProvider: fineProvider,
      );

      // Generate recommendations immediately for the student
      if (userProvider.user != null) {
        await bookProvider.generateRecommendations(userProvider.user!);
      }

      if (mounted) Navigator.pop(context); // Close loading dialog

      if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error ?? 'Registration failed.')));
    }
  }

  void _handleGuestRegister() async {
    if (_guestNameController.text.trim().isEmpty ||
        _guestEmailController.text.trim().isEmpty ||
        _guestPurposeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final success = await userProvider.guestRegister(
      _guestNameController.text.trim(),
      _guestEmailController.text.trim(),
      _guestPurposeController.text.trim(),
    );

    if (success && mounted) {
      final user = userProvider.user;
      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GuestQRScreen(
              name: user.name,
              email: user.email,
              purpose: user.purpose,
              userId: user.id,
            ),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Guest registration failed.')),
      );
    }
  }

  // --- UI Build Methods ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: _getCurrentView(),
        ),
      ),
    );
  }

  Widget _getCurrentView() {
    if (showInitial) return _buildInitialView();
    if (isLogin) return _buildLoginView();
    return isStudent
        ? _buildStudentRegistrationView()
        : _buildGuestRegistrationView();
  }

  // Helper for consistent styling
  InputDecoration _buildInputDecoration(String label, IconData icon) {
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
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.getAccentColor(theme.brightness),
          width: 1.5,
        ),
      ),
      labelStyle: TextStyle(
        color: AppColors.getTextSecondary(theme.brightness),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  // Helper for staggered animations
  Widget _buildAnimatedItem(Widget child, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: child,
    );
  }

  Widget _buildInitialView() {
    final theme = Theme.of(context);
    return Center(
      key: const ValueKey('InitialView'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _fadeAnimation,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.getAccentColor(
                    theme.brightness,
                  ).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.library_books,
                  size: 80,
                  color: AppColors.getAccentColor(theme.brightness),
                ),
              ),
            ),
            const SizedBox(height: 32),
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                'Welcome to Library System',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextPrimary(theme.brightness),
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                'Your gateway to knowledge',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.getTextSecondary(theme.brightness),
                ),
              ),
            ),
            const SizedBox(height: 60),

            // Student Button
            _buildAnimatedItem(
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.getAccentColor(theme.brightness),
                    foregroundColor: Colors.black,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      isStudent = true;
                      showInitial = false;
                      isLogin = false;
                    });
                  },
                  child: const Text(
                    'STUDENT ACCESS',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              1,
            ),
            const SizedBox(height: 16),

            // Guest Button
            _buildAnimatedItem(
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppColors.getAccentColor(theme.brightness),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      isStudent = false;
                      showInitial = false;
                      isLogin = false;
                    });
                  },
                  child: Text(
                    'GUEST ACCESS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextPrimary(theme.brightness),
                    ),
                  ),
                ),
              ),
              2,
            ),
            const SizedBox(height: 32),

            // Already have account
            _buildAnimatedItem(
              TextButton(
                onPressed: () {
                  setState(() {
                    showInitial = false;
                    isLogin = true;
                  });
                },
                child: RichText(
                  text: TextSpan(
                    text: 'Already have an account? ',
                    style: TextStyle(
                      color: AppColors.getTextSecondary(theme.brightness),
                    ),
                    children: [
                      TextSpan(
                        text: 'LOGIN',
                        style: TextStyle(
                          color: AppColors.getAccentColor(theme.brightness),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginView() {
    return SingleChildScrollView(
      key: const ValueKey('LoginView'),
      child: Column(
        children: [
          _buildHeader('Welcome Back', 'Sign in to continue'),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildAnimatedItem(
                  TextField(
                    controller: _emailController,
                    decoration: _buildInputDecoration(
                      'Email Address',
                      Icons.email_outlined,
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  0,
                ),
                const SizedBox(height: 16),
                _buildAnimatedItem(
                  TextField(
                    controller: _passwordController,
                    decoration:
                        _buildInputDecoration(
                          'Password',
                          Icons.lock_outline,
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                    obscureText: _obscurePassword,
                  ),
                  1,
                ),
                const SizedBox(height: 24),
                _buildAnimatedItem(
                  Consumer<UserProvider>(
                    builder: (context, userProvider, child) {
                      return userProvider.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.getAccentColor(
                                    Theme.of(context).brightness,
                                  ),
                                  foregroundColor: Colors.black,
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: _handleLogin,
                                child: const Text(
                                  'LOGIN',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                    },
                  ),
                  2,
                ),
                const SizedBox(height: 16),
                _buildAnimatedItem(
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: AppColors.getAccentColor(
                          Theme.of(context).brightness,
                        ),
                      ),
                    ),
                  ),
                  3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentRegistrationView() {
    return SingleChildScrollView(
      key: const ValueKey('StudentRegView'),
      child: Column(
        children: [
          _buildHeader('Student Registration', 'Create your student account'),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                _buildAnimatedItem(
                  TextField(
                    controller: _nameController,
                    decoration: _buildInputDecoration(
                      'Full Name',
                      Icons.person_outline,
                    ),
                  ),
                  0,
                ),
                const SizedBox(height: 16),
                _buildAnimatedItem(
                  TextField(
                    controller: _studentIdController,
                    decoration: _buildInputDecoration(
                      'Student ID',
                      Icons.badge_outlined,
                    ),
                  ),
                  1,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildAnimatedItem(
                        DropdownButtonFormField<String>(
                          decoration: _buildInputDecoration(
                            'Dept',
                            Icons.school_outlined,
                          ),
                          initialValue: _selectedDept,
                          items: _departments.map((dept) {
                            return DropdownMenuItem(
                              value: dept,
                              child: Text(dept),
                            );
                          }).toList(),
                          onChanged: (value) =>
                              setState(() => _selectedDept = value),
                        ),
                        2,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildAnimatedItem(
                        DropdownButtonFormField<String>(
                          decoration: _buildInputDecoration(
                            'Year',
                            Icons.calendar_today_outlined,
                          ),
                          initialValue: _selectedYear,
                          items: _years.map((year) {
                            return DropdownMenuItem(
                              value: year,
                              child: Text(year),
                            );
                          }).toList(),
                          onChanged: (value) =>
                              setState(() => _selectedYear = value),
                        ),
                        3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildAnimatedItem(
                  TextField(
                    controller: _emailController,
                    decoration: _buildInputDecoration(
                      'Email',
                      Icons.email_outlined,
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  4,
                ),
                const SizedBox(height: 16),
                _buildAnimatedItem(
                  TextField(
                    controller: _phoneController,
                    decoration: _buildInputDecoration(
                      'Phone',
                      Icons.phone_outlined,
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  5,
                ),
                const SizedBox(height: 16),
                _buildAnimatedItem(
                  TextField(
                    controller: _passwordController,
                    decoration:
                        _buildInputDecoration(
                          'Password',
                          Icons.lock_outline,
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                    obscureText: _obscurePassword,
                  ),
                  6,
                ),
                const SizedBox(height: 16),
                _buildAnimatedItem(
                  TextField(
                    controller: _confirmPasswordController,
                    decoration:
                        _buildInputDecoration(
                          'Confirm Password',
                          Icons.lock_clock_outlined,
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            ),
                          ),
                        ),
                    obscureText: _obscureConfirmPassword,
                  ),
                  7,
                ),
                const SizedBox(height: 32),
                _buildAnimatedItem(
                  Consumer<UserProvider>(
                    builder: (context, userProvider, child) {
                      return userProvider.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.getAccentColor(
                                    Theme.of(context).brightness,
                                  ),
                                  foregroundColor: Colors.black,
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: _handleRegister,
                                child: const Text(
                                  'REGISTER',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                    },
                  ),
                  8,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestRegistrationView() {
    return SingleChildScrollView(
      key: const ValueKey('GuestRegView'),
      child: Column(
        children: [
          _buildHeader('Guest Registration', 'Visitor access portal'),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                _buildAnimatedItem(
                  TextField(
                    controller: _guestNameController,
                    decoration: _buildInputDecoration(
                      'Full Name',
                      Icons.person_outline,
                    ),
                  ),
                  0,
                ),
                const SizedBox(height: 16),
                _buildAnimatedItem(
                  TextField(
                    controller: _guestEmailController,
                    decoration: _buildInputDecoration(
                      'Email',
                      Icons.email_outlined,
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  1,
                ),
                const SizedBox(height: 16),
                _buildAnimatedItem(
                  TextField(
                    controller: _guestPurposeController,
                    decoration: _buildInputDecoration(
                      'Purpose of Visit',
                      Icons.note_alt_outlined,
                    ),
                  ),
                  2,
                ),
                const SizedBox(height: 32),
                _buildAnimatedItem(
                  Consumer<UserProvider>(
                    builder: (context, userProvider, child) {
                      return userProvider.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.getAccentColor(
                                    Theme.of(context).brightness,
                                  ),
                                  foregroundColor: Colors.black,
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: _handleGuestRegister,
                                child: const Text(
                                  'REGISTER',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                    },
                  ),
                  3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String title, String subtitle) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: AppColors.getAccentColor(theme.brightness),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
            onPressed: () => setState(() => showInitial = true),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
