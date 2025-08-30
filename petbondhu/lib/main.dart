import 'package:flutter/material.dart';
import 'splash_screen.dart';

final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.light);

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

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
          home: const SplashScreen(),
        );
      },
    );
  }
}