import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeData get themeData {
    return _isDarkMode
        ? ThemeData.dark().copyWith(
      primaryColor: Colors.green, // Primary color
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: Colors.green.shade100,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: Colors.black, // Dark dialog background
        titleTextStyle: TextStyle(color: Colors.green, fontSize: 20),
      ),
      colorScheme: ColorScheme.dark(
        primary: Colors.green,
        onPrimary: Colors.white,
        surface: Colors.black, // Dark surface (containers)
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.black87, // Dark scaffold background
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white, // AppBar text and icons
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.grey),
        ),
        floatingLabelStyle: TextStyle(color: Colors.green),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: Colors.white), // White text
        bodyMedium: TextStyle(color: Colors.white),
        bodySmall: TextStyle(color: Colors.white),
        headlineLarge: TextStyle(color: Colors.green), // Green heading
        headlineMedium: TextStyle(color: Colors.green),
        headlineSmall: TextStyle(color: Colors.green),
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: Colors.green,
        textTheme: ButtonTextTheme.primary,
      ),
    )
        : ThemeData.light().copyWith(
      primaryColor: Colors.green, // Primary color
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: Colors.green.shade800,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: Colors.white,
        titleTextStyle: TextStyle(color: Colors.green, fontSize: 20),
      ),
      colorScheme: ColorScheme.light(
        primary: Colors.green,
        onPrimary: Colors.white,
        surface: Colors.white, // Light surface (containers)
        onSurface: Colors.black,
      ),
      scaffoldBackgroundColor: Colors.green.shade100, // Light scaffold background
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.green,
        foregroundColor: Colors.black, // AppBar text and icons
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.grey),
        ),
        floatingLabelStyle: TextStyle(color: Colors.green),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: Colors.black), // Black text
        bodyMedium: TextStyle(color: Colors.black),
        bodySmall: TextStyle(color: Colors.black),
        headlineLarge: TextStyle(color: Colors.green), // Green heading
        headlineMedium: TextStyle(color: Colors.green),
        headlineSmall: TextStyle(color: Colors.green),
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: Colors.green,
        textTheme: ButtonTextTheme.primary,
      ),
    );
  }

  void toggleTheme(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
  }
}
