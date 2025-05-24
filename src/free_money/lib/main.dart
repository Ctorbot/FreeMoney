import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red), 
        scaffoldBackgroundColor: Colors.black, 
        textTheme: const TextTheme(
          headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), // Bolder for clarity
          bodyMedium: TextStyle(color: Colors.white70), // Slightly dim for less harsh contrast
        ),
      ),
      home: const MyHomePage(title: 'Free Money'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Map<String, Object>> _counters = [];
  double _totalPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCounters();
  }

  Future<void> _loadCounters() async {
    final prefs = await SharedPreferences.getInstance();
    final counterData = prefs.getString('counters') ?? '';
    setState(() {
      _counters = counterData.isEmpty
          ? []
          : counterData.split(';').map((entry) {
              final parts = entry.split(',');
              return {
                'name': parts[0],
                'price': double.parse(parts[1]),
                'totalPrice': prefs.getDouble(parts[0]) ?? 0.0,
                'count': prefs.getInt('${parts[0]}_count') ?? 0
              };
            }).toList();
      _updateTotalPrice();
    });
  }

  Future<void> _addCounter(String name, String price) async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _counters.add({
        'name': name,
        'price': double.parse(price) as Object, // Explicitly casting
        'totalPrice': 0.0 as Object,
      });
    });

    final counterData = _counters.map((counter) => '${counter['name']},${counter['price']}').join(';');
    prefs.setString('counters', counterData);
    prefs.setDouble(name, 0.0);

    await _loadCounters();
  }

  Future<bool> _showDeleteConfirmationDialog(String name) async {
    return await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Delete', style: TextStyle(color: Colors.black)),
          content: Text('Are you sure you want to delete "$name"?', style: TextStyle(color: Colors.black)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    ) ?? false; // Default to false if dialog is dismissed
  }

  Future<void> _deleteCounter(String name) async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _counters.removeWhere((counter) => counter['name'] == name);
    });

    // Remove stored counter data
    final counterData = _counters.map((counter) => '${counter['name']},${counter['price']}').join(';');
    prefs.setString('counters', counterData);

    // Remove counter's count and total price
    prefs.remove(name);           // Removes total price
    prefs.remove('${name}_count'); // Removes count

    // Recalculate total price
    _updateTotalPrice();
  }


  Future<void> _incrementCounter(String name, double price) async {
    final prefs = await SharedPreferences.getInstance();
    int currentCount = prefs.getInt('${name}_count') ?? 0;
    double currentTotal = prefs.getDouble(name) ?? 0.0;

    currentCount++;
    currentTotal += price;

    prefs.setInt('${name}_count', currentCount);
    prefs.setDouble(name, currentTotal);

    setState(() {
      _counters.firstWhere((counter) => counter['name'] == name)['count'] = currentCount;
      _counters.firstWhere((counter) => counter['name'] == name)['totalPrice'] = currentTotal;
      _updateTotalPrice();
    });
  }

  Future<void> _decrementCounter(String name, double price) async {
    final prefs = await SharedPreferences.getInstance();
    int currentCount = prefs.getInt('${name}_count') ?? 0;
    double currentTotal = prefs.getDouble(name) ?? 0.0;

    if (currentCount > 0) {
      currentCount--;
      currentTotal -= price;

      prefs.setInt('${name}_count', currentCount);
      prefs.setDouble(name, currentTotal);

      setState(() {
        _counters.firstWhere((counter) => counter['name'] == name)['count'] = currentCount;
        _counters.firstWhere((counter) => counter['name'] == name)['totalPrice'] = currentTotal;
        _updateTotalPrice();
      });
    }
  }



  void _updateTotalPrice() {
    setState(() {
      _totalPrice = _counters.fold(0.0, (sum, counter) => sum + (counter['totalPrice'] as double));
    });
  }

  void _showAddCounterDialog() {
    String name = '';
    String price = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Counter', style: TextStyle(color: Colors.black)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(labelText: 'Name'),
                onChanged: (value) => name = value,
              ),
              TextField(
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                onChanged: (value) => price = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (name.isNotEmpty && price.isNotEmpty) {
                  _addCounter(name, price);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red, // Red banner
        title: Text(widget.title, style: const TextStyle(color: Colors.white)), // Ensure text is visible
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Total Price: \$${_totalPrice.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          Expanded( // Ensures the list takes up remaining space
            child: SingleChildScrollView(
              child: ListView(
                shrinkWrap: true, // Prevents unnecessary height issues
                physics: const NeverScrollableScrollPhysics(), // Avoid double scrolling
                children: _counters.map((counter) {
                  return Dismissible(
                    key: Key(counter['name'] as String),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      return await _showDeleteConfirmationDialog(counter['name'] as String);
                    },
                    onDismissed: (direction) => _deleteCounter(counter['name'] as String),
                    child: ListTile(
                      title: Text(counter['name'] as String, style: TextStyle(color: Colors.white)),
                      subtitle: Text('Price: \$${counter['price']}', style: TextStyle(color: Colors.white70),),
                      trailing: SizedBox(
                        width: 160,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Total: \$${(counter['totalPrice'] as double).toStringAsFixed(2)}', style: TextStyle(color: Colors.white70)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey, width: 2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: SizedBox(
                                    height: 36,
                                    width: 36,
                                    child: IconButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                      icon: const Icon(Icons.remove, size: 18),
                                      onPressed: () => _decrementCounter(counter['name'] as String, counter['price'] as double),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Text('${counter['count'] as int}', style: const TextStyle(fontSize: 16, color: Colors.white70)),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey, width: 2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: SizedBox(
                                    height: 36,
                                    width: 36,
                                    child: IconButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                      icon: const Icon(Icons.add, size: 18),
                                      onPressed: () => _incrementCounter(counter['name'] as String, counter['price'] as double),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCounterDialog,
        tooltip: 'Add Counter',
        child: const Icon(Icons.add),
      ),
    );
  }
}
