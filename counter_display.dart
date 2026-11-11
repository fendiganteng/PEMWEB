import 'package:flutter/material.dart';

/// Menampilkan nilai counter.
/// Nilai diterima dari parent lewat constructor (passing data).
class CounterDisplay extends StatelessWidget {
  final int counter;

  const CounterDisplay({super.key, required this.counter});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Nilai Counter',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Text(
          '$counter',
          style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}