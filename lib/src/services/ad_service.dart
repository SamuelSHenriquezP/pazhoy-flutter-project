class AdService {
  AdService._();
  static final AdService instance = AdService._();

  Future<void> init() async {}

  void showRewardedAd(void Function() onEarnedReward) {
    onEarnedReward();
  }
}
