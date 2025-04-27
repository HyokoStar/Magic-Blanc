import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddCartePage extends StatefulWidget {
  @override
  _AddCartePageState createState() => _AddCartePageState();
}

class _AddCartePageState extends State<AddCartePage> {
  final supabase = Supabase.instance.client;
  final TextEditingController nomController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController rareteController = TextEditingController();
  final TextEditingController imageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Ajouter une carte"),
        backgroundColor: Colors.purple[300],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nomController,
              decoration: InputDecoration(
                labelText: 'Nom',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: rareteController,
              decoration: InputDecoration(
                labelText: 'Rareté',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: imageController,
              decoration: InputDecoration(
                labelText: 'URL de l\'image',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                final newCarte = {
                  'nom': nomController.text,
                  'description': descriptionController.text,
                  'rarete': rareteController.text,
                  'image': imageController.text,
                };

                // Ajout de la carte à la base de données
                final response = await supabase.from('carte').insert(newCarte);

                if (response.error == null) {
                  Navigator.pop(context); // Retour à la page principale après l'ajout
                } else {
                  print("Erreur lors de l'ajout de la carte : ${response.error?.message}");
                }
              },
              child: Text('Ajouter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[300],
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
