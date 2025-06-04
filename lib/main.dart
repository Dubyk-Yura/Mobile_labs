import 'package:flutter/material.dart';
import 'package:mobile_labs/page/home_page.dart';
import 'package:mobile_labs/page/login.dart';
import 'package:mobile_labs/page/main.dart';
import 'package:mobile_labs/page/profile.dart';
import 'package:mobile_labs/page/register.dart';
import 'package:mobile_labs/storage/storage.dart';
import 'package:mobile_labs/storage/storage_impl.dart';

final Storage localStorage = StorageImpl();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bool isLoggedIn = await localStorage.isLoggedIn();
  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({required this.isLoggedIn, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Environment Sensor',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xff111111),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xff111111),
        ),
      ),
      initialRoute: isLoggedIn ? '/main' : '/login',
      debugShowCheckedModeBanner: false,
      routes: {
        '/login': (context) {
          return const LoginPage();
        },
        '/register': (context) {
          return const RegisterPage();},
        '/main': (context) => const MainPage(),
        '/profile': (context) => const ProfilePage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}
