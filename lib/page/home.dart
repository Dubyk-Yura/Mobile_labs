import 'package:flutter/material.dart';
import 'package:mobile_labs/widgets/custom_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Item> items = [];

  void _addItem() {
    setState(() {
      items.add(
        Item(
          title: 'Sensor ${items.length + 1}',
          subItems: List.generate(3, (index) => 'Subitem ${index + 1}'),
        ),
      );
    });
  }

  void _removeItem(int index) {
    setState(() {
      items.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0x88939bae),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  margin: const EdgeInsets.symmetric(
                    vertical: 5,
                    horizontal: 10,
                  ),
                  child: ExpansionTile(
                    title: Text(
                      items[index].title,
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeItem(index),
                    ),
                    children: items[index].subItems.map((subItem) {
                      return ListTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subItem,
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: MediaQuery.of(context).size.width * 0.85,
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: const Center(
                                child: Text(
                                  'Sensor Chart',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                            ),
                            Center(
                              child: Container(
                                margin: const EdgeInsets.only(top: 10),
                                width: MediaQuery.of(context).size.width * 0.85,
                                height: 1,
                                color: const Color(0x68d9e0fa),
                              ),
                            )
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: CustomButton(
              onPressed: _addItem,
              text: 'Add Sensor',
              horizontalPadding: 60,
              verticalPadding: 4,
            ),
          ),
        ],
      ),
    );
  }
}

class Item {
  final String title;
  final List<String> subItems;

  Item({required this.title, required this.subItems});
}
