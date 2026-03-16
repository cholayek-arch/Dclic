import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00C9A7), Color(0xFF00796B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              final padding = isWide ? 48.0 : 24.0;
              
              return Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white),
                        onPressed: () => Navigator.of(context).pushNamed('/settings'),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: padding, vertical: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: isWide ? 60 : 42,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.cut, size: isWide ? 60 : 40, color: Colors.teal),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Delux',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: isWide ? 48 : 34,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Gestion des clients & mesures',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.white70,
                                    fontSize: isWide ? 20 : 16,
                                  ),
                            ),
                            const SizedBox(height: 48),
                            _buildActionButtons(context, isWide),
                            const SizedBox(height: 24),
                            TextButton(
                              onPressed: () => Navigator.of(context).pushNamed('/clients'),
                              child: Text(
                                'Voir la liste des clients',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: isWide ? 18 : 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isWide) {
    final children = [
      _ActionCard(
        icon: Icons.male,
        label: 'Homme',
        color: Colors.teal,
        onTap: () => Navigator.of(context).pushNamed('/add_male'),
        isWide: isWide,
      ),
      SizedBox(width: isWide ? 24 : 16, height: isWide ? 0 : 16),
      _ActionCard(
        icon: Icons.female,
        label: 'Femme',
        color: Colors.pinkAccent,
        onTap: () => Navigator.of(context).pushNamed('/add_female'),
        isWide: isWide,
      ),
    ];

    if (isWide) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: children,
      );
    } else {
      return Column(
        children: children,
      );
    }
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isWide;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: color,
        padding: EdgeInsets.symmetric(
          vertical: isWide ? 32 : 16,
          horizontal: isWide ? 48 : 20,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
      onPressed: onTap,
      child: Column(
        children: [
          Icon(icon, size: isWide ? 42 : 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: isWide ? 20 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
