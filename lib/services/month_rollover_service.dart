import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class MonthRolloverService {
  static const String _keyLastCheckDate = 'rollover_last_check_';
  static const String _keyMonths = 'rollover_months_';

  /// Checks if a month rollover is needed for [profileId].
  ///
  /// The endpoint is called at most once per day. The result is cached in
  /// SharedPreferences. Returns `true` when the current month is not yet
  /// present in the summary-months list (i.e. a rollover must be executed).
  Future<bool> checkAndFetchIfNeeded(
      String profileId, ApiService apiService) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final lastCheckKey = '$_keyLastCheckDate$profileId';
    final monthsKey = '$_keyMonths$profileId';

    final lastCheck = prefs.getString(lastCheckKey);

    if (lastCheck == todayStr) {
      // Already checked today — use cached data
      final storedJson = prefs.getString(monthsKey);
      if (storedJson != null) {
        final stored = jsonDecode(storedJson) as List<dynamic>;
        return _isRolloverNeeded(stored);
      }
      return false;
    }

    // First check of the day: fetch from API
    try {
      final months = await apiService.fetchSummaryMonths(profileId);
      await prefs.setString(lastCheckKey, todayStr);
      await prefs.setString(monthsKey, jsonEncode(months));
      return _isRolloverNeeded(months);
    } catch (_) {
      // If the request fails, silently skip — don't block the UI
      return false;
    }
  }

  /// Removes the cached data for [profileId] so the next call to
  /// [checkAndFetchIfNeeded] will re-fetch from the API.
  Future<void> clearCache(String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_keyLastCheckDate$profileId');
    await prefs.remove('$_keyMonths$profileId');
  }

  /// Returns `true` when the current month/year is not present in [months].
  bool _isRolloverNeeded(List<dynamic> months) {
    final now = DateTime.now();
    return !months.any(
      (m) =>
          (m['month'] as num).toInt() == now.month &&
          (m['year'] as num).toInt() == now.year,
    );
  }
}
