import 'package:flutter/material.dart';

class InfoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informações'),
        backgroundColor: Colors.blue,
      ),
      body: const Center(
        child: Text('Informações ainda não disponíveis.'),
      ),
    );
  }
}