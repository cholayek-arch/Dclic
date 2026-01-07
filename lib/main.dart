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
      home: PageAcceuil(),
    );
  }
}

class PageAcceuil extends StatelessWidget {
  const PageAcceuil({super.key});

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

      body: const Column(
        children: [
          Image(image: AssetImage('assets/images/magazineInfo.jpg')),
          PartieTitre(),
          PartieText(),
          PartieIcone(),
          PartieRubrique(),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print("Tu as cliqué dessus");
        },
        shape: CircleBorder(),
        backgroundColor: Colors.white60,
        child: const Text("Click", style: TextStyle(color: Colors.black)),
      ),
    );
  }
}

class PartieTitre extends StatelessWidget {
  const PartieTitre({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Bienvenu au Magazine infos",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.red,
              fontFamily: 'Magical',
            ),
            textAlign: TextAlign.left,
          ),
          Text(
            "Votre Magazine numérique, qui vous tient informé 24/24.",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.lightBlue,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }
}

class PartieText extends StatelessWidget {
  const PartieText({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: const Text(
        "Le Magazine infos est une plateforme numérique dédiée à la diffusion d'informations, d'analyses et de contenus variés. Notre mission est de fournir à nos lecteurs des articles de qualité couvrant un large éventail de sujets.",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          color: Colors.orange,
          fontFamily: 'Cracker',
        ),
      ),
    );
  }
}

class PartieIcone extends StatelessWidget {
  const PartieIcone({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.phone, color: Colors.pink),
                SizedBox(height: 5),
                Text(
                  'Tel'.toUpperCase(),
                  style: const TextStyle(color: Colors.pink),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.mail, color: Colors.pink),
                SizedBox(height: 5),
                Text(
                  'Mail'.toUpperCase(),
                  style: const TextStyle(color: Colors.pink),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.share, color: Colors.pink),
                SizedBox(height: 5),
                Text(
                  'Share'.toUpperCase(),
                  style: const TextStyle(color: Colors.pink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PartieRubrique extends StatelessWidget {
  const PartieRubrique({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ClipRRect(
            borderRadius: BorderRadiusGeometry.circular(8),
            child: const Image(image: AssetImage('assets/images/design.jpg')),
          ),
          ClipRRect(
            borderRadius: BorderRadiusGeometry.circular(8),
            child: const Image(image: AssetImage('assets/images/presse.jpg')),
          ),
        ],
      ),
    );
  }
}
