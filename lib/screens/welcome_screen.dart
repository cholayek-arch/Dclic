import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF00C9A7), Color(0xFF00796B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(radius: 42, backgroundColor: Colors.white, child: Icon(Icons.cut, size: 40, color: Colors.teal)),
                  const SizedBox(height: 16),
                  Text('Delux', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('Gestion des clients & mesures', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70)),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.teal, padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () => Navigator.of(context).pushNamed('/add_male'),
                        child: Column(
                          children: const [Icon(Icons.male, size: 28), SizedBox(height: 6), Text('Homme')],
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.pinkAccent, padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () => Navigator.of(context).pushNamed('/add_female'),
                        child: Column(
                          children: const [Icon(Icons.female, size: 28), SizedBox(height: 6), Text('Femme')],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamed('/clients'),
                    child: const Text('Voir la liste des clients', style: TextStyle(color: Colors.white70)),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
