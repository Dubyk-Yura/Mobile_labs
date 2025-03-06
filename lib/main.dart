import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hex Color Input',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ColorInputScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ColorInputScreen extends StatefulWidget {
  const ColorInputScreen({super.key});

  @override
  ColorInputScreenState createState() => ColorInputScreenState();
}

class ColorInputScreenState extends State<ColorInputScreen> {
  Color backgroundColor = Colors.white;
  final TextEditingController _controller = TextEditingController();

  void _updateBackgroundColor() {
    final String input = _controller.text.trim();
    if (input.length == 6 || input.length == 8) {
      try {
        setState(() {
          if (input.length == 6) {
            backgroundColor = Color(
              int.parse('0xFF$input'),
            );
          } else {
            backgroundColor = Color(int.parse('0x$input'));
          }
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Неправильний формат HEX-коду!')),
        );
      }
    } else if (input == '') {
    } else {
      showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Помилка'),
            content: const Text('Введений HEX-код неправильний!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
    // _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hex Color Input')),
      body: Container(
        color: backgroundColor,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'HEX колір (6 або 8 символів, від 0-9, A-F)',
                labelStyle: TextStyle(color: Colors.black),
                filled: true,
                fillColor: Colors.white,
              ),
              onSubmitted: (value) => _updateBackgroundColor(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _updateBackgroundColor,
              child: const Text('Змінити фон'),
            ),
            const ElevatedButton(
              onPressed: SystemNavigator.pop,
              child: Text('Вийти з додатку'),
            ),
          ],
        ),
      ),
    );
  }
}
