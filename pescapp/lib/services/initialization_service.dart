import 'package:shared_preferences/shared_preferences.dart';
import 'package:pescapp/services/permission_service.dart';

class InitializationService {
  static const String _permissionsCheckedKey = 'permissions_checked';
  final PermissionService _permissionService = PermissionService();

  Future<bool> checkIfPermissionsAlreadyGranted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_permissionsCheckedKey) ?? false;
  }

  Future<bool> requestInitialPermissions() async {
    try {
      final hasPermissions = await _permissionService.checkAndRequestLocationPermission();
      if (hasPermissions) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_permissionsCheckedKey, true);
      }
      return hasPermissions;
    } catch (e) {
      print('Error requesting permissions: $e');
      return false;
    }
  }

  Future<void> resetPermissionsCheck() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionsCheckedKey, false);
  }
} 