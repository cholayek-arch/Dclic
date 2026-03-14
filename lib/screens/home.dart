import 'package:flutter/material.dart';


class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp( debugShowCheckedModeBanner: false,
    theme:ThemeData(useMaterial3: true) ,
      home:  Scaffold(
      appBar: AppBar(title: const Text('Accueil')),
      body: const Center(child: Text("Bienvenue Premium\nSynchronisation Cloud active",
          textAlign: TextAlign.center)),
     ) );
  }
}