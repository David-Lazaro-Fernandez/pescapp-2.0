import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pescapp/widgets/base_layout.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:pescapp/services/firebase_service.dart';
import 'package:pescapp/services/location_service.dart';
import 'package:pescapp/screens/signin.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final FirebaseService _firebaseService = FirebaseService();
  final LocationService _locationService = LocationService();
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  bool _isLoading = true;
  bool _isTripActive = false;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Solicitar permisos usando el diálogo por defecto de Android
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      final position = await _locationService.getCurrentLocation();
      final currentLocation = _locationService.positionToLatLng(position);
      
      setState(() {
        _currentPosition = currentLocation;
        _isLoading = false;
      });

      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(currentLocation, 15),
        );
      }
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        _isLoading = false;
      });
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error de ubicación'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const SignInPage()),
                  );
                },
                child: const Text('Volver al inicio de sesión'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_currentPosition != null) {
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition!, 15),
      );
    }
  }

  Future<void> _handleTripStart() async {
    try {
      setState(() {
        _isTripActive = !_isTripActive;
      });

      if (_isTripActive) {
        await _firebaseService.startTravel();
        // Mostrar diálogo de cuenta regresiva
        if (context.mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => CountdownDialog(),
          );
        }
      } else {
        _firebaseService.stopTravel();
      }
    } catch (e) {
      // Si hay un error, revertir el estado
      setState(() {
        _isTripActive = !_isTripActive;
      });
      // Mostrar error al usuario
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al ${_isTripActive ? "iniciar" : "detener"} el viaje'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      currentIndex: 2,
      child: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_currentPosition == null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('No se pudo obtener la ubicación'),
                  ElevatedButton(
                    onPressed: _initializeLocation,
                    child: Text('Reintentar'),
                  ),
                ],
              ),
            )
          else
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _currentPosition!,
                zoom: 15,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
              mapToolbarEnabled: true,
            ),
          // Barra de búsqueda
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: '¿A dónde iremos hoy?',
                      border: InputBorder.none,
                      icon: Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Botones de filtro
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterButton('Muelle', Icons.anchor),
                      const SizedBox(width: 8),
                      _buildFilterButton('Pescado', Icons.phishing),
                      const SizedBox(width: 8),
                      _buildFilterButton('Zona en V', Icons.close),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Botón de inicio/fin de viaje
          Positioned(
            left: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: _handleTripStart,
              backgroundColor: const Color(0xFF1B67E0),
              label: Text(_isTripActive ? 'Finalizar Viaje' : 'Iniciar Viaje'),
              icon: Icon(_isTripActive ? Icons.stop : Icons.play_arrow),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, IconData icon) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

// Create a new widget for the countdown dialog
class CountdownDialog extends StatefulWidget {
  @override
  _CountdownDialogState createState() => _CountdownDialogState();
}

class _CountdownDialogState extends State<CountdownDialog> {
  int _countDown = 3;

  @override
  void initState() {
    super.initState();
    _startCountDown();
  }

  void _startCountDown() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countDown > 0) {
          _countDown--;
        } else {
          timer.cancel();
          Navigator.of(context).pop();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Iniciando viaje'),
      content: SizedBox(
        height: 100,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _countDown > 0 ? '$_countDown' : '¡Comenzamos!',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (_countDown > 0)
                const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
} 