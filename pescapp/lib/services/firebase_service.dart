import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:pescapp/services/local_storage_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseService extends ChangeNotifier {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  
  FirebaseService._internal() {
    _startSyncTimer();
    _restoreState();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalStorageService _localStorage = LocalStorageService();
  final Connectivity _connectivity = Connectivity();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<Position>? _locationSubscription;
  Timer? _syncTimer;
  String? _currentTravelId;
  bool _isTracking = false;

  bool get isTracking => _isTracking;
  
  Future<void> _restoreState() async {
    try {
      // Verificar si hay un viaje activo en Firestore
      final user = _auth.currentUser;
      if (user != null) {
        final activeTravel = await _firestore
            .collection('travels')
            .where('user_id', isEqualTo: user.uid)
            .where('status', isEqualTo: 'active')
            .get();

        if (activeTravel.docs.isNotEmpty) {
          final travelDoc = activeTravel.docs.first;
          _currentTravelId = travelDoc.data()['travel_id'];
          _isTracking = true;
          _startCoordsRecording();
        }
      }
    } catch (e) {
      print('Error restoring state: $e');
    }
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

      // Verificar si ya hay un viaje activo
      if (_isTracking) {
        throw Exception('Ya hay un viaje activo');
      }

      // Generar un ID único para el viaje
      _currentTravelId = DateTime.now().millisecondsSinceEpoch.toString();
      _isTracking = true;

      // Obtener la posición inicial
      Position initialPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        forceAndroidLocationManager: true,
      );
      final timestamp = DateTime.now();

      // Verificar conectividad
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        // Si hay conexión, crear el documento en Firestore y guardar la coordenada inicial
        await _firestore.collection('travels').add({
          'timestamp': FieldValue.serverTimestamp(),
          'travel_id': _currentTravelId,
          'user_id': user.uid,
          'user_email': user.email,
          'initial_coords': {
            'lat': initialPosition.latitude,
            'lon': initialPosition.longitude,
          },
          'status': 'active',
        });

        // Guardar la coordenada inicial
        await _firestore.collection('coords').add({
          'coords': {
            'lat': initialPosition.latitude,
            'lon': initialPosition.longitude,
          },
          'timestamp': FieldValue.serverTimestamp(),
          'travel_id': _currentTravelId,
          'type': 'initial',
          'accuracy': initialPosition.accuracy,
          'altitude': initialPosition.altitude,
          'speed': initialPosition.speed,
        });
      }

      // Siempre guardar localmente, independientemente de la conexión
      await _localStorage.saveTravel(
        _currentTravelId!,
        timestamp,
        user.uid,
        initialPosition.latitude,
        initialPosition.longitude,
      );
      
      await _localStorage.saveCoordinates(
        initialPosition.latitude,
        initialPosition.longitude,
        timestamp,
        _currentTravelId!,
        'initial',
        accuracy: initialPosition.accuracy,
        altitude: initialPosition.altitude,
        speed: initialPosition.speed,
      );

      // Iniciar el tracking de coordenadas
      _startCoordsRecording();
    } catch (e) {
      print('Error starting travel: $e');
      _isTracking = false;
      _currentTravelId = null;
      throw Exception('No se pudo iniciar el viaje');
    }
  }

  // Detener el viaje actual
  Future<void> stopTravel() async {
    try {
      if (_currentTravelId != null) {
        // Obtener la posición final
        Position finalPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          forceAndroidLocationManager: true,
        );
        final timestamp = DateTime.now();

        // Siempre guardar localmente primero
        await _localStorage.saveCoordinates(
          finalPosition.latitude,
          finalPosition.longitude,
          timestamp,
          _currentTravelId!,
          'final',
          accuracy: finalPosition.accuracy,
          altitude: finalPosition.altitude,
          speed: finalPosition.speed,
        );

        await _localStorage.endTravel(
          _currentTravelId!,
          finalPosition.latitude,
          finalPosition.longitude,
        );

        // Verificar conectividad
        final connectivityResult = await _connectivity.checkConnectivity();
        if (connectivityResult != ConnectivityResult.none) {
          // Guardar la coordenada final
          await _firestore.collection('coords').add({
            'coords': {
              'lat': finalPosition.latitude,
              'lon': finalPosition.longitude,
            },
            'timestamp': FieldValue.serverTimestamp(),
            'travel_id': _currentTravelId,
            'type': 'final',
            'accuracy': finalPosition.accuracy,
            'altitude': finalPosition.altitude,
            'speed': finalPosition.speed,
          });

          // Actualizar el documento del viaje con la hora de finalización
          await _firestore
              .collection('travels')
              .where('travel_id', isEqualTo: _currentTravelId)
              .get()
              .then((querySnapshot) {
            querySnapshot.docs.first.reference.update({
              'end_timestamp': FieldValue.serverTimestamp(),
              'final_coords': {
                'lat': finalPosition.latitude,
                'lon': finalPosition.longitude,
              },
              'status': 'completed',
            });
          });
        }
      }
    } catch (e) {
      print('Error stopping travel: $e');
    } finally {
      _locationSubscription?.cancel();
      _currentTravelId = null;
      _isTracking = false;
    }
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
          'status': travel['status'],
          'initial_coords': {
            'lat': travel['start_latitude'],
            'lon': travel['start_longitude'],
          },
          if (travel['end_latitude'] != null) 'final_coords': {
            'lat': travel['end_latitude'],
            'lon': travel['end_longitude'],
          },
          if (travel['end_timestamp'] != null) 'end_timestamp': travel['end_timestamp'],
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
          'type': coord['coord_type'],
          'accuracy': coord['accuracy'],
          'altitude': coord['altitude'],
          'speed': coord['speed'],
        });
        await _localStorage.markCoordinatesAsSynced(coord['id'] as int);
      }

      // Limpiar datos antiguos sincronizados
      await _localStorage.deleteOldSyncedData();
    } catch (e) {
      print('Error syncing data: $e');
    }
  }

  // Registrar coordenadas periódicamente
  void _startCoordsRecording() {
    // Cancelar subscription existente si hay uno
    _locationSubscription?.cancel();

    // Configurar opciones de localización en segundo plano
    final LocationSettings locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
      forceLocationManager: true,
      intervalDuration: const Duration(minutes: 2),
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationText: "PescApp está registrando tu ubicación",
        notificationTitle: "Viaje en curso",
        enableWakeLock: true,
      ),
    );

    // Suscribirse a actualizaciones de ubicación
    _locationSubscription = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) async {
      if (_currentTravelId == null || !_isTracking) {
        _locationSubscription?.cancel();
        return;
      }

      try {
        final timestamp = DateTime.now();

        // Siempre guardar localmente primero
        await _localStorage.saveCoordinates(
          position.latitude,
          position.longitude,
          timestamp,
          _currentTravelId!,
          'tracking',
          accuracy: position.accuracy,
          altitude: position.altitude,
          speed: position.speed,
        );

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
            'type': 'tracking',
            'accuracy': position.accuracy,
            'altitude': position.altitude,
            'speed': position.speed,
          });
        }
      } catch (e) {
        print('Error recording coordinates: $e');
      }
    });
  }

  // Obtener el ID del viaje actual
  String? get currentTravelId => _currentTravelId;

  set currentTravelId(String? value) {
    if (_currentTravelId != value) {
      _currentTravelId = value;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }

  Future<bool> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user != null;
    } catch (e) {
      print('Error signing in: $e');
      String errorMessage;
      switch (e.toString()) {
        case 'user-not-found':
          errorMessage = 'No existe una cuenta con este correo electrónico';
          break;
        case 'wrong-password':
          errorMessage = 'Contraseña incorrecta';
          break;
        case 'invalid-email':
          errorMessage = 'Correo electrónico inválido';
          break;
        case 'user-disabled':
          errorMessage = 'Esta cuenta ha sido deshabilitada';
          break;
        default:
          errorMessage = 'Error al iniciar sesión';
      }
      throw Exception(errorMessage);
    }
  }

  bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }

  set isTracking(bool value) {
    if (_isTracking != value) {
      _isTracking = value;
      notifyListeners();
    }
  }
}
