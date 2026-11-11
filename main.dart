import 'package:flutter/material.dart';

import 'counter_buttons.dart';
import 'counter_display.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Counter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

/// Halaman awal. Dipakai supaya CounterPage bisa dibuka dan ditutup,
/// sehingga initState() dan dispose() bisa dibuktikan lewat log console.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Beranda')),
      body: Center(
        child: FilledButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CounterPage()),
            );
          },
          child: const Text('Buka Counter'),
        ),
      ),
    );
  }
}

class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    debugPrint('Counter dimulai');
  }

  @override
  void dispose() {
    debugPrint('Counter ditutup');
    super.dispose();
  }

  void _add() {
    setState(() {
      _counter++;
    });
  }

  void _subtract() {
    // Angka tidak boleh minus.
    if (_counter == 0) return;
    setState(() {
      _counter--;
    });
  }

  void _reset() {
    setState(() {
      _counter = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aplikasi Counter')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Passing data: nilai counter dikirim ke child.
            CounterDisplay(counter: _counter),
            const SizedBox(height: 32),
            // Callback: child memanggil fungsi milik parent.
            CounterButtons(
              onAdd: _add,
              onSubtract: _subtract,
              onReset: _reset,
            ),
          ],
        ),
      ),
    );
  }
}