import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'screens/client_list.dart';
import 'screens/add_client.dart';
import 'screens/add_client_male.dart';
import 'screens/add_client_female.dart';
import 'screens/welcome_screen.dart';
import'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
Future <void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prise de mesures - Couturière',
      theme: AppTheme.light(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/clients': (ctx) => const ClientListScreen(),
        '/add': (ctx) => const AddClientScreen(),
        '/add_male': (ctx) => const AddClientMaleScreen(),
        '/add_female': (ctx) => const AddClientFemaleScreen(),
      },
      home: const WelcomeScreen(),
    );
  }
}
