import 'package:flutter/material.dart';
import 'package:mobile_labs/storage/storage.dart';
import 'package:mobile_labs/storage/storage_impl.dart';
import 'package:mobile_labs/widgets/custom_button.dart';
import 'package:mobile_labs/widgets/custom_text_button.dart';
import 'package:mobile_labs/widgets/custom_textfield.dart';

final Storage localStorage = StorageImpl();

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  RegisterPageState createState() => RegisterPageState();
}

class RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController loginController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
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
                  controller: emailController,
                  validationMessage: 'Please enter email',
                  email: true,
                ),
                const SizedBox(height: 10),
                CustomTextField(
                  label: 'Login',
                  controller: loginController,
                  validationMessage: 'Please enter login',
                  noDigits: true,
                  noDigitsMessage: 'Login cannot contain numbers',
                ),
                const SizedBox(height: 10),
                CustomTextField(
                  label: 'Password',
                  obscureText: true,
                  controller: passwordController,
                ),
                const SizedBox(height: 10),
                CustomTextField(
                  label: 'Confirm Password',
                  obscureText: true,
                  controller: confirmPasswordController,
                  validationMessage: 'Please confirm password',
                  getMatchValue: () => passwordController.text,
                  mismatchMessage: 'Passwords do not match',
                ),
                const SizedBox(height: 20),
                CustomButton(
                  text: 'Register',
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      try {
                        await localStorage.registerUser(
                          emailController.text,
                          passwordController.text,
                          loginController.text,
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
  }
}
