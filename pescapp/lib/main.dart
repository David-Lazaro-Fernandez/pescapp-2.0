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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PescApp',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: SignInPage(),  // Set SignInPage as initial screen
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
