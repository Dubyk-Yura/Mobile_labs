import 'package:flutter/material.dart';
import 'package:mobile_labs/storage/storage.dart';
import 'package:mobile_labs/storage/storage_impl.dart';
import 'package:mobile_labs/widgets/custom_button.dart';
import 'package:mobile_labs/widgets/custom_text_button.dart';
import 'package:mobile_labs/widgets/custom_textfield.dart';

final Storage localStorage = StorageImpl();

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
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
                controller: emailController,
                email: true,
                validationMessage: 'Please enter email',
              ),
              const SizedBox(height: 10),
              CustomTextField(
                label: 'Password',
                obscureText: true,
                controller: passwordController,
                validationMessage: 'Please enter password',
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: 'Login',
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      await localStorage.loginUser(
                        emailController.text,
                        passwordController.text,
                      );
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/main');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    }
                  }
                },
              ),

              const SizedBox(height: 10),
              CustomTextButton(
                text: 'Register',
                fontSize: 20,
                onPressed: () => Navigator.pushNamed(context, '/register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
