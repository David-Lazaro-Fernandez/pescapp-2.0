import 'package:flutter/material.dart';

class BaseLayout extends StatelessWidget {
  final Widget child;
  final int currentIndex;

  const BaseLayout({
    super.key,
    required this.child,
    this.currentIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.cloud), label: 'Weather'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Compass'),
          BottomNavigationBarItem(icon: Icon(Icons.water), label: 'Fish'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/dashboard');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/weather');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/compass');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/map');
              break;
            case 4:
              Navigator.pushReplacementNamed(context, '/profile');
              break;
          }
        },
      ),
    );
  }
} 