import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:petbondhu1/admin/admin_dashboard_page.dart';
import 'pet_lover/dashboard_home.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool _obscurePassword = true;
  String? errorMsg;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  // ✅ Fixed admin credentials
  static const String adminEmail = 'admin@gmail.com';
  static const String adminPassword = '123456';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    final email = emailCtrl.text.trim();
    final password = passCtrl.text.trim();

    setState(() {
      isLoading = true;
      errorMsg = null;
    });

    try {
      // 🟣 Step 1: Check for fixed admin account
      if (email.toLowerCase() == adminEmail && password == adminPassword) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const AdminDashboardPage(),
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOutCubic,
                    )),
                    child: child,
                  ),
                );
              },
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        }
        return;
      }

      // 🟢 Step 2: Sign in with Firebase
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => errorMsg = 'User not found');
        return;
      }

      // 🟡 Step 3: Check Firestore for user role (optional, fallback to user)
      String role = 'user';
      String userName = user.email ?? "User";
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          if (doc.data()?['role'] != null) {
            role = doc['role'].toString().toLowerCase();
          }
          if (doc.data()?['name'] != null) {
            userName = doc['name'].toString();
          }
        } else {
          // Create a minimal profile document for this user if allowed by rules.
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .set({
              'uid': user.uid,
              'email': user.email ?? '',
              'role': 'user',
              'createdAt': FieldValue.serverTimestamp(),
            });
          } catch (_) {
            // ignore write errors (rules may prevent it)
          }
        }
      } catch (e) {
        // Ignore Firestore errors for normal user login
      }

      // 🟢 Step 4: Redirect based on role
      if (mounted) {
        if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const AdminDashboardPage(),
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 400),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => DashboardHome(userName: userName),
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 400),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email.';
          break;
        case 'wrong-password':
          message = 'Incorrect password.';
          break;
        case 'invalid-email':
          message = 'Invalid email format.';
          break;
        case 'network-request-failed':
          message = 'Network error. Check your internet connection.';
          break;
        default:
          message = e.message ?? 'Login failed.';
      }
      setState(() => errorMsg = message);
    } catch (e) {
      setState(() => errorMsg = 'Error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> forgotPassword() async {
    final email = emailCtrl.text.trim();
    if (email.isEmpty) {
      _showSnackBar("Enter your email to reset password", isError: true);
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        _showSnackBar("Password reset email sent! 📧", isError: false);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("Failed to send reset email", isError: true);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(prefixIcon, color: Colors.deepPurple.shade400),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey.shade50,
      labelStyle: TextStyle(color: Colors.grey.shade600),
      hintStyle: TextStyle(color: Colors.grey.shade400),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red.shade400, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        height: size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade800,
              Colors.deepPurple.shade600,
              Colors.teal.shade400,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Header Section with Animation
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          // Animated Pet Icon with Glow
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 1000),
                            curve: Curves.elasticOut,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.2),
                                        blurRadius: 30,
                                        spreadRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.pets,
                                    size: 70,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                Colors.white,
                                Colors.white.withOpacity(0.8),
                              ],
                            ).createShader(bounds),
                            child: const Text(
                              "Welcome Back!",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Login to continue caring for your pets 🐾",
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Login Form Card
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 40,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Email Field
                            TextFormField(
                              controller: emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: _buildInputDecoration(
                                label: "Email Address",
                                hint: "example@email.com",
                                prefixIcon: Icons.email_outlined,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Please enter your email";
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                    .hasMatch(value)) {
                                  return "Please enter a valid email";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Password Field
                            TextFormField(
                              controller: passCtrl,
                              obscureText: _obscurePassword,
                              decoration: _buildInputDecoration(
                                label: "Password",
                                hint: "Enter your password",
                                prefixIcon: Icons.lock_outline_rounded,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: Colors.grey.shade500,
                                  ),
                                  onPressed: () {
                                    setState(() =>
                                        _obscurePassword = !_obscurePassword);
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Please enter your password";
                                }
                                return null;
                              },
                            ),

                            // Forgot Password
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: forgotPassword,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 8),
                                ),
                                child: Text(
                                  "Forgot Password?",
                                  style: TextStyle(
                                    color: Colors.deepPurple.shade400,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),

                            // Error Message
                            if (errorMsg != null) ...[
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline,
                                        color: Colors.red.shade400, size: 22),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        errorMsg!,
                                        style:
                                            TextStyle(color: Colors.red.shade700),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            const SizedBox(height: 8),

                            // Login Button
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: 58,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      Colors.deepPurple.shade300,
                                  elevation: isLoading ? 0 : 10,
                                  shadowColor:
                                      Colors.deepPurple.withOpacity(0.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        height: 26,
                                        width: 26,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 3,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.login_rounded, size: 24),
                                          SizedBox(width: 12),
                                          Text(
                                            "Login",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),

                            const SizedBox(height: 28),

                            // Divider
                            Row(
                              children: [
                                Expanded(
                                    child: Divider(color: Colors.grey.shade300)),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    "OR",
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(
                                    child: Divider(color: Colors.grey.shade300)),
                              ],
                            ),

                            const SizedBox(height: 28),

                            // Social Login Buttons (Optional UI)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildSocialButton(
                                  icon: Icons.g_mobiledata_rounded,
                                  color: Colors.red,
                                  onTap: () {},
                                ),
                                const SizedBox(width: 20),
                                _buildSocialButton(
                                  icon: Icons.facebook_rounded,
                                  color: Colors.blue.shade700,
                                  onTap: () {},
                                ),
                                const SizedBox(width: 20),
                                _buildSocialButton(
                                  icon: Icons.apple_rounded,
                                  color: Colors.black87,
                                  onTap: () {},
                                ),
                              ],
                            ),

                            const SizedBox(height: 28),

                            // Register Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushReplacement(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (_, __, ___) =>
                                            const RegisterScreen(),
                                        transitionsBuilder:
                                            (_, animation, __, child) {
                                          return SlideTransition(
                                            position: Tween<Offset>(
                                              begin: const Offset(1, 0),
                                              end: Offset.zero,
                                            ).animate(CurvedAnimation(
                                              parent: animation,
                                              curve: Curves.easeInOutCubic,
                                            )),
                                            child: child,
                                          );
                                        },
                                        transitionDuration:
                                            const Duration(milliseconds: 400),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    "Register",
                                    style: TextStyle(
                                      color: Colors.teal,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Footer
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Text(
                        "🐶 Your furry friends await! 🐱",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "PetBondhu - Caring for Pets Together",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }
}
