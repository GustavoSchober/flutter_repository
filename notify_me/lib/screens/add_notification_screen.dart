import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import '../models/notification_model.dart';
import '../database/db_helper.dart';
import '../services/notification_service.dart';
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
    // Busca apps com ícones. O true/true significa "com icone" e "com pacote"
    List<AppInfo> apps = await InstalledApps.getInstalledApps(true, true);
    
    // Remove apps que não têm nome (processos de sistema estranhos)
    apps = apps.where((app) => app.name != null).toList();

    apps.sort((a, b) => a.name!.toLowerCase().compareTo(b.name!.toLowerCase()));

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
    // CORREÇÃO 2: Pegamos a altura do teclado
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
              // CORREÇÃO 2: Adicionamos o keyboardHeight na margem inferior
              // Se o teclado abrir, o padding aumenta e empurra o modal pra cima
              padding: EdgeInsets.only(
                right: 20, 
                bottom: 90 + keyboardHeight // 90 é a distância do botão +, somamos o teclado
              ),
              child: Container(
                // Constraints para não ficar gigante nem minúsculo
                constraints: BoxConstraints(
                  maxWidth: size.width * 0.85, // ⬅️ Expandimos para 85% da tela
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

                // CORREÇÃO 1: SingleChildScrollView e Column com mainAxisSize.min
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

                      Center(
                        child: Text(
                          "Nova Notificação",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        )
                      ),
                      const SizedBox(height: 20),

                      // Campos do formulário
                      Text('Aplicativo', style: TextStyle(color: amethystSmoke, fontSize: 14)),
                      const SizedBox(height: 8),
                      _buildDropdown(),

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
                      _buildDaysSelector(), // <--- ADICIONE AQUI
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

                            // 3. AGORA SIM: Chama o Motor de Notificação 🔔
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

  // --- WIDGETS AUXILIARES (Mesmos de antes) ---

  Widget _buildDropdown() {
    if (_isLoadingApps) {
      return Container(
        height: 50,
        decoration: BoxDecoration(color: grafite.withOpacity(0.35), borderRadius: BorderRadius.circular(14)),
        child: Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: grapeSoda))),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: grafite.withOpacity(0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButton<AppInfo>(
        isExpanded: true,
        dropdownColor: grafite.withOpacity(0.95),
        menuMaxHeight: 300,
        value: _selectedApp,
        hint: Text(
          "Selecione o app",
          style: TextStyle(color: Colors.white.withOpacity(0.6)),
        ),
        underline: const SizedBox(),
        icon: Icon(Icons.arrow_drop_down, color: grapeSoda),
        items: _apps.map((AppInfo app) {
          return DropdownMenuItem<AppInfo>(
            value: app,
            child: Row(
              children: [
                app.icon != null
                  ? Image.memory(app.icon!, width: 24, height: 24)
                  : Icon(Icons.android, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    app.name!,
                    style: const TextStyle(color: Colors.white),
                    overflow: TextOverflow.ellipsis, 
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (AppInfo? newValue) {
          setState(() {
            _selectedApp = newValue;
          });
        },
      ),
    );
  }

  Widget _buildTextField() {
    return TextField(
      controller: _messageController,
      style: const TextStyle(color: Colors.white),
      maxLines: 2,
      minLines: 1,
      // keyboardType: TextInputType.text, // Opcional
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