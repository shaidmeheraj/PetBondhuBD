import 'dart:async';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:firebase_core/firebase_core.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoPulse;
  late final Timer _timer;
  int _tick = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _logoPulse = Tween(begin: 0.9, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // advance progress ticks and navigate after ~2.4s
    _timer = Timer.periodic(const Duration(milliseconds: 400), (t) {
      setState(() => _tick++);
      if (_tick >= 6) {
        t.cancel();
        _goNext();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _goNext() {
    // Always navigate to LoginScreen for now. AuthGate/main will handle logged-in state.
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // determine firebase availability safely
    bool fbAvailable = false;
    try {
      fbAvailable = Firebase.apps.isNotEmpty;
    } catch (_) {
      fbAvailable = false;
    }

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(seconds: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.teal.shade400,
              Colors.orange.shade300,
              Colors.pink.shade300,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _logoPulse,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.pets, size: 64, color: Colors.white),
                        const SizedBox(height: 8),
                        Text('PetBondhu',
                            style: (theme.textTheme.titleLarge ??
                                    const TextStyle(fontSize: 20))
                                .copyWith(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(6, (i) {
                    final on = i <= _tick;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: on ? Colors.white : Colors.white38,
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Text(
                  fbAvailable ? 'Launching...' : 'Offline mode',
                  style: (theme.textTheme.bodyMedium ??
                          const TextStyle(fontSize: 14))
                      .copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
