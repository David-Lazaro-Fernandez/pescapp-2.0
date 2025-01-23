import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Method to retrieve all documents from the 'boats' collection
  Future<List<Map<String, dynamic>>> getBoats() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('boats').get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error fetching boats: $e');
      return [];
    }
  }
}
