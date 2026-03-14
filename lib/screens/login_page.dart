import 'package:flutter/material.dart';
import '../services/auth_service.dart';


class LoginPage extends StatelessWidget{
  LoginPage({super.key});
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Center(
        child: ElevatedButton.icon(
          icon:const Icon(Icons.login),
          label: const Text('Sign in with Google'),
          onPressed: () async {
            final user = await _authService.signInWithGoogle();
            if (user != null) {
              Navigator.pushReplacementNamed(context, '/home');
            }
          },
        ),
      ),
    );
  }
}