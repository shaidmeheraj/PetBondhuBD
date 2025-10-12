import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:petbondhu1/login_screen.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.light);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase.
  // On web we must pass the options from `firebase_options.dart`.
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    // On Android/iOS the native google-services.json / GoogleService-Info.plist
    // provide the configuration, so call initializeApp() without options.
    await Firebase.initializeApp();
  }
  runApp(MyApp());
}

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
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.teal,
            scaffoldBackgroundColor: Colors.white,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.teal,
            scaffoldBackgroundColor: Colors.black,
            cardColor: Colors.grey[900],
            appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
          ),
          themeMode: mode,
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasData) {
                // User is logged in
                return const SplashScreen(); // Or your main app/home page
              } else {
                // Not logged in
                // return const LoginScreen();
                return const LoginScreen();
              }
            },
          ),
        );
      },
    );
  }
}