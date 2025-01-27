import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  TextStyle _textStyle(Color color) {
    return TextStyle(color: color, fontFamily: 'Arial');
  }

  ThemeData get themeData {
    return _isDarkMode
        ? ThemeData.dark().copyWith(
      primaryColor: Colors.green,
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: Colors.green.shade100,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: Colors.black,
        titleTextStyle: TextStyle(color: Colors.green, fontSize: 20),
      ),
      colorScheme: ColorScheme.dark(
        primary: Colors.green,
        onPrimary: Colors.white,
        surface: Colors.black,
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.black87,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
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
        bodyLarge: _textStyle(Colors.white),
        bodyMedium: _textStyle(Colors.white),
        bodySmall: _textStyle(Colors.white),
        headlineLarge: _textStyle(Colors.green),
        headlineMedium: _textStyle(Colors.green),
        headlineSmall: _textStyle(Colors.green),
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: Colors.green,
        textTheme: ButtonTextTheme.primary,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.green,
          textStyle: _textStyle(Colors.green),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.black,
          textStyle: _textStyle(Colors.black),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.green,
          side: BorderSide(color: Colors.green),
          textStyle: _textStyle(Colors.green),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    )
        : ThemeData.light().copyWith(
      primaryColor: Colors.green,
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
        surface: Colors.white,
        onSurface: Colors.black,
      ),
      scaffoldBackgroundColor: Colors.green.shade100,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.green,
        foregroundColor: Colors.black,
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
        bodyLarge: _textStyle(Colors.black),
        bodyMedium: _textStyle(Colors.black),
        bodySmall: _textStyle(Colors.black),
        headlineLarge: _textStyle(Colors.green),
        headlineMedium: _textStyle(Colors.green),
        headlineSmall: _textStyle(Colors.green),
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: Colors.green,
        textTheme: ButtonTextTheme.primary,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.green,
          textStyle: _textStyle(Colors.green),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.black,
          textStyle: _textStyle(Colors.black),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.green,
          side: BorderSide(color: Colors.green),
          textStyle: _textStyle(Colors.green),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }

  void toggleTheme(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
  }
}
