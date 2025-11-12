// lib/main.dart
import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb; // ⬅️ add kIsWeb
import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'splash_screen.dart';
import 'login_screen.dart';

// ⬇️ Use platform switch instead of importing web file directly
//import 'predict_platform.dart';

/// Light/Dark theme toggle notifier
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.light);

/// Set this to true to bypass your own screens with built-in placeholders while debugging.
const bool usePlaceholders = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Route all framework errors to console (avoid silent blank screens)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  // Catch uncaught async errors (no extra imports needed)
  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    debugPrint('Uncaught async error: $error\n$stack');
    return false; // let Flutter also handle/report it
  };

  String? initError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, st) {
    initError = 'Firebase initialization failed: $e\n$st';
    if (kDebugMode) {
      debugPrint(initError);
    }
  }

  runApp(initError == null ? const MyApp() : ErrorApp(error: initError));
}

/// Simple app shown if Firebase initialization fails
class ErrorApp extends StatelessWidget {
  final String? error;
  const ErrorApp({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        '/predict': (_) => const PredictionDemoPage(), // still allow demo
      },
      home: Scaffold(
        appBar: AppBar(title: const Text('Initialization error')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: SelectableText(
              (error ?? 'Unknown error') +
                  '\n\nCommon causes:\n'
                  '• Wrong/missing firebase_options.dart\n'
                  '• Misconfigured google-services.json / GoogleService-Info.plist\n'
                  '• Service worker / cache serving stale main.dart.js (Web)\n'
                  '• Network/CORS blocking Firebase scripts (Web)\n\n'
                  'Open console/logcat for details.',
              style: const TextStyle(fontFamily: 'monospace', height: 1.35),
            ),
          ),
        ),
      ),
    );
  }
}

/// Root app with theme + auth gate
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'PetBondhuBD',
          themeMode: mode,
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.teal,
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(elevation: 0),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.teal,
            scaffoldBackgroundColor: Colors.black,
            cardColor: Colors.grey[900],
            appBarTheme: const AppBarTheme(backgroundColor: Colors.black, elevation: 0),
          ),

          // ⬇️ NEW: add a route to the prediction demo page
          routes: {
            '/predict': (_) => const PredictionDemoPage(),
          },

          home: const AuthGate(),
        );
      },
    );
  }
}

/// Listens to FirebaseAuth and routes to Splash (logged in) or Login (logged out).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Connecting to auth stream
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _ScaffoldShell(
            title: 'Connecting…',
            child: CircularProgressIndicator(),
          );
        }

        // If the stream throws, show it
        if (snapshot.hasError) {
          return _ScaffoldShell(
            title: 'Auth error',
            child: Text(
              'Auth stream error:\n${snapshot.error}',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          );
        }

        // Logged in
        if (snapshot.hasData) {
          if (usePlaceholders) {
            return const _ScaffoldShell(
              title: 'Logged in',
              child: Text('Rendered: Splash placeholder'),
            );
          }
          return const SplashScreen();
        }

        // Not logged in
        if (usePlaceholders) {
          return const _ScaffoldShell(
            title: 'Not logged in',
            child: Text('Rendered: Login placeholder'),
          );
        }
        return const LoginScreen();
      },
    );
  }
}

/// Small reusable scaffold with theme toggle (and sign out if logged in)
class _ScaffoldShell extends StatelessWidget {
  final String title;
  final Widget child;
  const _ScaffoldShell({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            icon: const Icon(Icons.brightness_6),
            onPressed: () {
              final current = themeModeNotifier.value;
              themeModeNotifier.value =
                  current == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
            },
          ),
          // ⬇️ quick link to the prediction demo
          IconButton(
            tooltip: 'Prediction demo',
            icon: const Icon(Icons.science_outlined),
            onPressed: () {
              Navigator.of(context).pushNamed('/predict');
            },
          ),
          if (user != null)
            IconButton(
              tooltip: 'Sign out',
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
            ),
        ],
      ),
      body: Center(child: child),
    );
  }
}

/// A tiny page to test the JS interop prediction flow.
/// Paste a data URL (`data:image/png;base64,...`) and pick a preprocess mode.
class PredictionDemoPage extends StatefulWidget {
  const PredictionDemoPage({super.key});

  @override
  State<PredictionDemoPage> createState() => _PredictionDemoPageState();
}

class _PredictionDemoPageState extends State<PredictionDemoPage> {
  final _base64Ctrl = TextEditingController();
  String _mode = 'zero_1'; // 'zero_1', 'minus1_1', 'uint8'
  String? _status;
  bool _loading = false;

  Future<void> _run() async {
    final dataUrl = _base64Ctrl.text.trim();
    if (!dataUrl.startsWith('data:image/')) {
      setState(() => _status = 'Please paste a valid data URL like: data:image/png;base64,AAAA...');
      return;
    }

    // ⬇️ Guard: only run on Web (desktop builds don’t have JS interop)
    if (!kIsWeb) {
      setState(() => _status = 'Prediction demo runs on Web only. Try: flutter run -d chrome');
      return;
    }

    setState(() {
      _loading = true;
      _status = 'Running prediction...';
    });

    // try {
    //   // predictWeb comes from predict_platform.dart (web => real, non-web => stub)
    //   //final res = await predictWeb(dataUrl, _mode);
    //   setState(() {
    //     _status =
    //         '✅ ${res['predictedClass']}  (p=${(res['topProb'] as num).toStringAsFixed(4)})\n'
    //         'index=${res['topIndex']}  mode=${res['mode']}';
    //   });
    // } catch (e) {
    //   setState(() => _status = '❌ Error: $e');
    // } finally {
    //   setState(() => _loading = false);
    // }
  }

  @override
  void dispose() {
    _base64Ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Predict (Web Demo)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              'Paste Data URL (data:image/...;base64,...)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _base64Ctrl,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Preprocess mode:'),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _mode,
                  items: const [
                    DropdownMenuItem(value: 'zero_1', child: Text('zero_1 (0..1)')),
                    DropdownMenuItem(value: 'minus1_1', child: Text('-1..1')),
                    DropdownMenuItem(value: 'uint8', child: Text('uint8 (0..255)')),
                  ],
                  onChanged: (v) => setState(() => _mode = v ?? 'zero_1'),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _loading ? null : _run,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Predict'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SelectableText(
              _status ?? 'Status will appear here.',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 32),
            const Text(
              'Note: This demo expects your web/tf_model.js + index.html to be set up and '
              'model assets available under web/web_model/ and labels at web/assets/labels.txt.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
