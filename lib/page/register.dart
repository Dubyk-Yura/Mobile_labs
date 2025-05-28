import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_labs/storage/storage.dart';
import 'package:mobile_labs/storage/storage_impl.dart';
import 'package:mobile_labs/widgets/custom_button.dart';
import 'package:mobile_labs/widgets/custom_text_button.dart';
import 'package:mobile_labs/widgets/custom_textfield.dart';

final Storage localStorage = StorageImpl();

class RegisterState {
  final bool isLoading;

  const RegisterState({
    required this.isLoading,
  });

  RegisterState copyWith({bool? isLoading}) {
    return RegisterState(
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class RegisterCubit extends Cubit<RegisterState> {
  RegisterCubit() : super(const RegisterState(isLoading: false));

  Future<void> register(
    BuildContext context,
    String email,
    String password,
    String login,
  ) async {
    emit(state.copyWith(isLoading: true));

    try {
      await localStorage.registerUser(email, password, login);

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
    } finally {
      if (!isClosed) {
        emit(state.copyWith(isLoading: false));
      }
    }
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _loginController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _register(RegisterCubit cubit) {
    if (_formKey.currentState!.validate()) {
      cubit.register(
        context,
        _emailController.text,
        _passwordController.text,
        _loginController.text,
      );
    }
  }

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
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 120),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomTextField(
                        label: 'Email',
                        controller: _emailController,
                        validationMessage: 'Please enter email',
                        email: true,
                      ),
                      const SizedBox(height: 10),
                      CustomTextField(
                        label: 'Login',
                        controller: _loginController,
                        validationMessage: 'Please enter login',
                        noDigits: true,
                        noDigitsMessage: 'Login cannot contain numbers',
                      ),
                      const SizedBox(height: 10),
                      CustomTextField(
                        label: 'Password',
                        obscureText: true,
                        controller: _passwordController,
                      ),
                      const SizedBox(height: 10),
                      CustomTextField(
                        label: 'Confirm Password',
                        obscureText: true,
                        controller: _confirmPasswordController,
                        validationMessage: 'Please confirm password',
                        getMatchValue: () => _passwordController.text,
                        mismatchMessage: 'Passwords do not match',
                      ),
                      const SizedBox(height: 20),
                      CustomButton(
                        text: state.isLoading ? 'Registering...' : 'Register',
                        onPressed: () {
                          if (!state.isLoading) {
                            _register(context.read<RegisterCubit>());
                          }
                        },
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
