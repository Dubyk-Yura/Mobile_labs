import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_labs/page/home.dart';
import 'package:mobile_labs/page/profile.dart';

class MainState {
  final int selectedIndex;
  final List<Widget> pages;

  MainState({
    required this.selectedIndex,
    required this.pages,
  });

  MainState copyWith({int? selectedIndex}) {
    return MainState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
      pages: pages,
    );
  }
}

class MainCubit extends Cubit<MainState> {
  MainCubit()
      : super(
          MainState(
            selectedIndex: 0,
            pages: const [
              HomePage(),
              ProfilePage(),
            ],
          ),
        );

  void onItemTapped(int index) {
    emit(state.copyWith(selectedIndex: index));
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

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
                  child: state.pages[state.selectedIndex],
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
