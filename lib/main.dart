import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add.dart';
import 'see_all.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation Supabase
  await Supabase.initialize(
    url: 'https://lzpdlqbiluxekjiztrai.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx6cGRscWJpbHV4ZWtqaXp0cmFpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU0MTQ2NjksImV4cCI6MjA2MDk5MDY2OX0.-RjhGtPyBVHu8PjR4cjk0w8CAGX7f7w5pqkQdPl_4ng',
  );

  runApp(MagicCardApp());
}

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
  List<dynamic> cartes = [];
  List<dynamic> filteredCartes = [];
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchCartes();
  }

  Future<void> fetchCartes() async {
    final response = await supabase.from('carte').select();
    print('✅ Cartes : $response');

    if (response.isEmpty) {
      print('⚠️ Aucune carte récupérée !');
    }

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

  void filterCartes(String query) {
    setState(() {
      filteredCartes = cartes
          .where((carte) => (carte['nom'] ?? '')
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    });
  }

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
        return Colors.amber;
      default:
        return Colors.black;
    }
  }

  void modifierCarte(Map<String, dynamic> carte) async {
    TextEditingController nomController = TextEditingController(text: carte['nom']);
    TextEditingController descriptionController = TextEditingController(text: carte['description']);
    TextEditingController rareteController = TextEditingController(text: carte['rarete']);
    TextEditingController imageController = TextEditingController(text: carte['image']);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Modifier la carte'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomController,
                decoration: InputDecoration(labelText: 'Nom'),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: rareteController,
                decoration: InputDecoration(labelText: 'Rareté'),
              ),
              TextField(
                controller: imageController,
                decoration: InputDecoration(labelText: 'URL de l\'image'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedCarte = {
                  'nom': nomController.text,
                  'description': descriptionController.text,
                  'rarete': rareteController.text,
                  'image': imageController.text,
                };

                await supabase
                    .from('carte')
                    .update(updatedCarte)
                    .eq('id', carte['id']);

                Navigator.of(context).pop();
                fetchCartes();
              },
              child: Text('Sauvegarder'),
            ),
          ],
        );
      },
    );
  }

  void supprimerCarte(int id) async {
    bool? confirmation = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmation'),
          content: Text('Voulez-vous vraiment supprimer cette carte ?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('Non'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text('Oui'),
            ),
          ],
        );
      },
    );

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
          // Header
          Container(
            color: Colors.purple[300],
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.cancel, size: 30),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AddCartePage()),
                        );
                      },
                      child: Text('Ajouter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[200],
                      ),
                    ),
                    SizedBox(width: 20),
                    CircleAvatar(
                      child: Icon(Icons.person),
                      backgroundColor: Colors.yellow[300],
                    ),
                    SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SeeAllPage(),
                          ),
                        );
                      },
                      child: Text('Voir'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[200],
                      ),
                    ),
                  ],
                ),
                Icon(Icons.cancel, size: 30),
              ],
            ),
          ),

          // Titre + Image
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                Text(
                  "Magic Card",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amber[300]),
                ),
                SizedBox(height: 10),
                // >>> IMAGE ICI <<< 
                Image.asset(
                  '../assets/image/magic_card.png',
                  height: 200,
                  width: 280,
                  fit: BoxFit.cover,
                ),
              ],
            ),
          ),

          // Texte d'accueil
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(
              "Vous êtes actuellement sur Magic Card !\n"
              "Bienvenue sur votre compte personnel pour gérer vos cartes !\n\n"
              "Collectionnez autant de cartes que vous pouvez !\n",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),

          // Barre de recherche
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
            child: TextField(
              controller: searchController,
              onChanged: filterCartes,
              decoration: InputDecoration(
                hintText: 'Rechercher une carte...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
            ),
          ),

          // Liste des cartes
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : filteredCartes.isEmpty
                    ? Center(child: Text("Aucune carte trouvée"))
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: filteredCartes.length,
                        itemBuilder: (context, index) {
                          final carte = filteredCartes[index];
                          final rarete = carte['rarete'] ?? '';
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.purple[50],
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(12),
                                          bottomLeft: Radius.circular(12),
                                        ),
                                        child: carte['image'] != null
                                            ? Image.network(
                                                carte['image'],
                                                width: 100,
                                                height: 100,
                                                fit: BoxFit.cover,
                                                errorBuilder: (ctx, _, __) => Icon(Icons.broken_image, size: 80),
                                              )
                                            : Container(
                                                width: 100,
                                                height: 100,
                                                color: Colors.grey[300],
                                                child: Icon(Icons.image_not_supported, size: 50),
                                              ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                carte['nom'] ?? '',
                                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                carte['description'] ?? '',
                                                style: TextStyle(fontSize: 14),
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                "Rareté : $rarete",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: getRareteColor(rarete),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit, color: Colors.green),
                                        onPressed: () => modifierCarte(carte),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => supprimerCarte(carte['id']),
                                      ),
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

          // Footer
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text("Nous contacter :", style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
