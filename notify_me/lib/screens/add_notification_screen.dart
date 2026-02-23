import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import '../models/notification_model.dart';
import '../database/db_helper.dart';
import '../services/notification_service.dart';
import '../services/app_cache_service.dart';
import '../widgets/app_icon_widget.dart'; 

class AddNotificationScreen extends StatefulWidget {
  const AddNotificationScreen({super.key});

  @override
  State<AddNotificationScreen> createState() => _AddNotificationScreenState();
}

class _AddNotificationScreenState extends State<AddNotificationScreen> {
  // Paleta de cores
  final Color spaceIndigo = const Color(0xFF000033);
  final Color grapeSoda = const Color(0xFFea2f59);
  final Color amethystSmoke = const Color(0xFFA675A1);
  final Color grafite = const Color(0xFF466365);

  // Estado do horário
  TimeOfDay _selectedTime = TimeOfDay.now();

  // Variáveis para os apps
  List<AppInfo> _apps = [];
  AppInfo? _selectedApp;
  bool _isLoadingApps = true;

  // Controller do Texto
  final TextEditingController _messageController = TextEditingController();

  // 1 = Segunda, 7 = Domingo (Padrão DateTime do Dart)
  List<int> _selectedDays = [1, 2, 3, 4, 5, 6, 7]; // Por padrão, todos os dias

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadInstalledApps();
  }

  Future<void> _loadInstalledApps() async {
    // Usa o cache em memória ao invés de ler do sistema toda vez
    final apps = await AppCacheService().loadApps();

    if (mounted) {
      setState(() {
        _apps = apps;
        _isLoadingApps = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Pegamos a altura do teclado
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Material(
      color: Colors.transparent,
      child: Stack( // Usamos Stack para garantir o alinhamento
        children: [
          // Gesto para fechar clicando fora (opcional, mas bom UX)
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(color: Colors.transparent),
          ),
          
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              // Adicionamos o keyboardHeight na margem inferior
              // Se o teclado abrir, o padding aumenta e empurra o modal pra cima
              padding: EdgeInsets.only(
                right: 20, 
                bottom: 90 + keyboardHeight // 90 é a distância do botão +, somamos o teclado
              ),
              child: Container(
                // Constraints para não ficar gigante nem minúsculo
                constraints: BoxConstraints(
                  maxWidth: size.width * 0.85, // Expandimos para 85% da tela
                  maxHeight: size.height * 0.65,
                ),
                width: size.width * 0.85.clamp(340.0, 500.0),
                
                decoration: BoxDecoration(
                  color: spaceIndigo,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.55),
                      blurRadius: 30,
                      offset: const Offset(-12, -12),
                      spreadRadius: 2,
                    ),
                  ],
                ),

                // SingleChildScrollView e Column com mainAxisSize.min
                // Isso resolve o erro amarelo (Overflow) e permite rolar se o teclado apertar a tela
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Ocupa só o espaço necessário
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tracinho decorativo
                      Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: amethystSmoke.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      const Center(
                        child: Text(
                          "Nova Notificação",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        )
                      ),
                      const SizedBox(height: 20),

                      // Campos do formulário
                      Text('Aplicativo', style: TextStyle(color: amethystSmoke, fontSize: 14)),
                      const SizedBox(height: 8),
                      _buildAppSelector(), // <--- MUDAMOS PARA O SELETOR NOVO AQUI

                      const SizedBox(height: 20),

                      Text('Mensagem', style: TextStyle(color: amethystSmoke, fontSize: 14)),
                      const SizedBox(height: 8),
                      _buildTextField(),

                      const SizedBox(height: 20),

                      Text('Horário', style: TextStyle(color: amethystSmoke, fontSize: 14)),
                      const SizedBox(height: 8),
                      _buildTimePicker(),

                      const SizedBox(height: 20),
                      Text('Dias da Semana', style: TextStyle(color: amethystSmoke, fontSize: 14)),
                      const SizedBox(height: 8),
                      _buildDaysSelector(), 
                      const SizedBox(height: 24),

                      // Botão Agendar
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: grapeSoda,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          onPressed: () async {
                            if (_selectedApp == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Selecione um aplicativo!')),
                                );
                                return;
                            }
                            
                            if (_messageController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Digite uma mensagem!')),
                                );
                                return;
                            }

                            // 1. Cria o modelo
                            final notification = NotificationModel(
                              appName: _selectedApp!.name!,
                              packageName: _selectedApp!.packageName,
                              message: _messageController.text,
                              hour: _selectedTime.hour,
                              minute: _selectedTime.minute,
                              days: _selectedDays.join(','),
                            );

                            // 2. Salva no Banco e PEGA O ID GERADO
                            final int newId = await DBHelper().insertNotification(notification);

                            // 3. AGORA SIM: Chama o Motor de Notificação 🔔 (Sem await para ser rápido)
                            NotificationService().scheduleNotification(
                              id: newId,
                              title: 'Hora de usar: ${_selectedApp!.name!}',
                              body: _messageController.text,
                              hour: _selectedTime.hour,
                              minute: _selectedTime.minute,
                              payload: _selectedApp!.packageName,
                              days: _selectedDays,
                            );

                            print("SUCESSO: Salvo no banco ID $newId e Agendado para ${_selectedTime.format(context)}");

                            if (mounted) {
                              Navigator.pop(context, true);
                            }
                          },
                          child: const Text('Agendar Notificação', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildAppSelector() {
    if (_isLoadingApps) {
      return Container(
        height: 50,
        decoration: BoxDecoration(color: grafite.withOpacity(0.35), borderRadius: BorderRadius.circular(14)),
        child: Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: grapeSoda))),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: _showAppSearchModal, // Chama a gaveta de pesquisa
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: grafite.withOpacity(0.35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.transparent), 
        ),
        child: Row(
          children: [
            _selectedApp != null && _selectedApp!.icon != null
                ? Image.memory(_selectedApp!.icon!, width: 24, height: 24)
                : Icon(Icons.android, color: Colors.white.withOpacity(0.5), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedApp != null ? _selectedApp!.name! : "Selecione o aplicativo",
                style: TextStyle(
                  color: _selectedApp != null ? Colors.white : Colors.white.withOpacity(0.4), 
                  fontSize: 16
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.search, color: grapeSoda), // Ícone de lupa
          ],
        ),
      ),
    );
  }

  void _showAppSearchModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite que a gaveta ocupe mais espaço na tela
      backgroundColor: Colors.transparent,
      builder: (context) {
        // Copiamos a lista original para não perder os dados ao apagar a pesquisa
        List<AppInfo> filteredApps = List.from(_apps);
        
        // StatefulBuilder permite atualizar a tela DENTRO do modal
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75, // 75% da tela
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              decoration: BoxDecoration(
                color: spaceIndigo,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // A BARRA DE PESQUISA
                  TextField(
                    autofocus: true, // Já abre o teclado direto
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Digite o nome do app...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                      prefixIcon: Icon(Icons.search, color: amethystSmoke),
                      filled: true,
                      fillColor: grafite.withOpacity(0.35),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14), 
                        borderSide: BorderSide.none
                      ),
                    ),
                    onChanged: (value) {
                      setStateModal(() {
                        // AQUI ESTÁ A LÓGICA DO FILTRO (Ignora maiúsculas/minúsculas)
                        filteredApps = _apps.where((app) {
                          return app.name!.toLowerCase().contains(value.toLowerCase());
                        }).toList();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // A LISTA DE RESULTADOS
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredApps.length,
                      itemBuilder: (context, index) {
                        final app = filteredApps[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 4),
                          leading: app.icon != null 
                            ? Image.memory(app.icon!, width: 40, height: 40)
                            : const Icon(Icons.android, color: Colors.white),
                          title: Text(
                            app.name!, 
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)
                          ),
                          onTap: () {
                            // Quando clica, salva a escolha e fecha a gaveta
                            setState(() {
                              _selectedApp = app;
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTextField() {
    return TextField(
      controller: _messageController,
      style: const TextStyle(color: Colors.white),
      maxLines: 2,
      minLines: 1,
      decoration: InputDecoration(
        hintText: 'Digite a mensagem...',
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
        filled: true,
        fillColor: grafite.withOpacity(0.35),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildTimePicker() {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: _selectedTime,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.dark(
                  primary: grapeSoda,
                  onPrimary: Colors.white,
                  surface: spaceIndigo,
                  onSurface: Colors.white,
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(foregroundColor: grapeSoda),
                ),
              ),
              child: child!,
            );
          },
        );

        if (picked != null && picked != _selectedTime) {
          setState(() {
            _selectedTime = picked;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: grafite.withOpacity(0.35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: grapeSoda.withOpacity(0.4), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedTime.format(context),
              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
            ),
            Icon(Icons.access_time_rounded, color: grapeSoda, size: 26),
          ],
        ),
      ),
    );
  }

  Widget _buildDaysSelector() {
    final daysOfWeek = [
      {'name': 'D', 'val': 7},
      {'name': 'S', 'val': 1},
      {'name': 'T', 'val': 2},
      {'name': 'Q', 'val': 3},
      {'name': 'Q', 'val': 4},
      {'name': 'S', 'val': 5},
      {'name': 'S', 'val': 6},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: daysOfWeek.map((day) {
        final isSelected = _selectedDays.contains(day['val']);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected && _selectedDays.length > 1) {
                _selectedDays.remove(day['val']);
              } else if (!isSelected) {
                _selectedDays.add(day['val'] as int);
              }
            });
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isSelected ? grapeSoda : grafite.withOpacity(0.35),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              day['name'] as String,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}