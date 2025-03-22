import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pescapp/services/permission_service.dart';

class LocationService {
  final PermissionService _permissionService = PermissionService();

  Future<Position> getCurrentLocation() async {
    try {
      final hasPermission = await _permissionService.hasLocationPermission();
      if (!hasPermission) {
        throw Exception('Se requieren permisos de ubicación para usar esta función');
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      ).catchError((error) {
        if (error is TimeoutException) {
          return Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 5),
          );
        }
        throw error;
      });
    } catch (e) {
      print('Error getting location: $e');
      rethrow;
    }
  }

  // Helper method to convert Position to LatLng
  LatLng positionToLatLng(Position position) {
    return LatLng(position.latitude, position.longitude);
  }

  // Método para verificar si los permisos están realmente otorgados
  Future<bool> arePermissionsGranted() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always || 
             permission == LocationPermission.whileInUse;
    } catch (e) {
      print('Error checking granted permissions: $e');
      return false;
    }
  }
} 