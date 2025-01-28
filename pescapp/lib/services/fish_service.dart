import 'package:cloud_firestore/cloud_firestore.dart';

class FishService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getFishesInRegion() async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection('fishes').get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'scientificName': data['scientificName'] ?? '',
          'imageUrl': data['imageUrl'] ?? '',
          'description': data['description'] ?? '',
          'habitat': data['habitat'] ?? '',
          'season': data['season'] ?? '',
        };
      }).toList();
    } catch (e) {
      print('Error fetching fishes: $e');
      return [];
    }
  }
} 