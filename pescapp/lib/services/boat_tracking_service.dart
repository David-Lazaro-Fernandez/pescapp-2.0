import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:pescapp/services/local_storage_service.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class BoatTrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalStorageService _localStorage = LocalStorageService();
  final Connectivity _connectivity = Connectivity();
  int? _currentTravelId;
  bool _isTracking = false;
  Timer? _recordingTimer;
  static const int _recordingInterval = 5 * 60; // 5 minutes in seconds

  // Initialize a new travel
  Future<void> startTravel() async {
    try {
      _currentTravelId = DateTime.now().millisecondsSinceEpoch;
      
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        await _firestore.collection('travels').add({
          'timestamp': FieldValue.serverTimestamp(),
          'travel_id': _currentTravelId,
        });
      }
 
      _isTracking = true;
      _startPeriodicRecording();
    } catch (e) {
      print('Error starting travel: $e');
      throw Exception('Failed to start travel');
    }
  }

  void _startPeriodicRecording() {
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(Duration(seconds: _recordingInterval), (timer) async {
      // Get current position and record it
      // You'll need to implement position getting logic here
      // For example, using geolocator package:
      try {
        Position position = await Geolocator.getCurrentPosition();
        await recordCoordinates(position.latitude, position.longitude);
      } catch (e) {
        print('Error recording periodic coordinates: $e');
      }
    });
  }

  // Record coordinates during travel
  Future<void> recordCoordinates(double latitude, double longitude) async {
    if (!_isTracking || _currentTravelId == null) {
      throw Exception('No active travel to record coordinates');
    }

    try {
      // Save coordinates locally first
      await _localStorage.saveCoordinates(_currentTravelId!, latitude, longitude);

      // Check connectivity and sync if possible
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        await _syncPendingCoordinates();
      }
    } catch (e) {
      print('Error recording coordinates: $e');
      // Don't throw exception here as coordinates are saved locally
    }
  }

  // Sync pending coordinates
  Future<void> _syncPendingCoordinates() async {
    try {
      final pendingCoordinates = await _localStorage.getPendingCoordinates();
      final syncedIds = <int>[];

      for (final coord in pendingCoordinates) {
        await _firestore.collection('coords').add({
          'coords': {
            'lat': coord['latitude'],
            'lon': coord['longitude'],
          },
          'timestamp': coord['timestamp'],
          'travelid': coord['travel_id'],
        });
        syncedIds.add(coord['id'] as int);
      }

      if (syncedIds.isNotEmpty) {
        await _localStorage.markCoordinatesAsSynced(syncedIds);
      }
    } catch (e) {
      print('Error syncing coordinates: $e');
    }
  }

  // End the current travel
  Future<void> endTravel() async {
    _recordingTimer?.cancel();
    if (!_isTracking || _currentTravelId == null) {
      throw Exception('No active travel to end');
    }

    try {
      // Try to sync any remaining coordinates
      await _syncPendingCoordinates();

      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        await _firestore
            .collection('travels')
            .where('travel_id', isEqualTo: _currentTravelId)
            .get()
            .then((querySnapshot) {
          querySnapshot.docs.first.reference.update({
            'end_timestamp': FieldValue.serverTimestamp(),
          });
        });
      }

      _isTracking = false;
      _currentTravelId = null;
    } catch (e) {
      print('Error ending travel: $e');
      throw Exception('Failed to end travel');
    }
  }

  // Get the current travel status
  bool get isTracking => _isTracking;

  // Get the current travel ID
  int? get currentTravelId => _currentTravelId;

  // Get coordinates for a specific travel
  Future<List<Map<String, dynamic>>> getTravelCoordinates(int travelId) async {
    try {
      final querySnapshot = await _firestore
          .collection('coords')
          .where('travelid', isEqualTo: travelId)
          .orderBy('timestamp')
          .get();

      return querySnapshot.docs
          .map((doc) => {
                'coords': doc.data()['coords'],
                'timestamp': doc.data()['timestamp'],
              })
          .toList();
    } catch (e) {
      print('Error fetching travel coordinates: $e');
      return [];
    }
  }
} 