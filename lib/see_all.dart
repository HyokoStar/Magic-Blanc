import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class SeeAllPage extends StatefulWidget {
  @override
  _SeeAllPageState createState() => _SeeAllPageState();
}

class _SeeAllPageState extends State<SeeAllPage> {
  final supabase = Supabase.instance.client;
  List<dynamic> cartes = [];
  bool isLoading = true;

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
      isLoading = false;
    });
  }

  // Filtrage des cartes par rareté
  List<dynamic> filterByRarete(String rarete) {
    return cartes.where((carte) => carte['rarete'].toLowerCase() == rarete).toList();
  }

  // Fonction pour obtenir la couleur associée à chaque rareté
  Color getRareteColor(String rarete) {
    switch (rarete.toLowerCase()) {
      case 'légendaire':
        return Colors.amber;
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
        backgroundColor: Colors.purple[300], // Couleur du bandeau
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // Section Légendaire
                _buildCardSection('Légendaire', filterByRarete('légendaire')),
                // Section Mythique
                _buildCardSection('Mythique', filterByRarete('mythique')),
                // Section Epique
                _buildCardSection('Epique', filterByRarete('épique')),
                // Section Rare
                _buildCardSection('Rare', filterByRarete('rare')),
                // Section Commun
                _buildCardSection('Commun', filterByRarete('commun')),
              ],
            ),
    );
  }

  Widget _buildCardSection(String rarete, List<dynamic> cartesParRarete) {
    if (cartesParRarete.isEmpty) {
      return Container(); // Si aucune carte dans cette rareté, ne rien afficher
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bandeau violet avec le texte
          Container(
            padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
            child: Text(
              '$rarete',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: getRareteColor(rarete), // Texte coloré en fonction de la rareté
              ),
            ),
          ),
          SizedBox(height: 10),
          Container(
            height: 200, // La hauteur de chaque section
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: cartesParRarete.length,
              itemBuilder: (context, index) {
                final carte = cartesParRarete[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: GestureDetector(
                    onTap: () {
                      // Ouvrir l'image en plein écran lors du clic
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
                        // Image de la carte
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

// Page pour afficher l'image en plein écran avec zoom et la possibilité de faire défiler
class FullScreenImagePage extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  FullScreenImagePage({required this.imageUrls, required this.initialIndex});

  @override
  _FullScreenImagePageState createState() => _FullScreenImagePageState();
}

class _FullScreenImagePageState extends State<FullScreenImagePage> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.7), // Fond sombre pour la barre
        actions: [
          // Bouton de fermeture (croix) dans la barre supérieure
          IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: () {
              Navigator.pop(context); // Retourner à la page précédente
            },
          ),
        ],
      ),
      body: Center(
        child: PhotoViewGallery.builder(
          itemCount: widget.imageUrls.length,
          builder: (context, index) {
            return PhotoViewGalleryPageOptions(
              imageProvider: NetworkImage(widget.imageUrls[index]),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered,
            );
          },
          scrollPhysics: BouncingScrollPhysics(),
          backgroundDecoration: BoxDecoration(
            color: Colors.black,
          ),
          pageController: _pageController,
          onPageChanged: (index) {
            setState(() {
              // Mettre à jour l'index de la page actuelle si nécessaire
            });
          },
        ),
      ),
    );
  }
}
