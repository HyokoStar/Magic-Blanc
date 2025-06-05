import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'add.dart';
import 'see_all.dart';

Future<void> main() async {
  // Initialisation de Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation de Supabase
  await Supabase.initialize(
    url: 'https://lzpdlqbiluxekjiztrai.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx6cGRscWJpbHV4ZWtqaXp0cmFpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU0MTQ2NjksImV4cCI6MjA2MDk5MDY2OX0.-RjhGtPyBVHu8PjR4cjk0w8CAGX7f7w5pqkQdPl_4ng',
  );

  // Lancement de l'application
  runApp(MagicCardApp());
}

// Classe principale de l'application
class MagicCardApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MagicHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MagicHomePage extends StatefulWidget {
  @override
  _MagicHomePageState createState() => _MagicHomePageState();
}

class _MagicHomePageState extends State<MagicHomePage> {
  final supabase = Supabase.instance.client;
  List<dynamic> cartes = []; // Liste pour stocker les cartes récupérées
  List<dynamic> filteredCartes = []; // Liste pour stocker les cartes filtrées
  bool isLoading = true; // Indicateur de chargement
  TextEditingController searchController = TextEditingController(); // Contrôleur pour le champ de recherche

  @override
  void initState() {
    super.initState();
    fetchCartes(); // Appel initial pour récupérer les cartes depuis Supabase
  }

  Future<void> fetchCartes() async {
    final response = await supabase.from('carte').select();
    setState(() {
      cartes = response;
      filteredCartes = cartes;

      // Tri des cartes par rareté
      cartes.sort((a, b) {
        final rareteA = a['rarete'].toLowerCase();
        final rareteB = b['rarete'].toLowerCase();
        const raretePriorities = {
          'légendaire': 1,
          'mythique': 2,
          'épique': 3,
          'rare': 4,
          'commun': 5,
        };
        return raretePriorities[rareteA]!.compareTo(raretePriorities[rareteB]!);
      });

      isLoading = false;
    });
  }

