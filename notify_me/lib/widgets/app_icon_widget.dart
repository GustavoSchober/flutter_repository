import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';

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
    return FutureBuilder<AppInfo?>(
      // Busca informações do app pelo pacote
      future: InstalledApps.getAppInfo(packageName, null),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.icon != null) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                // O ícone agora vem como Uint8List direto
                image: MemoryImage(snapshot.data!.icon!), 
                fit: BoxFit.cover,
              ),
            ),
          );
        }

        // Fallback (Sino)
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFF25283D),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFA675A1).withOpacity(0.3)),
          ),
          child: Icon(
            Icons.notifications_active,
            color: const Color(0xFFA675A1),
            size: size * 0.5,
          ),
        );
      },
    );
  }
}