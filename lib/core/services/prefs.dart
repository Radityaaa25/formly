import 'package:shared_preferences/shared_preferences.dart';

import '../../state/app_state.dart';

abstract final class Prefs {
  static const _demoUsedKey = 'demo_used';
  static const _onboardingKey = 'onboarding_done';
  static const _modeKey = 'app_mode';

  static Future<bool> demoUsed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_demoUsedKey) ?? false;
  }

  static Future<void> markDemoUsed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_demoUsedKey, true);
  }

  static Future<bool> onboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  static Future<void> setOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  static Future<void> saveMode(AppMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, mode.name);
  }

  static Future<AppMode?> savedMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_modeKey);
    for (final mode in AppMode.values) {
      if (mode.name == value) return mode;
    }
    return null;
  }
}
