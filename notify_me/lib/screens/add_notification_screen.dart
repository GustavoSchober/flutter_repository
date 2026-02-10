import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';
import '../models/notification_model.dart';
import '../database/db_helper.dart';
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
  List<Application> _apps = [];
  Application? _selectedApp;
  bool _isLoadingApps = true;

  // Controller do Texto
  final TextEditingController _messageController = TextEditingController();

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
    // CORREÇÃO 3: includeSystemApps: true
    // Isso garante que apareça TUDO (Gmail, Agenda, Calculadora, etc)
    final apps = await DeviceApps.getInstalledApplications(
      includeAppIcons: true,
      includeSystemApps: true, 
      onlyAppsWithLaunchIntent: true, // Mantemos true para não pegar processos ocultos do Android
    );

    apps.sort((a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));

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
                  maxWidth: size.width * 0.65, // Aumentei um pouco a largura para caber melhor os textos
                  maxHeight: size.height * 0.6,
                ),
                width: size.width * 0.65.clamp(280.0, 420.0),
                
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

                            // Criar o Objeto NotificationModel
                            final notification = NotificationModel(
                              appName: _selectedApp!.appName,
                              packageName: _selectedApp!.packageName,
                              message: _messageController.text,
                              hour: _selectedTime.hour,
                              minute: _selectedTime.minute,
                            );

                            // Salvar no Banco
                            await DBHelper().insertNotification(notification);

                            if (mounted) {
                              Navigator.pop(context, true); // Retorna true para atualizar a Home
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
      child: DropdownButton<Application>(
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
        items: _apps.map((Application app) {
          return DropdownMenuItem<Application>(
            value: app,
            child: Row(
              children: [
                app is ApplicationWithIcon 
                  ? Image.memory(app.icon, width: 24, height: 24)
                  : Icon(Icons.android, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    app.appName,
                    style: const TextStyle(color: Colors.white),
                    overflow: TextOverflow.ellipsis, 
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (Application? newValue) {
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
}