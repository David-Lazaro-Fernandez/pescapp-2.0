import 'package:flutter/material.dart';
import 'package:pescapp/widgets/base_layout.dart';
import 'package:pescapp/services/fish_service.dart';

class FishesScreen extends StatelessWidget {
  final FishService _fishService = FishService();

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      currentIndex: 3, // Fish tab index
      child: SafeArea(
        child: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Peces en la región',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0E0E0E),
                  fontFamily: 'Inter',
                ),
              ),
            ),
            // Fish Grid
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _fishService.getFishesInRegion(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final fishes = snapshot.data ?? [];
                  
                  if (fishes.isEmpty) {
                    return Center(child: Text('No hay peces registrados'));
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: fishes.length,
                    itemBuilder: (context, index) {
                      final fish = fishes[index];
                      return FishCard(
                        name: fish['name'],
                        scientificName: fish['scientificName'],
                        imageUrl: fish['imageUrl'],
                        onTap: () {
                          // Navigate to fish detail screen
                          // Navigator.pushNamed(context, '/fish-detail', arguments: fish);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FishCard extends StatelessWidget {
  final String name;
  final String scientificName;
  final String imageUrl;
  final VoidCallback onTap;

  const FishCard({
    super.key,
    required this.name,
    required this.scientificName,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 120,
                    color: Colors.grey[300],
                    child: Icon(Icons.error),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    scientificName,
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 