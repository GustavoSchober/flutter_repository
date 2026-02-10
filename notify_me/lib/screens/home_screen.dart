import 'package:flutter/material.dart';
import 'package:notify_me/screens/add_notification_screen.dart';
import '../models/notification_model.dart'; // Import do Modelo
import '../database/db_helper.dart';       // Import do Banco
import '../widgets/app_icon_widget.dart';  // <--- Import do Widget de Ícone que criamos

class NotificationHomeScreen extends StatefulWidget {
  const NotificationHomeScreen({super.key});

  @override
  State<NotificationHomeScreen> createState() => _NotificationHomeScreenState();
}

class _NotificationHomeScreenState extends State<NotificationHomeScreen> {
  // Cores do Tema
  final Color spaceIndigo = const Color(0xFF000033);
  final Color grapeSoda = const Color(0xFFea2f59);
  final Color amethystSmoke = const Color(0xFFA675A1);
  final Color grafite = const Color(0xFF466365);

  // Função para carregar as notificações do Banco
  Future<List<NotificationModel>> _fetchNotifications() async {
    return await DBHelper().getNotifications();
  }

  // Função para deletar
  void _deleteNotification(int id) async {
    await DBHelper().deleteNotification(id);
    setState(() {}); // Recarrega a tela para sumir o item
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: spaceIndigo,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Minhas Notificações', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_sweep_outlined, color: amethystSmoke), 
            onPressed: () {
              // Futuro: Implementar "Limpar Tudo"
            }
          ),
        ],
      ),
      
      body: Column(
        children: [
          const SizedBox(height: 20),
          
          // --- LISTA DO BANCO DE DADOS ---
          Expanded(
            child: FutureBuilder<List<NotificationModel>>(
              future: _fetchNotifications(), // Busca os dados do SQL
              builder: (context, snapshot) {
                // 1. Carregando...
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: grapeSoda));
                }
                
                // 2. Se der erro ou lista vazia
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                // 3. Sucesso! Mostra a lista
                final notifications = snapshot.data!;
                
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: notifications.length, 
                  itemBuilder: (context, index) {
                    final item = notifications[index];
                    return _buildNotificationCard(item);
                  },
                );
              },
            ),
          ),
        ],
      ),
      
      // Botão Flutuante (+) com animação
      floatingActionButton: FloatingActionButton(
        backgroundColor: grapeSoda,
        onPressed: () async {
          // Navega e ESPERA (await) o resultado
          final result = await Navigator.of(context).push(
            PageRouteBuilder(
              opaque: false,
              barrierColor: Colors.black.withOpacity(0.55),
              barrierDismissible: true,
              transitionDuration: const Duration(milliseconds: 500),
              reverseTransitionDuration: const Duration(milliseconds: 400),
              pageBuilder: (context, animation, secondaryAnimation) => const AddNotificationScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeOutCubic;
                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                return SlideTransition(position: animation.drive(tween), child: child);
              },
            ),
          );

          // Se salvou algo novo, atualiza a lista
          if (result == true) {
            setState(() {});
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Tela de "Nada por aqui"
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: amethystSmoke.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'Tudo limpo por aqui!',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 18),
          ),
          Text(
            'Toque no + para criar um lembrete',
            style: TextStyle(color: amethystSmoke, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // O CARD DE NOTIFICAÇÃO (Aqui está a mágica do ícone)
  Widget _buildNotificationCard(NotificationModel item) {
    return Dismissible(
      key: Key(item.id.toString()), // Chave única para o arraste funcionar
      background: Container(
        color: Colors.red.withOpacity(0.8),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart, // Só arrasta da direita pra esquerda
      onDismissed: (direction) {
        if (item.id != null) _deleteNotification(item.id!);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: grafite.withOpacity(0.25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center, 
            children: [
              
              AppIconWidget(packageName: item.packageName),

              const SizedBox(width: 16),
              
              // Textos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Nome do App (Ex: Airbnb)
                        Text(
                          item.appName, 
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        // Horário
                        Text(
                          "${item.hour.toString().padLeft(2, '0')}:${item.minute.toString().padLeft(2, '0')}",
                          style: TextStyle(color: amethystSmoke, fontSize: 12)
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Mensagem
                    Text(
                      item.message,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.7), fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}