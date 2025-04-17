import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final bool isValid;
  final Color backgroundColor;
  final Color borderColor;
  final String validationMessage;
  final bool email;
  final String? Function()? getMatchValue;
  final String? mismatchMessage;
  final bool noDigits;
  final String? noDigitsMessage;


  const CustomTextField({
    required this.label,
    required this.controller,
    this.email = false,
    super.key,
    this.obscureText = false,
    this.isValid = true,
    this.backgroundColor = const Color(0xffd9e0fa),
    this.borderColor = const Color(0xffd9e0fa),
    this.validationMessage = 'This field cannot be empty',
    this.getMatchValue,
    this.mismatchMessage,
    this.noDigitsMessage,
    this.noDigits = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: const TextStyle(color: Colors.black),
        filled: true,
        fillColor: backgroundColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Colors.transparent,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: Colors.transparent,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return validationMessage;
        }
        if (email) {
          final RegExp emailRegex = RegExp(
              r"(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'"
              r'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-'
              r'\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*'
              r'[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:(2(5[0-5]|[0-4]'
              r'[0-9])|1[0-9][0-9]|[1-9]?[0-9]))\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9]'
              r'[0-9]|[1-9]?[0-9])|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\'
              r'x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])');
          if (!emailRegex.hasMatch(value)) {
            return 'Please enter a valid email address';
          }
        }
        if (noDigits && RegExp(r'\d').hasMatch(value)) {
          return noDigitsMessage ?? 'This field cannot contain digits';
        }
        if (getMatchValue != null && value != getMatchValue!()) {
          return mismatchMessage ?? 'Values do not match';
        }
        return null;
      },
    );
  }
}
