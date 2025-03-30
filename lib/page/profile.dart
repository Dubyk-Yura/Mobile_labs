import 'package:flutter/material.dart';
import 'package:mobile_labs/widgets/custom_button.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 80,
              backgroundImage: AssetImage('lib/photo/profile_photo.png'),
            ),
            const SizedBox(height: 10),
            const Text(
              'Dubyk Yurii',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'exampleEmail@gmail.com',
              style: TextStyle(fontSize: 16, color: Color(0xafbdbdbd)),
            ),
            const SizedBox(height: 20),
            CustomButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              text: 'Quit',
              verticalPadding: 0,
            ),
          ],
        ),
      ),
    );
  }
}
