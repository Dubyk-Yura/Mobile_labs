import 'package:flutter/material.dart';
import 'package:mobile_labs/widgets/custom_button.dart';
import 'package:mobile_labs/widgets/custom_text_button.dart';
import 'package:mobile_labs/widgets/custom_textfield.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  RegisterPageState createState() => RegisterPageState();
}

class RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomTextField(
                label: 'Email',
                backgroundColor: Colors.grey,
                controller: emailController,
                validationMessage: 'Please enter email',
                email: true,
              ),
              const SizedBox(height: 10),
              CustomTextField(
                label: 'Password',
                obscureText: true,
                backgroundColor: Colors.grey,
                controller: passwordController,
              ),
              const SizedBox(height: 10),
              CustomTextField(
                label: 'Confirm Password',
                obscureText: true,
                backgroundColor: Colors.grey,
                controller: confirmPasswordController,
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: 'Register',
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Registration successful!')),
                    );
                    Navigator.pushReplacementNamed(context, '/main');
                  }
                },
              ),
              const SizedBox(height: 10),
              CustomTextButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                text: 'Already have an account? Login',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
