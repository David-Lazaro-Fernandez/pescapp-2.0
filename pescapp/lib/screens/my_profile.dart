import 'package:flutter/material.dart';
import 'package:pescapp/widgets/base_layout.dart';

class MyProfilePage extends StatelessWidget {
  const MyProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      currentIndex: 4, // Profile tab
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            _buildSettingsList(),
          ],
        ),
      ),
    );
  }

Widget _buildProfileHeader() {
  return Center(
    child: Container(
      padding: const EdgeInsets.fromLTRB(0, 32, 0, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Powered By: ML Cats Consultancy',
            textAlign: TextAlign.center, // Asegura que el texto también quede centrado
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0E0E0E),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Este proyecto fue desarrollado por ECOSUR y financiado por recursos de PRODECTI 2023 CCyTET',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF0E0E0E),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildSettingsList() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          _SettingsButton(
            icon: Icons.edit,
            title: 'Editar Perfil',
            subtitle: 'Cambia la información de tu perfil',
            onTap: () {},
          ),
          _SettingsButton(
            icon: Icons.notifications,
            title: 'Notificaciones',
            subtitle: 'Añade tus preferencias',
            onTap: () {},
          ),
          _SettingsButton(
            icon: Icons.security,
            title: 'Seguridad',
            subtitle: 'Configura tu contraseña',
            onTap: () {},
          ),
          _SettingsButton(
            icon: Icons.language,
            title: 'Idioma',
            subtitle: 'Cambia el idioma de la app',
            onTap: () {},
          ),
          _SettingsButton(
            icon: Icons.logout,
            title: 'Cerrar Sesión',
            subtitle: 'Cierra tu sesión en la app',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1B67E0),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0E0E0E),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF717171),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 