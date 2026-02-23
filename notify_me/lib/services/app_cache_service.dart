import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';

/// Serviço Singleton que mantém a lista de apps instalados em cache na memória.
/// Evita recarregar os apps do sistema toda vez que o usuário abre a tela de agendamento.
class AppCacheService {
  static final AppCacheService _instance = AppCacheService._internal();
  factory AppCacheService() => _instance;
  AppCacheService._internal();

  // O cache dos apps
  List<AppInfo> _cachedApps = [];
  bool _isLoaded = false;

  /// Retorna true se o cache já foi carregado
  bool get isLoaded => _isLoaded;

  /// Retorna a lista de apps cacheada
  List<AppInfo> get apps => _cachedApps;

  /// Carrega os apps do sistema e armazena no cache.
  /// Se [forceReload] for true, recarrega mesmo que já tenha cache.
  Future<List<AppInfo>> loadApps({bool forceReload = false}) async {
    if (_isLoaded && !forceReload) {
      return _cachedApps;
    }

    List<AppInfo> apps = await InstalledApps.getInstalledApps(true, true);

    // Remove apps sem nome (processos de sistema)
    apps = apps.where((app) => app.name != null).toList();

    // Ordena alfabeticamente
    apps.sort((a, b) => a.name!.toLowerCase().compareTo(b.name!.toLowerCase()));

    _cachedApps = apps;
    _isLoaded = true;

    print("📱 AppCacheService: ${apps.length} apps carregados no cache.");
    return _cachedApps;
  }

  /// Força o recarregamento do cache (usar no onResume)
  Future<void> refresh() async {
    await loadApps(forceReload: true);
  }
}
