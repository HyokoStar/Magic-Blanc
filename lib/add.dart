import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class AddCartePage extends StatefulWidget {
  @override
  _AddCartePageState createState() => _AddCartePageState();
}

class _AddCartePageState extends State<AddCartePage> {
  final supabase = Supabase.instance.client;
  final picker = ImagePicker();

  final TextEditingController nomController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController rareteController = TextEditingController();

  Uint8List? _imageBytes;
  String? _imageExtension;

  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageExtension = picked.name.split('.').last;
      });
    }
  }

  Future<String?> _uploadImage(Uint8List bytes, String ext) async {
    try {
      final fileName = "${const Uuid().v4()}.$ext";

      final res = await supabase.storage
          .from('images')
          .uploadBinary(fileName, bytes, fileOptions: FileOptions(contentType: 'image/$ext'));

      if (res.isEmpty) return null;

      final publicUrl = supabase.storage.from('images').getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      print("Erreur upload : $e");
      return null;
    }
  }

  Future<void> _ajouterCarte() async {
    if (_imageBytes == null || _imageExtension == null ||
        nomController.text.isEmpty || descriptionController.text.isEmpty || rareteController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Tous les champs sont requis")));
      return;
    }

    final imageUrl = await _uploadImage(_imageBytes!, _imageExtension!);

    if (imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Échec de l'upload de l'image")));
      return;
    }

    final carte = {
      'nom': nomController.text,
      'description': descriptionController.text,
      'rarete': rareteController.text,
      'image': imageUrl,
    };

    final response = await supabase.from('carte').insert(carte);

    if (response.error == null) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur : ${response.error!.message}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Ajouter une carte"),
        backgroundColor: Colors.purple[300],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nomController,
              decoration: InputDecoration(labelText: 'Nom', border: OutlineInputBorder()),
            ),
            SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
            ),
            SizedBox(height: 16),
            TextField(
              controller: rareteController,
              decoration: InputDecoration(labelText: 'Rareté', border: OutlineInputBorder()),
            ),
            SizedBox(height: 16),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: _imageBytes != null
                    ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                    : Center(child: Text("Clique ici pour choisir une image")),
              ),
            ),
            SizedBox(height: 32),
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
