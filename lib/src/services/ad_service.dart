import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool _isInitialized = false;

  // Usa IDs de prueba proporcionados por Google para desarrollo.
  // IMPORTANTE: Reemplazar por los IDs reales en producción.
  String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712482630';
    }
    throw UnsupportedError('Plataforma no soportada');
  }

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error inicializando AdMob: $e');
    }
  }

  /// Muestra un anuncio de video recompensado.
  /// Llama a [onEarnedReward] si el usuario completó la visualización.
  /// Si el anuncio falla en cargar, también llamará a [onEarnedReward]
  /// como respaldo (fallback) para no bloquear al usuario por problemas de red.
  void showRewardedAd(Function() onEarnedReward) {
    if (!_isInitialized) {
      // Si el SDK falló, permitimos la acción de todos modos.
      onEarnedReward();
      return;
    }

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          debugPrint('Anuncio recompensado cargado exitosamente.');
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (RewardedAd ad) {
              ad.dispose();
            },
            onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
              debugPrint('Fallo al mostrar el anuncio: $error');
              ad.dispose();
              // Respaldo en caso de fallo
              onEarnedReward();
            },
          );
          
          ad.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
            debugPrint('El usuario ganó la recompensa: ${reward.amount} ${reward.type}');
            onEarnedReward();
          });
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('Fallo al cargar el anuncio recompensado: $error');
          // Respaldo en caso de fallo de red
          onEarnedReward();
        },
      ),
    );
  }
}
