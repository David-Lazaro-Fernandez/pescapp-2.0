import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:pescapp/services/local_storage_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalStorageService _localStorage = LocalStorageService();
  final Connectivity _connectivity = Connectivity();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Timer? _coordsTimer;
  Timer? _syncTimer;
  String? _currentTravelId;

  FirebaseService() {
    // Iniciar timer de sincronización
    _startSyncTimer();
  }

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

  // Iniciar un nuevo viaje
  Future<void> startTravel() async {
    try {
      // Verificar que hay un usuario autenticado
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No hay usuario autenticado');
      }

      // Generar un ID único para el viaje
      _currentTravelId = DateTime.now().millisecondsSinceEpoch.toString();

      // Verificar conectividad
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        // Si hay conexión, crear el documento en Firestore
        await _firestore.collection('travels').add({
          'timestamp': FieldValue.serverTimestamp(),
          'travel_id': _currentTravelId,
          'user_id': user.uid,
          'user_email': user.email,
        });
      } else {
        // Si no hay conexión, guardar localmente
        await _localStorage.saveTravel(_currentTravelId!, DateTime.now(), user.uid);
      }

      // Iniciar el timer para registrar coordenadas
      _startCoordsRecording();
    } catch (e) {
      print('Error starting travel: $e');
      throw Exception('No se pudo iniciar el viaje');
    }
  }

  // Detener el viaje actual
  void stopTravel() {
    _coordsTimer?.cancel();
    _currentTravelId = null;
  }

  // Timer para sincronización periódica
  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      await _syncPendingData();
    });
  }

  // Sincronizar datos pendientes
  Future<void> _syncPendingData() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return; // No hay conexión, salir
      }

      // Sincronizar viajes pendientes
      final pendingTravels = await _localStorage.getPendingTravels();
      for (final travel in pendingTravels) {
        await _firestore.collection('travels').add({
          'timestamp': travel['timestamp'],
          'travel_id': travel['travel_id'],
          'user_id': travel['user_id'],
        });
        await _localStorage.markTravelAsSynced(travel['travel_id'] as String);
      }

      // Sincronizar coordenadas pendientes
      final pendingCoords = await _localStorage.getUnsyncedCoordinates();
      for (final coord in pendingCoords) {
        await _firestore.collection('coords').add({
          'coords': {
            'lat': coord['latitude'],
            'lon': coord['longitude'],
          },
          'timestamp': coord['timestamp'],
          'travel_id': coord['travel_id'],
        });
        await _localStorage.markCoordinatesAsSynced(coord['id'] as int);
      }
    } catch (e) {
      print('Error syncing data: $e');
    }
  }

  // Registrar coordenadas periódicamente
  void _startCoordsRecording() {
    // Cancelar timer existente si hay uno
    _coordsTimer?.cancel();

    // Crear nuevo timer que se ejecuta cada 2 minutos
    _coordsTimer = Timer.periodic(const Duration(minutes: 2), (timer) async {
      if (_currentTravelId == null) {
        timer.cancel();
        return;
      }

      try {
        // Obtener posición actual
        Position position = await Geolocator.getCurrentPosition();
        final timestamp = DateTime.now();

        // Verificar conectividad
        final connectivityResult = await _connectivity.checkConnectivity();
        if (connectivityResult != ConnectivityResult.none) {
          // Si hay conexión, guardar en Firestore
          await _firestore.collection('coords').add({
            'coords': {
              'lat': position.latitude,
              'lon': position.longitude,
            },
            'timestamp': FieldValue.serverTimestamp(),
            'travel_id': _currentTravelId,
          });
        } else {
          // Si no hay conexión, guardar localmente
          await _localStorage.saveCoordinates(
            position.latitude,
            position.longitude,
            timestamp,
            _currentTravelId!,
          );
        }
      } catch (e) {
        print('Error recording coordinates: $e');
      }
    });
  }

  // Obtener el ID del viaje actual
  String? get currentTravelId => _currentTravelId;

  // Dispose timers
  void dispose() {
    _coordsTimer?.cancel();
    _syncTimer?.cancel();
  }
}
