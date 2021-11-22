import 'package:flutter/material.dart';

final colorScheme = ColorScheme(
  primary: const Color(0xFFFF6B6B),
  primaryVariant: const Color(0xFFFF6B6B),
  secondary: const Color(0xFFFFCAAF),
  secondaryVariant: const Color(0xFFFFCAAF),
  surface: const Color(0xFFCCCCCC),
  background: const Color(0xFFCCCCCC),
  error: Colors.red,
  onPrimary: Colors.white,
  onSecondary: Colors.white,
  onSurface: Colors.black,
  onBackground: Colors.black,
  onError: Colors.black,
  brightness: Brightness.light,
);

final appBarTheme = AppBarTheme(
  color: Colors.transparent,
  elevation: 0.0,
  iconTheme: iconThemeData,
);

final iconThemeData = IconThemeData(
  color: colorScheme.primary,
);

final inputDecorationTheme = InputDecorationTheme(
  hoverColor: colorScheme.primary,
  border: OutlineInputBorder(
    borderSide: BorderSide(color: colorScheme.primary),
  ),
);

final textButtonTheme = TextButtonThemeData(
  style: TextButton.styleFrom(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(4.0)),
    ),
  ),
);

final elevatedButtonTheme = ElevatedButtonThemeData(
  style: ElevatedButton.styleFrom(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(4.0)),
    ),
    elevation: 8.0,
  ),
);

class MainTheme {
  ThemeData get theme => ThemeData(
        colorScheme: colorScheme,
        primaryColor: colorScheme.primary,
        errorColor: colorScheme.error,
        backgroundColor: colorScheme.background,
        brightness: colorScheme.brightness,
        appBarTheme: appBarTheme,
        inputDecorationTheme: inputDecorationTheme,
        iconTheme: iconThemeData,
        textButtonTheme: textButtonTheme,
        elevatedButtonTheme: elevatedButtonTheme,
      );
}
