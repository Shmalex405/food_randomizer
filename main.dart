import 'package:flutter/material.dart';
import 'home_page.dart';

void main() {
  runApp(FoodRandomizerApp());
}

class FoodRandomizerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Randomizer',
      theme: ThemeData(
        primaryColor: Colors.orange,
        brightness: Brightness.light,
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.orange,
          textTheme: ButtonTextTheme.primary,
        ),
        textTheme: TextTheme(
          titleLarge: TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.bold,
          ),
          bodyMedium: TextStyle(
            color: Colors.black54,
            fontSize: 16,
          ),
        ),
        appBarTheme: AppBarTheme(
          color: Colors.white,
          iconTheme: IconThemeData(color: Colors.orange),
          titleTextStyle: TextStyle(
            color: Colors.orange,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
      home: HomePage(),
    );
  }
}
