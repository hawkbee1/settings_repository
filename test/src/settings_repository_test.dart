import 'package:flutter_test/flutter_test.dart';
import 'package:settings_repository/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  group(SettingsRepository, () {
    late SharedPreferencesAsync preferences;
    late SettingsRepository repository;

    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      preferences = SharedPreferencesAsync();
      repository = SettingsRepository(preferences: preferences);
    });

    tearDown(() => repository.dispose());

    group('themeMode', () {
      test('is system by default', () async {
        expect(await repository.themeMode(), AppThemeMode.system);
      });

      test('survives a new repository on the same storage', () async {
        await repository.setThemeMode(AppThemeMode.dark);

        final reopened = SettingsRepository(preferences: preferences);

        expect(await reopened.themeMode(), AppThemeMode.dark);
      });

      test('falls back to system for an unknown stored value', () async {
        await preferences.setString(SettingsRepository.themeModeKey, 'neon');

        expect(await repository.themeMode(), AppThemeMode.system);
      });
    });

    group('touchControls', () {
      test('is auto by default and for an unknown stored value', () async {
        expect(await repository.touchControls(), TouchControlsMode.auto);

        await preferences.setString(SettingsRepository.touchControlsKey, '?');

        expect(await repository.touchControls(), TouchControlsMode.auto);
      });

      test('survives a new repository on the same storage', () async {
        await repository.setTouchControls(TouchControlsMode.never);

        final reopened = SettingsRepository(preferences: preferences);

        expect(await reopened.touchControls(), TouchControlsMode.never);
      });
    });

    group('rules', () {
      test('are the defaults when nothing is stored', () async {
        expect(await repository.rules(), AnalysisRules.defaults());
      });

      test('are stored, watched and reset', () async {
        final changed = AnalysisRules.defaults().copyWith(
          RuleIds.linksImports,
          true,
        );
        final watched = <AnalysisRules>[];
        final subscription = repository.watchRules().listen(watched.add);

        await repository.setRules(changed);
        final stored = await SettingsRepository(preferences: preferences)
            .rules();
        await repository.resetRules();
        await Future<void>.delayed(Duration.zero);

        expect(stored, changed);
        expect(await repository.rules(), AnalysisRules.defaults());
        expect(watched, [changed, AnalysisRules.defaults()]);
        await subscription.cancel();
      });

      test('fall back to the defaults for corrupt stored JSON', () async {
        for (final corrupt in ['{not json', '[1, 2]']) {
          await preferences.setString(SettingsRepository.rulesKey, corrupt);

          expect(await repository.rules(), AnalysisRules.defaults());
        }
      });
    });
  });
}
