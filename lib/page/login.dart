import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_labs/services/network_monitor.dart';
import 'package:mobile_labs/storage/storage.dart';
import 'package:mobile_labs/storage/storage_impl.dart';
import 'package:mobile_labs/widgets/custom_button.dart';
import 'package:mobile_labs/widgets/custom_text_button.dart';
import 'package:mobile_labs/widgets/custom_textfield.dart';

final Storage localStorage = StorageImpl();

class LoginState {
  final bool isOffline;
  final bool isLoading;

  const LoginState({
    required this.isOffline,
    required this.isLoading,
  });

  LoginState copyWith({
    bool? isOffline,
    bool? isLoading,
  }) {
    return LoginState(
      isOffline: isOffline ?? this.isOffline,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class LoginCubit extends Cubit<LoginState> {
  LoginCubit() : super(const LoginState(isOffline: false, isLoading: false));

  Future<void> handleLogin(
    BuildContext context,
    String email,
    String password,
  ) async {
    emit(state.copyWith(isLoading: true));

    final hasConnection = await NetworkMonitor.checkConnection();

    if (!context.mounted) return;

    emit(state.copyWith(isOffline: !hasConnection, isLoading: false));

    if (!hasConnection) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No internet connection. Trying offline login...'),
        ),
      );
    }

    try {
      await localStorage.loginUser(email, password);

      if (!context.mounted) return;

      if (state.isOffline) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offline mode: some features may be unavailable.'),
          ),
        );
      }

      Navigator.pushReplacementNamed(context, '/main');
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${e.toString()}')),
      );
    }
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login(LoginCubit cubit) {
    if (_formKey.currentState!.validate()) {
      cubit.handleLogin(
        context,
        _emailController.text,
        _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginCubit(),
      child: BlocBuilder<LoginCubit, LoginState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: const Text(
                'Login',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomTextField(
                      label: 'Email',
                      controller: _emailController,
                      email: true,
                      validationMessage: 'Please enter email',
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      label: 'Password',
                      obscureText: true,
                      controller: _passwordController,
                      validationMessage: 'Please enter password',
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      text: state.isLoading ? 'Loading...' : 'Login',
                      onPressed: () {
                        if (!state.isLoading) {
                          _login(context.read<LoginCubit>());
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    CustomTextButton(
                      text: 'Register',
                      fontSize: 20,
                      onPressed: () =>
                          Navigator.pushNamed(context, '/register'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
