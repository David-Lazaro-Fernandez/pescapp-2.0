import 'package:flutter/material.dart';
import 'package:pescapp/services/permission_service.dart';
import 'package:pescapp/screens/signin.dart';
import 'package:pescapp/screens/map_page.dart';
import 'package:pescapp/services/firebase_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final PermissionService _permissionService = PermissionService();
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Verificar si hay un usuario autenticado
      final isLoggedIn = _firebaseService.isUserLoggedIn();
      
      if (!isLoggedIn) {
        // Si no hay usuario, ir a sign in
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SignInPage()),
          );
        }
        return;
      }

      // Si hay usuario, verificar permisos
      final hasPermissions = await _permissionService.hasLocationPermission();
      if (!hasPermissions) {
        final granted = await _permissionService.checkAndRequestLocationPermission();
        if (!granted) {
          // Si no se otorgaron los permisos, ir a sign in
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SignInPage()),
            );
          }
          return;
        }
      }

      // Si todo está bien, ir al mapa
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MapPage()),
        );
      }
    } catch (e) {
      print('Error in initialization: $e');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SignInPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'PescApp',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B67E0),
              ),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
} 