import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PremiumProvider extends ChangeNotifier {
  static const String _premiumKey = 'is_premium';
  bool _isPremium = false;
  bool _isInitialized = false;

  bool get isPremium => _isPremium;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _isPremium = prefs.getBool(_premiumKey) ?? false;
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading premium status: $e');
    }
  }

  Future<void> purchasePremium() async {
    // Aquí es donde en el futuro integrarás In-App Purchases (RevenueCat / in_app_purchase)
    // Por ahora, simulamos la compra exitosa cambiando el estado localmente.
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_premiumKey, true);
      _isPremium = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving premium status: $e');
    }
  }

  Future<void> resetPremiumForTesting() async {
    // Solo para propósitos de prueba
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_premiumKey, false);
      _isPremium = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error resetting premium status: $e');
    }
  }
}
