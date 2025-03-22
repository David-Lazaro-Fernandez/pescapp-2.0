import 'package:flutter/material.dart';
import 'package:pescapp/firebase_options.dart';
import 'package:pescapp/screens/signin.dart';
import 'package:pescapp/screens/signup.dart';
import 'package:pescapp/screens/dashboard.dart';
import 'package:pescapp/screens/my_profile.dart';
import 'package:pescapp/screens/map_page.dart';
import 'package:pescapp/screens/weather.dart';
import 'package:pescapp/screens/fishes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pescapp/services/permission_service.dart';
import 'package:pescapp/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PescApp',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B67E0)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/signin': (context) => SignInPage(),
        '/signup': (context) => SignUpPage(),
        '/dashboard': (context) => DashboardPage(),
        '/profile': (context) => MyProfilePage(),
        '/map': (context) => MapPage(),
        '/weather': (context) => WeatherScreen(),
        '/fish': (context) => FishesScreen(),
      },
    );
  }
}

class PermissionCheckScreen extends StatefulWidget {
  const PermissionCheckScreen({super.key});

  @override
  State<PermissionCheckScreen> createState() => _PermissionCheckScreenState();
}

class _PermissionCheckScreenState extends State<PermissionCheckScreen> {
  final PermissionService _permissionService = PermissionService();
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    bool hasPermissions = await _permissionService.hasLocationPermission();
    if (mounted) {
      if (hasPermissions) {
        Navigator.pushReplacementNamed(context, '/signin');
      } else {
        setState(() => _checking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _checking
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Se requieren permisos de ubicación para usar la aplicación',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _checking = true);
                      _checkPermissions();
                    },
                    child: const Text('Verificar Permisos'),
                  ),
                ],
              ),
      ),
    );
  }
}
