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

  // Function to handle trip start
  void _handleTripStart() async {
    await _showCountdownDialog();
    setState(() {
      isTripActive = true;
    });
    // Add your trip start logic here
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