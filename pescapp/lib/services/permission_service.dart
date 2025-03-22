import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

class PermissionService {
  static const String _locationPermissionKey = 'location_permission_granted';
  static final PermissionService _instance = PermissionService._internal();
  
  factory PermissionService() => _instance;
  
  PermissionService._internal();

  Future<bool> hasLocationPermission() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_locationPermissionKey) ?? false;
  }

  Future<bool> checkAndRequestLocationPermission() async {
    try {
      // Verificar si el servicio está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      // Verificar permisos actuales
      LocationPermission permission = await Geolocator.checkPermission();
      
      // Si los permisos están denegados, solicitarlos
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      // Si los permisos están permanentemente denegados
      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      // Guardar el estado de los permisos
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_locationPermissionKey, true);
      
      return true;
    } catch (e) {
      print('Error checking permissions: $e');
      return false;
    }
  }

  Future<void> resetPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_locationPermissionKey, false);
  }
} 