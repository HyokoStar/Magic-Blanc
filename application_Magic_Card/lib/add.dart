// Importation des bibliothèques nécessaires
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

// Déclaration du widget pour la page d'ajout de carte
class AddCartePage extends StatefulWidget {
  @override
  _AddCartePageState createState() => _AddCartePageState();
}

class _AddCartePageState extends State<AddCartePage> {
  final supabase = Supabase.instance.client; // Instance Supabase
  final picker = ImagePicker(); // Utilitaire pour choisir une image depuis la galerie

  // Contrôleurs pour les champs texte
  final TextEditingController nomController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String? selectedRarete; // Valeur sélectionnée dans le menu déroulant

  Uint8List? _imageBytes; // Contenu de l'image sélectionnée
  String? _imageExtension; // Extension du fichier image

  // Fonction pour sélectionner une image dans la galerie
  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageExtension = picked.name.split('.').last; // Récupère l'extension
      });
    }
  }

  // Fonction pour uploader l’image vers Supabase Storage
  Future<String?> _uploadImage(Uint8List bytes, String ext) async {
    try {
      final fileName = "${const Uuid().v4()}.$ext"; // Génère un nom unique
      final res = await supabase.storage
          .from('images')
          .uploadBinary(fileName, bytes, fileOptions: FileOptions(contentType: 'image/$ext'));
      if (res.isEmpty) return null;
      return supabase.storage.from('images').getPublicUrl(fileName); // Retourne l'URL publique
    } catch (e) {
      print("Erreur upload : $e");
      return null;
    }
  }

  // Fonction appelée lorsqu’on appuie sur "Ajouter"
  Future<void> _ajouterCarte() async {
    // Affiche une alerte avant de procéder (même si la suite échoue)
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Carte ajoutée"),
        content: Text("La carte a été ajoutée (ou tentative d'ajout effectuée)."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // Ferme l'alerte
            child: Text("OK"),
          ),
        ],
      ),
    );

    // Vérifie que tous les champs sont remplis
    if (_imageBytes == null || _imageExtension == null ||
        nomController.text.isEmpty || descriptionController.text.isEmpty || selectedRarete == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Tous les champs sont requis")));
      return;
    }

    // Upload l'image
    final imageUrl = await _uploadImage(_imageBytes!, _imageExtension!);
    if (imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Échec de l'upload de l'image")));
      return;
    }

    // Création de la carte à insérer dans la base
    final carte = {
      'nom': nomController.text,
      'description': descriptionController.text,
      'rarete': selectedRarete,
      'image': imageUrl,
    };

    // Envoie les données à Supabase
    final response = await supabase.from('carte').insert(carte);

    // Affiche une erreur si l'insertion a échoué
    if (response.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur : ${response.error!.message}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Ajouter une carte"),
        backgroundColor: const Color.fromRGBO(1447, 132, 213, 1), // Couleur personnalisée du bandeau supérieur
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Champ pour le nom de la carte
            TextField(
              controller: nomController,
              decoration: InputDecoration(labelText: 'Nom', border: OutlineInputBorder()),
            ),
            SizedBox(height: 16),

            // Champ pour la description
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              maxLines: null,
              keyboardType: TextInputType.multiline,
            ),
            SizedBox(height: 16),

            // Menu déroulant pour choisir la rareté
            DropdownButtonFormField<String>(
              value: selectedRarete,
              onChanged: (value) {
                setState(() {
                  selectedRarete = value;
                });
              },
              items: ['commun', 'rare', 'épique', 'mythique', 'légendaire']
                  .map((rarete) => DropdownMenuItem(
                        value: rarete,
                        child: Text(rarete[0].toUpperCase() + rarete.substring(1)), // Capitalise la première lettre
                      ))
                  .toList(),
              decoration: InputDecoration(labelText: 'Rareté', border: OutlineInputBorder()),
            ),
            SizedBox(height: 16),

            // Zone pour afficher et sélectionner une image
            GestureDetector(
              onTap: _pickImage, // Quand on clique, on choisit une image
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: _imageBytes != null
                    ? Image.memory(_imageBytes!, fit: BoxFit.cover) // Affiche l'image sélectionnée
                    : Center(child: Text("Clique ici pour choisir une image")),
              ),
            ),
            SizedBox(height: 32),

            // Bouton pour soumettre la carte
            ElevatedButton(
              onPressed: _ajouterCarte,
              child: Text("Ajouter"),
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
