import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_labs/page/home_page.dart';
import 'package:mobile_labs/page/profile.dart';

class MainState {
  final int selectedIndex;

  const MainState({
    required this.selectedIndex,
  });

  MainState copyWith({int? selectedIndex}) {
    return MainState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
    );
  }
}

class MainCubit extends Cubit<MainState> {
  MainCubit() : super(const MainState(selectedIndex: 0));

  void onItemTapped(int index) {
    emit(state.copyWith(selectedIndex: index));
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  Widget _getCurrentPage(int index) {
    switch (index) {
      case 0:
        return const HomePage();
      case 1:
        return const ProfilePage();
      default:
        return const HomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MainCubit(),
      child: BlocBuilder<MainCubit, MainState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(),
            body: Column(
              children: [
                Expanded(
                  child: _getCurrentPage(state.selectedIndex),
                ),
                Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: 1,
                  color: const Color(0x68d9e0fa),
                ),
              ],
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: state.selectedIndex,
              onTap: (index) => context.read<MainCubit>().onItemTapped(index),
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
        },
      ),
    );
  }
}
