import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../database/db_helper.dart';
import '../services/notification_service.dart';
import '../widgets/app_icon_widget.dart';

class EditNotificationScreen extends StatefulWidget {
  final NotificationModel notification;

  const EditNotificationScreen({super.key, required this.notification});

  @override
  State<EditNotificationScreen> createState() => _EditNotificationScreenState();
}

class _EditNotificationScreenState extends State<EditNotificationScreen> {
  // Cores do Tema
  final Color spaceIndigo = const Color(0xFF000033);
  final Color grapeSoda = const Color(0xFFea2f59);
  final Color amethystSmoke = const Color(0xFFA675A1);
  final Color grafite = const Color(0xFF466365);

  late TimeOfDay _selectedTime;
  late List<int> _selectedDays;
  late TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    // Carrega os dados da notificação existente para a tela
    _selectedTime = TimeOfDay(hour: widget.notification.hour, minute: widget.notification.minute);
    _messageController = TextEditingController(text: widget.notification.message);
    
    // Converte a string "1,2,3" de volta para uma lista de inteiros [1, 2, 3]
    _selectedDays = widget.notification.days.split(',').map((e) => int.parse(e)).toList();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: spaceIndigo,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Editar Notificação', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CABEÇALHO: Ícone e Nome do App
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: grafite.withOpacity(0.25),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  AppIconWidget(packageName: widget.notification.packageName, size: 50),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.notification.appName,
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),

            // RELÓGIO (TimePicker)
            Text('Horário', style: TextStyle(color: amethystSmoke, fontSize: 14)),
            const SizedBox(height: 8),
            _buildTimePicker(),

            const SizedBox(height: 24),

            // MENSAGEM (Opcional, mas útil manter na edição)
            Text('Mensagem', style: TextStyle(color: amethystSmoke, fontSize: 14)),
            const SizedBox(height: 8),
            _buildTextField(),

            const SizedBox(height: 24),

            // DIAS DA SEMANA
            Text('Dias da Semana', style: TextStyle(color: amethystSmoke, fontSize: 14)),
            const SizedBox(height: 8),
            _buildDaysSelector(),

            const SizedBox(height: 40),

            // BOTÕES: Salvar e Excluir
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: grapeSoda),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _deleteNotification,
                    child: Text('EXCLUIR', style: TextStyle(color: grapeSoda, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: grapeSoda,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _saveEdits,
                    child: const Text('SALVAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // --- FUNÇÕES DE AÇÃO ---

  Future<void> _saveEdits() async {
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione pelo menos um dia!')));
      return;
    }

    // 1. CANCELA os alarmes antigos no Android
    await NotificationService().cancelNotification(widget.notification.id!);

    // 2. ATUALIZA o modelo com os novos dados
    widget.notification.hour = _selectedTime.hour;
    widget.notification.minute = _selectedTime.minute;
    widget.notification.message = _messageController.text;
    widget.notification.days = _selectedDays.join(',');

    // 3. SALVA as alterações no Banco de Dados
    await DBHelper().updateNotification(widget.notification);

    // 4. AGENDA os novos alarmes
    NotificationService().scheduleNotification(
      id: widget.notification.id!,
      title: 'Hora de usar: ${widget.notification.appName}',
      body: widget.notification.message,
      hour: widget.notification.hour,
      minute: widget.notification.minute,
      payload: widget.notification.packageName,
      days: _selectedDays,
    );

    if (mounted) Navigator.pop(context, true); // Retorna 'true' para a Home atualizar a lista
  }

  Future<void> _deleteNotification() async {
    await NotificationService().cancelNotification(widget.notification.id!);
    await DBHelper().deleteNotification(widget.notification.id!);
    if (mounted) Navigator.pop(context, true);
  }

  // --- WIDGETS AUXILIARES (Reaproveitados da tela de adicionar) ---

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
                colorScheme: ColorScheme.dark(primary: grapeSoda, onPrimary: Colors.white, surface: spaceIndigo, onSurface: Colors.white),
              ),
              child: child!,
            );
          },
        );
        if (picked != null && picked != _selectedTime) {
          setState(() => _selectedTime = picked);
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
            Text(_selectedTime.format(context), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            Icon(Icons.access_time_rounded, color: grapeSoda, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField() {
    return TextField(
      controller: _messageController,
      style: const TextStyle(color: Colors.white),
      maxLines: 2,
      minLines: 1,
      decoration: InputDecoration(
        filled: true,
        fillColor: grafite.withOpacity(0.35),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildDaysSelector() {
    final daysOfWeek = [
      {'name': 'D', 'val': 7}, {'name': 'S', 'val': 1}, {'name': 'T', 'val': 2},
      {'name': 'Q', 'val': 3}, {'name': 'Q', 'val': 4}, {'name': 'S', 'val': 5}, {'name': 'S', 'val': 6},
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: isSelected ? grapeSoda : grafite.withOpacity(0.35), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(day['name'] as String, style: TextStyle(color: isSelected ? Colors.white : Colors.white.withOpacity(0.5), fontWeight: FontWeight.bold)),
          ),
        );
      }).toList(),
    );
  }
}