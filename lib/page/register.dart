import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_labs/storage/storage.dart';
import 'package:mobile_labs/storage/storage_impl.dart';
import 'package:mobile_labs/widgets/custom_button.dart';
import 'package:mobile_labs/widgets/custom_text_button.dart';
import 'package:mobile_labs/widgets/custom_textfield.dart';

final Storage localStorage = StorageImpl();

class RegisterState {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController loginController;
  final TextEditingController confirmPasswordController;

  RegisterState({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.loginController,
    required this.confirmPasswordController,
  });
}

class RegisterCubit extends Cubit<RegisterState> {
  RegisterCubit()
      : super(
          RegisterState(
            formKey: GlobalKey<FormState>(),
            emailController: TextEditingController(),
            passwordController: TextEditingController(),
            loginController: TextEditingController(),
            confirmPasswordController: TextEditingController(),
          ),
        );

  Future<void> register(BuildContext context) async {
    if (state.formKey.currentState!.validate()) {
      try {
        await localStorage.registerUser(
          state.emailController.text,
          state.passwordController.text,
          state.loginController.text,
        );
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/main');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e.toString().replaceFirst('Exception: ', ''),
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  Future<void> close() {
    state.emailController.dispose();
    state.passwordController.dispose();
    state.loginController.dispose();
    state.confirmPasswordController.dispose();
    return super.close();
  }
}

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RegisterCubit(),
      child: BlocBuilder<RegisterCubit, RegisterState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: const Text(
                'Register',
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 120),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomTextField(
                        label: 'Email',
                        controller: state.emailController,
                        validationMessage: 'Please enter email',
                        email: true,
                      ),
                      const SizedBox(height: 10),
                      CustomTextField(
                        label: 'Login',
                        controller: state.loginController,
                        validationMessage: 'Please enter login',
                        noDigits: true,
                        noDigitsMessage: 'Login cannot contain numbers',
                      ),
                      const SizedBox(height: 10),
                      CustomTextField(
                        label: 'Password',
                        obscureText: true,
                        controller: state.passwordController,
                      ),
                      const SizedBox(height: 10),
                      CustomTextField(
                        label: 'Confirm Password',
                        obscureText: true,
                        controller: state.confirmPasswordController,
                        validationMessage: 'Please confirm password',
                        getMatchValue: () => state.passwordController.text,
                        mismatchMessage: 'Passwords do not match',
                      ),
                      const SizedBox(height: 20),
                      CustomButton(
                        text: 'Register',
                        onPressed: () =>
                            context.read<RegisterCubit>().register(context),
                      ),
                      const SizedBox(height: 10),
                      CustomTextButton(
                        onPressed: () => Navigator.pushNamed(context, '/login'),
                        text: 'Already have an account? Login',
                        fontSize: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
