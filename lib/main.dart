import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // щоб вийти з додатку

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hex Color Input',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ColorInputScreen(),
    );
  }
}

class ColorInputScreen extends StatefulWidget {
  const ColorInputScreen({super.key});

  //на відміну від Stateless віджета в цьому ми можем змінювати стан, функцією setState()
  @override
  _ColorInputScreenState createState() => _ColorInputScreenState();
}

class _ColorInputScreenState extends State<ColorInputScreen> {
  Color backgroundColor = Colors.white; // колір фону на початку
  final TextEditingController _controller = TextEditingController();

  void _updateBackgroundColor() {
    final String input = _controller.text.trim();
    if (input.length == 6 || input.length == 8) {
      try {
        setState(() {
          if (input.length == 6) {
            backgroundColor = Color(
              int.parse('0xFF$input'),
            ); // FF стоїть на початку щоб коли введу 6 символів то означає що колір буде не прозорим (ARGB)
          } else {
            backgroundColor = Color(int.parse('0x$input'));
          } // тут можна задати власну прозорість в перших двох символах
        });
      } catch (e) {
        // Якщо якась помилка парсингу, залишаємо старий колір і видаєм помилку
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Неправильний формат HEX-коду!')));
      }
    } else if (input == '') {
      //якщо користувач просто виходить з поля вводу
    } else {
      showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Помилка'),
            content: const Text('Введений HEX-код неправильний!'),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
          );
        },
      );
    }
    // _controller.clear(); // якщо розкоментувати то буде видаляти введене повідомлення після виведення коліру на фон
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hex Color Input')),
      body: Container(
        color: backgroundColor, // Фон змінюється
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
            ElevatedButton(onPressed: _updateBackgroundColor, child: const Text('Змінити фон')),
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
