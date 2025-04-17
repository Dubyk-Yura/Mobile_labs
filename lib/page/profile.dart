import 'package:flutter/material.dart';
import 'package:mobile_labs/storage/storage.dart';
import 'package:mobile_labs/storage/storage_impl.dart';
import 'package:mobile_labs/widgets/custom_button.dart';

final Storage localStorage = StorageImpl();

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _userEmail;
  String? _userLogin;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final email = await localStorage.getCurrentUserEmail();
    final login = await localStorage.getCurrentUserLogin();
    setState(() {
      _userEmail = email;
      _userLogin = login;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 80,
              backgroundImage: AssetImage('lib/photo/profile_photo.png'),
            ),
            const SizedBox(height: 10),
            Text(
              _userLogin ?? 'Loading...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _userEmail ?? 'Loading...',
              style: const TextStyle(fontSize: 16, color: Color(0xafbdbdbd)),
            ),
            const SizedBox(height: 20),
            CustomButton(
              onPressed: () async {
                await localStorage.logout();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                        (_) => false,
                  );
                }
              },
              text: 'Quit',
              verticalPadding: 0,
            ),
          ],
        ),
      ),
    );
  }
}
