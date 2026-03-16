import 'package:flutter/material.dart';
import 'dart:developer' as dev;

import '../screens/login_page.dart';
import 'theme/app_theme.dart';
import 'screens/client_list.dart';
import 'screens/add_client_male.dart';
import 'screens/add_client_female.dart';
import 'screens/welcome_screen.dart';
import'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import'package:firebase_auth/firebase_auth.dart';
import'../services/db_service.dart';

import 'screens/splash_screen.dart';
import 'screens/settings_screen.dart';

Future <void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,);

    final user = FirebaseAuth.instance.currentUser;
      
    if (user != null) {
      _startBackgroundSync(user.uid);
    }
  
  runApp(const MyApp());
 
}

void _startBackgroundSync(String userId) async {
  try {
    final db = DbService();
    
    await FirestoreService().pullSync(userId);
    
    final clients = await db.getClients();
    await FirestoreService().pushSync(userId, clients);
  } catch (e) {
    dev.log('Background sync failed', error: e);
  }
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
        '/splash': (ctx) => const SplashScreen(),
        '/clients': (ctx) => const ClientListScreen(),
        '/add_male': (ctx) => const AddClientMaleScreen(),
        '/add_female': (ctx) => const AddClientFemaleScreen(),
        '/login': (ctx) => LoginPage(),
        '/home': (ctx) => const WelcomeScreen(),
        '/settings': (ctx) => const SettingsScreen(),
      },
      home: const SplashScreen(),
    );
  }
}
