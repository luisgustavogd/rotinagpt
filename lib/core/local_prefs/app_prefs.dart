import 'package:shared_preferences/shared_preferences.dart';

/// Preferências puramente locais e não sensíveis (tema escolhido, última aba
/// aberta). Nunca guardar aqui dado de saúde/rotina — isso vive só no
/// Firestore (ver `data/remote`).
class AppPrefs {
  AppPrefs(this._prefs);

  static Future<AppPrefs> create() async {
    return AppPrefs(await SharedPreferences.getInstance());
  }

  final SharedPreferences _prefs;

  static const _themeModeKey = 'theme_mode';
  static const _lastTabKey = 'last_tab_index';

  String? get themeMode => _prefs.getString(_themeModeKey);

  Future<void> setThemeMode(String mode) =>
      _prefs.setString(_themeModeKey, mode);

  int get lastTabIndex => _prefs.getInt(_lastTabKey) ?? 0;

  Future<void> setLastTabIndex(int index) => _prefs.setInt(_lastTabKey, index);
}
