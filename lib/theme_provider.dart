import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  late SharedPreferences _prefs;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }

  void toggleTheme(bool isDarkMode) {
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    _saveTheme(isDarkMode);
  }

  Future<void> _loadTheme() async {
    _prefs = await SharedPreferences.getInstance();
    _themeMode = _prefs.getBool('isDarkMode') ?? false ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> _saveTheme(bool isDarkMode) async {
    await _prefs.setBool('isDarkMode', isDarkMode);
  }

  // Define consistent color schemes for Light and Dark mode
  ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: Colors.green[600],
      scaffoldBackgroundColor: Colors.green[50],
      cardColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.black),
        bodyMedium: TextStyle(color: Colors.black),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.all(Colors.green[600]),
        trackColor: MaterialStateProperty.all(Colors.green[300]),
      ),
    );
  }

  ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.green[700],
      scaffoldBackgroundColor: Colors.grey[900],
      cardColor: Colors.grey[800],
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.all(Colors.green[700]),
        trackColor: MaterialStateProperty.all(Colors.green[500]),
      ),
    );
  }
}
