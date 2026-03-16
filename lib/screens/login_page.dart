import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';
import 'premium_purchase_screen.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activer Premium')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
          final contentWidth = isWide ? 500.0 : constraints.maxWidth;
          
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
              child: SizedBox(
                width: contentWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars, size: 80, color: Colors.teal),
                    const SizedBox(height: 32),
                    const Text(
                      'Accédez à la puissance du Cloud',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Connectez-vous pour sauvegarder vos clients, vos mesures et vos photos en toute sécurité dans votre espace personnel.',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: Image.asset(
                          'assets/google_g_logo.png',
                          height: 24,
                        ),
                        label: const Text('Continuer avec Google', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          final user = await _authService.signInWithGoogle();
                          if (user != null) {
                            final isPremium = await FirestoreService().isUserPremium(user.uid);
                            if (!isPremium && context.mounted) {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const PremiumPurchaseScreen()),
                              );
                            }
                            if (context.mounted) {
                              Navigator.of(context).pop(true);
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
