import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/env.dart';
import '../../core/router/app_router.dart';
import '../../core/services/ai_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/chat_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const _answers = {
    'Kenapa lutut saya terasa tegang?': 'Biasanya karena lutut maju melewati ujung kaki atau berat badan bertumpu di depan. Coba dorong pinggul ke belakang dan tekan lewat tumit. Kalau nyeri tajam, berhenti dulu ya.',
    'Gerakan pengganti squat?': 'Coba Glute Bridge atau Wall Sit. Keduanya melatih otot yang sama dengan tekanan lebih ringan di lutut.',
    'Berapa lama istirahat antar set?':
        'Untuk latihan ringan, 45-90 detik sudah cukup. Dengarkan tubuhmu.',
  };

  final List<({ChatSender from, String text})> _messages = [
    (
      from: ChatSender.ai,
      text: 'Halo Raka! Ada yang mau ditanyakan soal latihanmu hari ini?',
    ),
  ];
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _typing = false;
  bool _listening = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _messages.add((from: ChatSender.user, text: trimmed));
      _typing = true;
      _listening = false;
    });
    _input.clear();
    _scrollToBottom();

    final history = _messages
        .take(_messages.length - 1)
        .map(
          (m) =>
              (sender: m.from == ChatSender.user ? 'user' : 'ai', text: m.text),
        )
        .toList();

    final reply = await AiService.askCoach(trimmed, history: history);

    if (!mounted) return;
    setState(() {
      _typing = false;
      _messages.add((from: ChatSender.ai, text: reply));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    _CircleIconButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => context.go(AppRoutes.home),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Tanya Pelatih',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (!Env.hasSupabase)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.cloud_off_rounded,
                        size: 16,
                        color: AppColors.warning,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'AI online belum aktif. Isi assets/config/env.json lalu build ulang.',
                          style: TextStyle(
                            fontSize: 11.5,
                            height: 1.3,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  itemCount: _messages.length + (_typing ? 1 : 0),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index >= _messages.length) {
                      return const TypingBubble();
                    }
                    final message = _messages[index];
                    return ChatBubble(from: message.from, text: message.text);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Column(
                  children: [
                    SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _answers.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final question = _answers.keys.elementAt(index);
                          return AppChip(
                            label: question,
                            onTap: () => _send(question),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 6, 6, 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.68),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.10),
                            blurRadius: 22,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _input,
                              onSubmitted: _send,
                              style: const TextStyle(fontSize: 15.5),
                              decoration: InputDecoration(
                                hintText: _listening
                                    ? 'Mendengarkan...'
                                    : 'Tulis pertanyaan',
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                setState(() => _listening = !_listening),
                            icon: Icon(
                              Icons.mic_rounded,
                              color: _listening
                                  ? Colors.white
                                  : AppColors.primary,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: _listening
                                  ? AppColors.primary
                                  : Colors.transparent,
                            ),
                          ),
                          const SizedBox(width: 2),
                          IconButton(
                            onPressed: () => _send(_input.text),
                            icon: const Icon(Icons.send_rounded, size: 20),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Bukan pengganti nasihat medis',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mutedForeground,
                      ),
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

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.66),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
          ),
          child: Icon(icon, size: 20),
        ),
      ),
    );
  }
}
