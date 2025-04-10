import 'package:flutter/material.dart';
import 'package:mobile_labs/page/home.dart';
import 'package:mobile_labs/page/profile.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<MainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const ProfilePage(),
  ];

  void onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          Expanded(
            child: _pages[_selectedIndex],
          ),
          Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: 1,
            color: const Color(0x68d9e0fa),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: onItemTapped,
        selectedItemColor: const Color(0xff697efd),
        unselectedItemColor: Colors.grey,
        backgroundColor: const Color(0xff111111),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
