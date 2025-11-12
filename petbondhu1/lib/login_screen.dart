import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'admin_dashboard_page.dart';
import 'pet_lover/dashboard_home.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  bool isLoading = false;

  // ✅ Fixed admin credentials
  static const String adminEmail = 'admin@gmail.com';
  static const String adminPassword = '123456';

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final email = emailCtrl.text.trim();
    final password = passCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter email and password')),
        );
      } else {
        // ignore: avoid_print
        print('Please enter email and password');
      }
      return;
    }

    setState(() => isLoading = true);

    try {
      // 🟣 Step 1: Check for fixed admin account
      if (email.toLowerCase() == adminEmail && password == adminPassword) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not found')),
          );
        } else {
          // ignore: avoid_print
          print('User not found');
        }
        return;
      }

      // 🟡 Step 3: Check Firestore for user role (optional, fallback to user)
      String role = 'user';
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && doc.data()?['role'] != null) {
          role = doc['role'].toString().toLowerCase();
        }
        else if (!doc.exists) {
          // Create a minimal profile document for this user if allowed by rules.
          try {
            await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
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
            MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => DashboardHome(
                userName: user.email ?? "User",
              ),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      } else {
        // If state unmounted, print for debugging.
        // ignore: avoid_print
        print('Login error (unmounted): $message');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } else {
        // ignore: avoid_print
        print('Login exception (unmounted): $e');
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> forgotPassword() async {
    final email = emailCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter your email to reset password")),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password reset email sent!")),
        );
      } else {
        // ignore: avoid_print
        print('Password reset email sent (unmounted)');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to send reset email")),
        );
      } else {
        // ignore: avoid_print
        print('Failed to send reset email: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.teal],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: Colors.white.withOpacity(0.95),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.pets, size: 70, color: Colors.deepPurple),
                    const SizedBox(height: 24),
                    TextField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        prefixIcon: Icon(Icons.email, color: Colors.deepPurple),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: "Password",
                        prefixIcon: Icon(Icons.lock, color: Colors.deepPurple),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 48, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: login,
                            child: const Text(
                              "Login",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: forgotPassword,
                          child: const Text(
                            "Forgot Password?",
                            style: TextStyle(color: Colors.deepPurple),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RegisterScreen()),
                            );
                          },
                          child: const Text(
                            "Register",
                            style: TextStyle(color: Colors.teal),
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
      ),
    );
  }
}
