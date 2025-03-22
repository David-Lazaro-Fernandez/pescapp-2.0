import 'package:flutter/foundation.dart';
import 'package:pescapp/services/firebase_service.dart';

class TripProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;
  bool _isTripActive = false;
  String? _currentTripId;

  bool get isLoading => _isLoading;
  bool get isTripActive => _isTripActive;
  String? get currentTripId => _currentTripId;

  TripProvider() {
    _initializeState();
    // Escuchar cambios en FirebaseService
    _firebaseService.addListener(_onFirebaseStateChanged);
  }

  void _onFirebaseStateChanged() {
    final newIsTracking = _firebaseService.isTracking;
    final newTripId = _firebaseService.currentTravelId;
    
    if (_isTripActive != newIsTracking || _currentTripId != newTripId) {
      _isTripActive = newIsTracking;
      _currentTripId = newTripId;
      notifyListeners();
    }
  }

  Future<void> _initializeState() async {
    _isTripActive = _firebaseService.isTracking;
    _currentTripId = _firebaseService.currentTravelId;
    notifyListeners();
  }

  Future<void> startTrip() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firebaseService.startTravel();
      _isTripActive = true;
      _currentTripId = _firebaseService.currentTravelId;

    } catch (e) {
      print('Error starting trip: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> endTrip() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firebaseService.stopTravel();
      _isTripActive = false;
      _currentTripId = null;

    } catch (e) {
      print('Error ending trip: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _firebaseService.removeListener(_onFirebaseStateChanged);
    super.dispose();
  }
}