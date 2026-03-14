import 'package:flutter/material.dart';
import '../screens/home.dart';
import '../screens/login_page.dart';
import 'theme/app_theme.dart';
import 'screens/client_list.dart';
import 'screens/add_client.dart';
import 'screens/add_client_male.dart';
import 'screens/add_client_female.dart';
import 'screens/welcome_screen.dart';
import'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import'package:firebase_auth/firebase_auth.dart';
import'../services/db_service.dart';

Future <void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,);

    final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
  final clients = await DbService().getClients();

  await FirestoreService().syncClients(clients);
}
  
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
        '/login': (ctx) => LoginPage(),
        '/home': (ctx) => const HomePage(),
      },
      home: const WelcomeScreen(),
    );
  }
}
