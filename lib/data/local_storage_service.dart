import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/finance_models.dart';

class LocalStorageService {
  // v2 intentionally starts with an empty profile so old demo content is not
  // silently carried into the real planner.
  static const _profileKey = 'financial_profile_v2';

  Future<FinancialProfile?> loadProfile() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(_profileKey);
    if (value == null || value.isEmpty) return null;
    try {
      return FinancialProfile.fromJson(
        Map<String, dynamic>.from(jsonDecode(value) as Map),
      );
    } on Object {
      return null;
    }
  }

  Future<void> saveProfile(FinancialProfile profile) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_profileKey);
  }
}
