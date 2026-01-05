import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: "Magazine",
      debugShowCheckedModeBanner: false,
      home: pageAcceuil(),
    );
  }
}

class pageAcceuil extends StatelessWidget {
  const pageAcceuil({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Magazine infos"),
        centerTitle: true,
        backgroundColor: Colors.pink,
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      ),
      body: Center(
        child: Image.asset('assets/images/images.jpg', fit: BoxFit.cover),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print("Tu as cliqué dessus");
        },
        shape: CircleBorder(),
        backgroundColor: Colors.blueAccent,
        child: const Text("Click", style: TextStyle(color: Colors.black26)),
      ),
    );
  }
}