  // Fonction pour filtrer les cartes en fonction de la recherche
  void filterCartes(String query) {
    setState(() {
      filteredCartes = cartes
          .where((carte) => (carte['nom'] ?? '')
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    });
  }

  // Fonction pour obtenir la couleur de la rareté
  Color getRareteColor(String rarete) {
    switch (rarete.toLowerCase()) {
      case 'commun':
        return Colors.blue;
      case 'rare':
        return Colors.green;
      case 'épique':
        return Colors.purple;
      case 'mythique':
        return Colors.red;
      case 'légendaire':
        return const Color.fromARGB(255, 255, 174, 0);
      default:
        return Colors.black;
    }
  }

  // Fonction pour obtenir l'URL publique de l'image
  String? getPublicImageUrl(String? fileName) {
    if (fileName == null || fileName.isEmpty) return null;
    if (fileName.startsWith('http://') || fileName.startsWith('https://')) {
      return fileName;
    }
    return "https://lzpdlqbiluxekjiztrai.supabase.co/storage/v1/object/public/images/$fileName";
  }

  // Fonction pour modifier une carte
  void modifierCarte(Map<String, dynamic> carte) async {
    final picker = ImagePicker();
    Uint8List? newImageBytes;
    String? newImageExtension;

    // Initialisation des contrôleurs de texte avec les valeurs actuelles de la carte
    TextEditingController nomController = TextEditingController(text: carte['nom']);
    TextEditingController descriptionController = TextEditingController(text: carte['description']);
    TextEditingController rareteController = TextEditingController(text: carte['rarete']);

    // Fonction pour choisir une nouvelle image
    Future<void> _pickNewImage() async {
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        newImageBytes = await picked.readAsBytes();
        newImageExtension = picked.name.split('.').last;
      }
    }

    // Affichage du dialogue de modification de la carte
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Modifier la carte'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nomController, decoration: InputDecoration(labelText: 'Nom')),
                    TextField(
                      controller: descriptionController, 
                      decoration: InputDecoration(labelText: 'Description'),
                      maxLines: null,  // Permet d'avoir un champ de texte dynamique
                      keyboardType: TextInputType.multiline,  // Permet d'écrire sur plusieurs lignes
                    ),
                    TextField(controller: rareteController, decoration: InputDecoration(labelText: 'Rareté')),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
                        await _pickNewImage();
                        setState(() {});
                      },
                      child: Text('Changer l\'image'),
                    ),
                    SizedBox(height: 10),
                    // Affichage de l'image actuelle ou de la nouvelle image choisie
                    newImageBytes != null
                        ? Image.memory(newImageBytes!, height: 100)
                        : carte['image'] != null
                            ? Image.network(getPublicImageUrl(carte['image'])!, height: 100)
                            : Container(),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Annuler')),
                ElevatedButton(
                  onPressed: () async {
                    String? newImageUrl = carte['image'];

                    // Si une nouvelle image a été choisie, on l'upload
                    if (newImageBytes != null && newImageExtension != null) {
                      final fileName = "${Uuid().v4()}.$newImageExtension";
                      await supabase.storage
                          .from('images')
                          .uploadBinary(fileName, newImageBytes!, fileOptions: FileOptions(contentType: 'image/$newImageExtension'));
                      newImageUrl = fileName;
                    }

                    // Mise à jour de la carte avec les nouvelles valeurs
                    final updatedCarte = {
                      'nom': nomController.text,
                      'description': descriptionController.text,
                      'rarete': rareteController.text,
                      'image': newImageUrl,
                    };

                    await supabase.from('carte').update(updatedCarte).eq('id', carte['id']);
                    Navigator.of(context).pop();
                    fetchCartes(); // Rafraîchissement de la liste des cartes
                  },
                  child: Text('Sauvegarder'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Fonction pour supprimer une carte
  void supprimerCarte(int id) async {
    bool? confirmation = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmation'),
          content: Text('Voulez-vous vraiment supprimer cette carte ?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Non')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text('Oui')),
          ],
        );
      },
    );

    // Si l'utilisateur confirme la suppression, on supprime la carte
    if (confirmation == true) {
      await supabase.from('carte').delete().eq('id', id);
      fetchCartes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // En-tête de l'application
          Container(
            color: const Color.fromRGBO(1447, 132, 213, 1),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.cancel, size: 30, color: const Color.fromARGB(255, 207, 207, 207),),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AddCartePage()),
                        );
                      },
                      child: Text('Ajouter', style: TextStyle(color: const Color.fromARGB(255, 138, 96, 5))),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color.fromRGBO(251, 231, 126, 1)),
                    ),
                    SizedBox(width: 20),
                    CircleAvatar(child: Icon(Icons.person, color: const Color.fromARGB(255, 17, 114, 114),), backgroundColor: const Color.fromRGBO(46, 203, 204, 1)),
                    SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SeeAllPage()),
                        );
                      },
                      child: Text('Voir', style: TextStyle(color: const Color.fromARGB(255, 138, 96, 5))),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color.fromRGBO(251, 231, 126, 1)),
                    ),
                  ],
                ),
                Icon(Icons.cancel, size: 30, color: const Color.fromARGB(255, 207, 207, 207),),
              ],
            ),
          ),
          // Contenu principal de la page
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                Text("Magic Card", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: const Color.fromARGB(255, 255, 174, 0))),
                SizedBox(height: 10),
                Image.asset('../assets/image/magic_card.png', height: 200, width: 280, fit: BoxFit.cover),
              ],
            ),
          ),
          // Message de bienvenue
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(
              "Vous êtes actuellement sur Magic Card !\nBienvenue sur votre compte personnel pour gérer vos cartes !",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
          // Champ de recherche pour filtrer les cartes
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
            child: TextField(
              controller: searchController,
              onChanged: filterCartes,
              decoration: InputDecoration(
                hintText: 'Rechercher une carte...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          // Liste des cartes
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator()) // Affichage d'un indicateur de chargement pendant la récupération des cartes
                : filteredCartes.isEmpty
                    ? Center(child: Text("Aucune carte trouvée"))
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: filteredCartes.length,
                        itemBuilder: (context, index) {
                          final carte = filteredCartes[index];
                          final rarete = carte['rarete'] ?? '';
                          final imageUrl = getPublicImageUrl(carte['image']);

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(104, 215, 202, 233),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  // Affichage de l'image, du nom, de la description et de la rareté de la carte
                                  Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(12),
                                          bottomLeft: Radius.circular(12),
                                        ),
                                        child: imageUrl == null
                                            ? Container(
                                                width: 100,
                                                height: 100,
                                                color: Colors.grey[300],
                                                child: Icon(Icons.broken_image, size: 50),
                                              )
                                            : Image.network(
                                                imageUrl,
                                                width: 100,
                                                height: 100,
                                                fit: BoxFit.cover,
                                              ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(carte['nom'] ?? '', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                              SizedBox(height: 8),
                                              Text(carte['description'] ?? '', style: TextStyle(fontSize: 14)),
                                              SizedBox(height: 8),
                                              Text("Rareté : $rarete", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: getRareteColor(rarete))),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Boutons pour modifier et supprimer la carte
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(icon: Icon(Icons.edit, color: const Color.fromRGBO(46, 203, 204, 1)), onPressed: () => modifierCarte(carte)),
                                      IconButton(icon: Icon(Icons.delete, color: const Color.fromARGB(255, 204, 46, 46)), onPressed: () => supprimerCarte(carte['id'])),
                                      SizedBox(width: 10),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          // Section de contact
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text("Nous contacter :", style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}