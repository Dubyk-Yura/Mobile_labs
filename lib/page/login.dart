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
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isOffline;

  LoginState({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.isOffline,
  });

  LoginState copyWith({bool? isOffline}) {
    return LoginState(
      formKey: formKey,
      emailController: emailController,
      passwordController: passwordController,
      isOffline: isOffline ?? this.isOffline,
    );
  }
}

class LoginCubit extends Cubit<LoginState> {
  LoginCubit()
      : super(
          LoginState(
            formKey: GlobalKey<FormState>(),
            emailController: TextEditingController(),
            passwordController: TextEditingController(),
            isOffline: false,
          ),
        );

  Future<void> handleLogin(BuildContext context) async {
    final hasConnection = await NetworkMonitor.checkConnection();

    if (!context.mounted) return;

    emit(state.copyWith(isOffline: !hasConnection));

    if (!hasConnection) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No internet connection. Trying offline login...'),
        ),
      );
    }

    try {
      await localStorage.loginUser(
        state.emailController.text,
        state.passwordController.text,
      );

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

  void login(BuildContext context) {
    if (state.formKey.currentState!.validate()) {
      handleLogin(context);
    }
  }

  @override
  Future<void> close() {
    state.emailController.dispose();
    state.passwordController.dispose();
    return super.close();
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

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
                key: state.formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomTextField(
                      label: 'Email',
                      controller: state.emailController,
                      email: true,
                      validationMessage: 'Please enter email',
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      label: 'Password',
                      obscureText: true,
                      controller: state.passwordController,
                      validationMessage: 'Please enter password',
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      text: 'Login',
                      onPressed: () =>
                          context.read<LoginCubit>().login(context),
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
