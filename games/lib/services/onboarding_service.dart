import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  const OnboardingService();

  static const completedKey = 'onboarding_completed';

  Future<bool> isCompleted() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(completedKey) ?? false;
  }

  Future<void> complete() async {
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.setBool(completedKey, true)) {
      throw StateError('Unable to save onboarding completion');
    }
  }
}
