import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/iap_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class PremiumPurchaseScreen extends StatefulWidget {
  const PremiumPurchaseScreen({super.key});

  @override
  State<PremiumPurchaseScreen> createState() => _PremiumPurchaseScreenState();
}

class _PremiumPurchaseScreenState extends State<PremiumPurchaseScreen> {
  final IAPService _iapService = IAPService();
  bool _isLoading = false;
  List<ProductDetails> _products = [];
  String? _selectedId = IAPService.yearlyId;
  StreamSubscription? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _iapService.initialize();
    _loadProducts();
    _statusSubscription = _iapService.purchaseStatuses.listen((success) {
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Félicitations ! Vous êtes maintenant Premium 🎉')),
        );
        Navigator.of(context).pop(true);
      } else if (!success && mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('L\'achat a échoué ou a été annulé.')),
        );
      }
    });
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final products = await _iapService.getSubscriptionProducts();
    if (mounted) {
      setState(() {
        _products = products;
      });
    }
  }

  Future<void> _processPurchase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez vous connecter pour continuer.')),
      );
      Navigator.of(context).pushNamed('/login');
      return;
    }

    if (_selectedId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une offre.')),
      );
      return;
    }

    // Chercher le produit correspondant à l'ID sélectionné
    ProductDetails? product;
    try {
      product = _products.firstWhere((p) => p.id == _selectedId);
    } catch (_) {
      product = null;
    }

    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cette offre n\'est pas encore disponible sur le store. Veuillez configurer le Google Play Console.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _iapService.buySubscription(product);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'achat : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF004D40), Color(0xFF009688), Color(0xFF80CBC4)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              final contentWidth = isWide ? 800.0 : constraints.maxWidth;
              
              return Column(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        width: contentWidth,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              Icon(Icons.stars_rounded, size: isWide ? 100 : 80, color: Colors.amber),
                              const SizedBox(height: 16),
                              Text(
                                'Passez à Delux Premium',
                                style: TextStyle(
                                  fontSize: isWide ? 36 : 28, 
                                  fontWeight: FontWeight.bold, 
                                  color: Colors.white
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Libérez tout le potentiel de votre atelier',
                                style: TextStyle(fontSize: isWide ? 20 : 16, color: Colors.white70),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 48),
                              
                              if (isWide)
                                Wrap(
                                  spacing: 32,
                                  runSpacing: 24,
                                  children: [
                                    SizedBox(width: (contentWidth-80)/2, child: _buildFeature(Icons.cloud_done, 'Sauvegarde Cloud', 'Ne perdez plus jamais les mesures.')),
                                    SizedBox(width: (contentWidth-80)/2, child: _buildFeature(Icons.photo_library, 'Stockage Photo', 'Gardez une trace visuelle.')),
                                    SizedBox(width: (contentWidth-80)/2, child: _buildFeature(Icons.sync_lock, 'Synchro Multi-Appareils', 'Travaillez partout.')),
                                    SizedBox(width: (contentWidth-80)/2, child: _buildFeature(Icons.support_agent, 'Support Prioritaire', 'Nous répondons en priorité.')),
                                  ],
                                )
                              else
                                Column(
                                  children: [
                                    _buildFeature(Icons.cloud_done, 'Sauvegarde Cloud Illimitée', 'Ne perdez plus jamais les mesures de vos clients.'),
                                    _buildFeature(Icons.photo_library, 'Stockage Photo Sécurisé', 'Gardez une trace visuelle de chaque projet.'),
                                    _buildFeature(Icons.sync_lock, 'Synchro Multi-Appareils', 'Travaillez sur tablette ou téléphone indifféremment.'),
                                    _buildFeature(Icons.support_agent, 'Support Prioritaire', 'Nous répondons à vos besoins en priorité.'),
                                  ],
                                ),
                              
                              const SizedBox(height: 40),
                              _buildPricingOptions(isWide),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  _buildBottomAction(isWide),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAction(bool isWide) {
    final selectedProduct = _products.any((p) => p.id == _selectedId) 
        ? _products.firstWhere((p) => p.id == _selectedId) 
        : null;

    String buttonPrice = '';
    if (selectedProduct != null) {
      buttonPrice = selectedProduct.price;
    } else if (_selectedId == IAPService.monthlyId) {
      buttonPrice = '1.000 FCFA';
    } else if (_selectedId == IAPService.yearlyId) {
      buttonPrice = '10.000 FCFA';
    }

    return Container(
      width: isWide ? 500 : double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
              onPressed: _isLoading ? null : _processPurchase,
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    _selectedId != null 
                      ? '1 MOIS GRATUIT - PUIS $buttonPrice'
                      : 'ESSAYER GRATUITEMENT', 
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                  ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '1 mois gratuit, puis abonnement renouvelable. Annulation possible à tout moment.', 
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 11)
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingOptions(bool isWide) {
    final children = [
      _buildPlanCard(
        id: IAPService.monthlyId,
        title: 'Mensuel',
        price: '1.000 FCFA',
        subtitle: '',
        badge: '1 MOIS OFFERT',
      ),
      SizedBox(width: isWide ? 24 : 0, height: isWide ? 0 : 16),
      _buildPlanCard(
        id: IAPService.yearlyId,
        title: 'Annuel',
        price: '10.000 FCFA',
        subtitle: '',
        isBestValue: true,
        badge: '1 MOIS OFFERT',
      ),
    ];

    if (isWide) {
      return Row(
        children: children.map((c) => c is SizedBox ? c : Expanded(child: c)).toList(),
      );
    } else {
      return Column(
        children: children,
      );
    }
  }

  Widget _buildPlanCard({
    required String id,
    required String title,
    required String price,
    required String subtitle,
    String? badge,
    bool isBestValue = false,
  }) {
    // Find the real product if loaded to get the real local price
    final product = _products.any((p) => p.id == id) 
        ? _products.firstWhere((p) => p.id == id) 
        : null;
    
    final displayPrice = product?.price ?? price;
    final isSelected = _selectedId == id;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedId = id);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white10,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.amber : Colors.white30,
            width: 2,
          ),
          boxShadow: isSelected 
              ? [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 4))]
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.teal : Colors.white,
                        ),
                      ),
                      if (isBestValue || badge != null)
                        Text(
                          badge ?? (isBestValue ? 'MEILLEURE OFFRE' : ''),
                          style: TextStyle(
                            fontSize: 12, 
                            fontWeight: FontWeight.w500, 
                            color: isSelected ? Colors.teal.withAlpha(200) : Colors.amberAccent,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected ? Colors.teal.withAlpha(178) : Colors.white70,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              displayPrice,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.teal : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
