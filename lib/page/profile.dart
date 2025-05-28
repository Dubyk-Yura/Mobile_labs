import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_labs/storage/storage.dart';
import 'package:mobile_labs/storage/storage_impl.dart';
import 'package:mobile_labs/widgets/custom_button.dart';

final Storage localStorage = StorageImpl();

class ProfileState {
  final String? userEmail;
  final String? userLogin;

  ProfileState({this.userEmail, this.userLogin});

  ProfileState copyWith({String? userEmail, String? userLogin}) {
    return ProfileState(
      userEmail: userEmail ?? this.userEmail,
      userLogin: userLogin ?? this.userLogin,
    );
  }
}

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit() : super(ProfileState()) {
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final email = await localStorage.getCurrentUserEmail();
    final login = await localStorage.getCurrentUserLogin();
    emit(state.copyWith(userEmail: email, userLogin: login));
  }

  Future<void> logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Quit',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Confirm quit',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Back',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Quit',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (shouldLogout == true) {
      await localStorage.logout();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (_) => false,
        );
      }
    }
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileCubit(),
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
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
                    state.userLogin ?? 'Loading...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    state.userEmail ?? 'Loading...',
                    style:
                        const TextStyle(fontSize: 16, color: Color(0xafbdbdbd)),
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    onPressed: () =>
                        context.read<ProfileCubit>().logout(context),
                    text: 'Quit',
                    verticalPadding: 0,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
