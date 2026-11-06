import 'package:flutter/material.dart';

class PreparationScreen extends StatelessWidget {
  const PreparationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Persiapan')),
      body: const Center(child: Text('Persiapan (Vendor, Seserahan, dll)')),
    );
  }
}