import 'dart:async';
import 'dart:convert';

import 'package:code_analysis_engine/code_analysis_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app's color theme choice.
enum AppThemeMode {
  /// Follow the device.
  system,

  /// Always light.
  light,

  /// Always dark.
  dark,
}

/// The user's settings: theme mode and engine rules, persisted with
/// `shared_preferences`.
///
/// Corrupt or unknown stored values fall back to the defaults: settings
/// never crash the app.
class SettingsRepository {
  /// Creates the repository over `preferences`.
  new({required this._preferences});

  final SharedPreferencesAsync _preferences;

  /// Storage key of the theme mode.
  static const themeModeKey = 'dc3d.theme_mode';

  /// Storage key of the rules (one JSON object: rule id → value).
  static const rulesKey = 'dc3d.rules';

  final _rulesController = StreamController<AnalysisRules>.broadcast();

  /// The stored theme mode ([AppThemeMode.system] by default).
  Future<AppThemeMode> themeMode() async {
    final stored = await _preferences.getString(themeModeKey);
    return AppThemeMode.values.asNameMap()[stored] ?? AppThemeMode.system;
  }

  /// Stores [mode].
  Future<void> setThemeMode(AppThemeMode mode) =>
      _preferences.setString(themeModeKey, mode.name);

  /// The stored rules (defaults for anything missing or invalid).
  Future<AnalysisRules> rules() async {
    final stored = await _preferences.getString(rulesKey);
    if (stored == null) return AnalysisRules.defaults();
    try {
      final json = jsonDecode(stored);
      return json is Map<String, Object?>
          ? AnalysisRules.fromJson(json)
          : AnalysisRules.defaults();
    } on FormatException {
      return AnalysisRules.defaults();
    }
  }

  /// Stores [rules] and notifies [watchRules] listeners.
  Future<void> setRules(AnalysisRules rules) async {
    await _preferences.setString(rulesKey, jsonEncode(rules.toJson()));
    _rulesController.add(rules);
  }

  /// Restores the default rules.
  Future<void> resetRules() async {
    await _preferences.remove(rulesKey);
    _rulesController.add(AnalysisRules.defaults());
  }

  /// Rules each time they change.
  Stream<AnalysisRules> watchRules() => _rulesController.stream;

  /// Releases the change stream.
  Future<void> dispose() => _rulesController.close();
}
