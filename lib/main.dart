import 'package:flutter/material.dart';
import 'package:mobile_labs/page/home.dart';
import 'package:mobile_labs/page/login.dart';
import 'package:mobile_labs/page/main.dart';
import 'package:mobile_labs/page/profile.dart';
import 'package:mobile_labs/page/register.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Enviroment sensor',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xff111111),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xff111111),
        ),
      ),
      initialRoute: '/login',
      debugShowCheckedModeBanner: false,
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/main': (context) => const MainPage(),
        '/profile': (context) => const ProfilePage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}
