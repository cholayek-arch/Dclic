import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'db_service.dart';
import 'dart:developer' as dev;

class IAPService {
  static final IAPService _instance = IAPService._internal();
  factory IAPService() => _instance;
  IAPService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  
  // Subscription IDs from Google Play Console
  static const String monthlyId = 'delux_premium_monthly';
  static const String yearlyId = 'delux_premium_yearly';

  final _purchaseController = StreamController<bool>.broadcast();
  Stream<bool> get purchaseStatuses => _purchaseController.stream;

  void initialize() {
    final purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen(
      (purchaseList) {
        _listenToPurchaseUpdated(purchaseList);
      },
      onDone: () => _subscription.cancel(),
      onError: (error) => dev.log('IAP Error: $error'),
    );
  }

  void dispose() {
    _subscription.cancel();
    _purchaseController.close();
  }

  Future<List<ProductDetails>> getSubscriptionProducts() async {
    final bool available = await _iap.isAvailable();
    if (!available) return [];

    final ProductDetailsResponse response = await _iap.queryProductDetails({monthlyId, yearlyId});
    if (response.notFoundIDs.isNotEmpty) {
      dev.log('Products not found: ${response.notFoundIDs}');
    }
    return response.productDetails;
  }

  Future<void> buySubscription(ProductDetails productDetails) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
    // On Android, subscriptions use the same buy method if the product is a subscription
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> _listenToPurchaseUpdated(List<PurchaseDetails> purchaseList) async {
    for (var purchase in purchaseList) {
      if (purchase.status == PurchaseStatus.pending) {
        // Show pending UI if needed
      } else if (purchase.status == PurchaseStatus.error) {
        dev.log('Purchase Error: ${purchase.error}');
        _purchaseController.add(false);
      } else if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
        final bool valid = await _verifyPurchase(purchase);
        if (valid) {
          await _deliverProduct(purchase);
        }
      }
      
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    // In a real app, you should verify the purchase on your backend or via Firebase Functions.
    // For now, we will trust the client-side result for this implementation.
    return true; 
  }

  Future<void> _deliverProduct(PurchaseDetails purchase) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      try {
        await FirestoreService().activatePremium(userId);
        _purchaseController.add(true);
      } catch (e) {
        dev.log('Failed to activate premium in Firestore', error: e);
        _purchaseController.add(false);
      }
    }
  }
}
