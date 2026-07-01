import 'package:flutter/material.dart';
import 'splashscreen.dart';
import 'translation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await T.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: T.languageNotifier,
      builder: (context, lang, child) {
        return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: SplashScreen(),
        );
      },
    );
  }
}