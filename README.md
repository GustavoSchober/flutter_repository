# flutter_repository

# notify_me

A new Flutter project.

## Getting Started
# Notify Me 📱🔔

Um aplicativo Flutter que permite agendar notificações personalizadas para abrir outros aplicativos instalados no seu dispositivo Android.

## Sobre o Projeto

Notify Me é um app simples e intuitivo que possibilita ao usuário:
- Escolher um aplicativo dentre os instalados no dispositivo;
- Escrever uma mensagem personalizada;
- Selecionar uma data e hora para receber uma notificação.

No horário definido, uma notificação é exibida no sistema. Ao clicar nela, o aplicativo escolhido é aberto automaticamente.

Este projeto foi desenvolvido como um MVP (Produto Mínimo Viável) para demonstrar a integração de notificações locais agendadas com Flutter, incluindo:
- Agendamento exato com suporte a fusos horários;
- Notificações diárias recorrentes;
- Persistência dos lembretes em banco de dados SQLite;
- Abertura de apps externos via package name.

## ✨ Funcionalidades

- 📋 **Lista de aplicativos**: exibe todos os apps instalados no dispositivo (requer permissão `QUERY_ALL_PACKAGES`).
- ✏️ **Personalização**: defina uma mensagem e o horário (hora e minuto) para a notificação.
- 🔔 **Notificações precisas**: utiliza alarmes exatos (`SCHEDULE_EXACT_ALARM`) para garantir que a notificação dispare mesmo com economia de bateria.
- 🔁 **Repetição diária**: a notificação se repete todos os dias no mesmo horário.
- 👆 **Ação ao toque**: ao clicar na notificação, o app selecionado é aberto.
- 💾 **Persistência local**: os lembretes são salvos em SQLite, permitindo gerenciamento futuro.

🛠️ Tecnologias Utilizadas

- [Flutter](https://flutter.dev/)
- [Dart](https://dart.dev/)
