import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔌 Initialisation Supabase
  await Supabase.initialize(
    url: 'https://lzpdlqbiluxekjiztrai.supabase.co', // Remplace avec ton URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx6cGRscWJpbHV4ZWtqaXp0cmFpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU0MTQ2NjksImV4cCI6MjA2MDk5MDY2OX0.-RjhGtPyBVHu8PjR4cjk0w8CAGX7f7w5pqkQdPl_4ng',      // Remplace avec ta clé anon
  );

  runApp(MagicBlancApp());
}

class MagicBlancApp extends StatelessWidget {
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
                      onPressed: () {},
                      child: Text('Acheter'),
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
                      onPressed: () {},
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

          // Connexion
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: EdgeInsets.all(10),
              child: ElevatedButton(
                onPressed: () {
                  print(Supabase.instance.client);
                },
                child: Text("Se connecter"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[300],
                ),
              ),
            ),
          ),

          // Logo
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                Text("Magic Blanc", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Placeholder(fallbackHeight: 120),
              ],
            ),
          ),

          // Texte d'accueil
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(
              "Vous êtes bien sur le site du magasin Magic Blanc !\n"
              "Magasin vendant des cartes de toute sorte à bon prix !\n"
              "NUMERO 1 sur le marché des ventes de cartes et d’autres objets !",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),

          // Soldes
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, color: Colors.amber),
              Text("50% Solde", style: TextStyle(color: Colors.red, fontSize: 18)),
            ],
          ),

          SizedBox(height: 20),

          // 🧾 Tableau des cartes
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : cartes.isEmpty
                    ? Center(child: Text("Aucune carte trouvée"))
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('id')),
                            DataColumn(label: Text('nom')),
                            DataColumn(label: Text('description')),
                            DataColumn(label: Text('image')),
                          ],
                          rows: cartes.map((carte) {
                            return DataRow(cells: [
                              DataCell(Text(carte['id'].toString())),
                              DataCell(Text(carte['nom'] ?? '')),
                              DataCell(Text(carte['description'] ?? '')),
                              DataCell(
                                carte['image'] != null
                                    ? Image.network(
                                        carte['image'],
                                        width: 80,
                                        height: 80,
                                        errorBuilder: (ctx, _, __) => Icon(Icons.broken_image),
                                      )
                                    : Icon(Icons.image_not_supported),
                              ),
                            ]);
                          }).toList(),
                        ),
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
