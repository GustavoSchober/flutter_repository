import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';

class AppIconWidget extends StatelessWidget {
  final String packageName;
  final double size;

  const AppIconWidget({
    super.key,
    required this.packageName,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Application?>(
      // Pergunta pro Android quem é esse app e pede o ícone
      future: DeviceApps.getApp(packageName, true),
      builder: (context, snapshot) {
        // Se achou o app e ele tem ícone
        if (snapshot.hasData && snapshot.data is ApplicationWithIcon) {
          final app = snapshot.data as ApplicationWithIcon;
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: MemoryImage(app.icon), // Converte bytes em imagem
                fit: BoxFit.cover,
              ),
            ),
          );
        }

        // Se ainda tá carregando ou não achou (Fallback), mostra o sino
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFF25283D), // Space Indigo
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFA675A1).withOpacity(0.3)),
          ),
          child: const Icon(
            Icons.notifications_active,
            color: Color(0xFFA675A1), // Amethyst Smoke
            size: 24,
          ),
        );
      },
    );
  }
}