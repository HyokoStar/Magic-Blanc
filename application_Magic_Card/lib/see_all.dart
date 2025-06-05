import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

// Page principale affichant toutes les cartes classées par rareté
class SeeAllPage extends StatefulWidget {
  @override
  _SeeAllPageState createState() => _SeeAllPageState();
}

class _SeeAllPageState extends State<SeeAllPage> {
  final supabase = Supabase.instance.client; // Instance Supabase
  List<dynamic> cartes = []; // Liste contenant les cartes récupérées
  bool isLoading = true; // Indique si les données sont en cours de chargement

  @override
  void initState() {
    super.initState();
    fetchCartes(); // Appel de la fonction de récupération des cartes au lancement
  }

  // Fonction pour récupérer les cartes depuis Supabase
  Future<void> fetchCartes() async {
    final response = await supabase.from('carte').select(); // Requête pour sélectionner toutes les cartes
    print('✅ Cartes : $response'); // Affichage dans la console

    if (response.isEmpty) {
      print('⚠️ Aucune carte récupérée !'); // Avertissement si aucune carte n'est trouvée
    }

    // Mise à jour de l'état avec les cartes récupérées
    setState(() {
      cartes = response;
      isLoading = false;
    });
  }

  // Fonction pour filtrer les cartes selon leur rareté
  List<dynamic> filterByRarete(String rarete) {
    return cartes.where((carte) => carte['rarete'].toLowerCase() == rarete).toList();
  }

  // Fonction pour retourner une couleur en fonction de la rareté
  Color getRareteColor(String rarete) {
    switch (rarete.toLowerCase()) {
      case 'légendaire':
        return const Color.fromARGB(255, 255, 174, 0);
      case 'mythique':
        return Colors.red;
      case 'épique':
        return Colors.purple;
      case 'rare':
        return Colors.green;
      case 'commun':
        return Colors.blue;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Livret de cartes'),
        backgroundColor: const Color.fromRGBO(1447, 132, 213, 1), // Couleur personnalisée de l'appbar
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Affiche un loader si en cours de chargement
          : ListView(
              children: [
                // Affichage des cartes pour chaque rareté
                _buildCardSection('Légendaire', filterByRarete('légendaire')),
                _buildCardSection('Mythique', filterByRarete('mythique')),
                _buildCardSection('Épique', filterByRarete('épique')),
                _buildCardSection('Rare', filterByRarete('rare')),
                _buildCardSection('Commun', filterByRarete('commun')),
              ],
            ),
    );
  }

  // Widget qui construit chaque section de cartes par rareté
  Widget _buildCardSection(String rarete, List<dynamic> cartesParRarete) {
    if (cartesParRarete.isEmpty) {
      return Container(); // Ne rien afficher si aucune carte de cette rareté
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre de section avec couleur spécifique
          Container(
            padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
            child: Text(
              '$rarete',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: getRareteColor(rarete), // Couleur dynamique selon la rareté
              ),
            ),
          ),
          SizedBox(height: 10),
          // Liste horizontale des cartes de cette rareté
          Container(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: cartesParRarete.length,
              itemBuilder: (context, index) {
                final carte = cartesParRarete[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: GestureDetector(
                    onTap: () {
                      // Affichage plein écran lors du clic
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FullScreenImagePage(
                            imageUrls: cartesParRarete.map((carte) => carte['image'] as String).toList(),
                            initialIndex: index,
                          ),
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        // Affiche l'image de la carte ou un placeholder en cas d'erreur
                        carte['image'] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  carte['image'],
                                  width: 100,
                                  height: 150,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, _, __) => Icon(Icons.broken_image, size: 80),
                                ),
                              )
                            : Container(
                                width: 100,
                                height: 150,
                                color: Colors.grey[300],
                                child: Icon(Icons.image_not_supported, size: 50),
                              ),
                        SizedBox(height: 5),
                        // Nom de la carte sous l'image
                        Text(
                          carte['nom'] ?? 'Nom indisponible',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Page permettant d'afficher une image en plein écran avec zoom et défilement
class FullScreenImagePage extends StatefulWidget {
  final List<String> imageUrls; // Liste des URLs d'images à afficher
  final int initialIndex; // Index initial de l'image affichée

  FullScreenImagePage({required this.imageUrls, required this.initialIndex});

  @override
  _FullScreenImagePageState createState() => _FullScreenImagePageState();
}

class _FullScreenImagePageState extends State<FullScreenImagePage> {
  late PageController _pageController; // Contrôleur pour faire défiler les images

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex); // Initialisation avec l'image sélectionnée
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.7), // Barre sombre en haut
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: Colors.white), // Bouton pour fermer la page
            onPressed: () {
              Navigator.pop(context); // Retour à la page précédente
            },
          ),
        ],
      ),
      body: Center(
        child: PhotoViewGallery.builder(
          itemCount: widget.imageUrls.length, // Nombre d'images
          builder: (context, index) {
            return PhotoViewGalleryPageOptions(
              imageProvider: NetworkImage(widget.imageUrls[index]), // Fournisseur d'image réseau
              minScale: PhotoViewComputedScale.contained, // Zoom minimum
              maxScale: PhotoViewComputedScale.covered, // Zoom maximum
            );
          },
          scrollPhysics: BouncingScrollPhysics(), // Effet de rebond
          backgroundDecoration: BoxDecoration(color: Colors.black), // Fond noir
          pageController: _pageController, // Contrôleur de page
          onPageChanged: (index) {
            setState(() {
              // Mise à jour de l'index si nécessaire (ex: pour afficher une info sur l'image)
            });
          },
        ),
      ),
    );
  }
}
