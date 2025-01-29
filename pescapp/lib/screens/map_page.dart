import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pescapp/services/google_maps_service.dart';
import 'package:pescapp/widgets/base_layout.dart';
import 'dart:async';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController mapController;
  final GoogleMapsService _googleMapsService = GoogleMapsService();

  final LatLng _initialPosition = const LatLng(18.293232, -93.863316);
  final Set<Marker> _markers = {};

  // Add new variable to track trip status
  bool isTripActive = false;

  // Function to show countdown dialog
  Future<void> _showCountdownDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CountdownDialog();
      },
    );
  }

  // Add this function to show the confirmation dialog
  Future<bool?> _showEndTripConfirmationDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Finalizar viaje'),
          content: Text('¿Estás seguro que quieres terminar el viaje?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text('Sí, Finalizar'),
            ),
          ],
        );
      },
    );
  }

  // Modify the _handleTripStart function
  void _handleTripStart() async {
    if (isTripActive) {
      // Show confirmation dialog when trying to end trip
      final bool? shouldEnd = await _showEndTripConfirmationDialog();
      if (shouldEnd ?? false) {
        setState(() {
          isTripActive = false;
        });
        // Add your trip end logic here
      }
    } else {
      // Start new trip
      await _showCountdownDialog();
      setState(() {
        isTripActive = true;
      });
      // Add your trip start logic here
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _addMarkers();
  }

  void _addMarkers() {
    final marker = _googleMapsService.createMarker(
      markerId: 'defaultMarker',
      position: _initialPosition,
      infoWindowTitle: 'Default Location',
    );
    setState(() {
      _markers.add(marker);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      currentIndex: 3, // Set the index for the map tab
      child: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 11.0,
            ),
            markers: _markers,
          ),
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Column(
              children: [
                _buildSearchBar(),
                const SizedBox(height: 16),
                _buildButtonRow(),
              ],
            ),
          ),
          Positioned(
            left: 16,
            bottom: 32,
            child: FloatingActionButton.extended(
              onPressed: _handleTripStart,
              backgroundColor: const Color(0xFF1B67E0),
              label: Text(
                isTripActive ? 'Finalizar viaje' : 'Iniciar viaje',
                style: TextStyle(color: Colors.white),
              ),
              icon: Icon(
                isTripActive ? Icons.stop : Icons.play_arrow,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
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
    );
  }

  Widget _buildButtonRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildButton('Muelle', Icons.anchor),
        _buildButton('Pescado', Icons.phishing),
        _buildButton('Zona en V', Icons.close),
      ],
    );
  }

  Widget _buildButton(String label, IconData icon) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 2,
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