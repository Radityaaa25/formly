import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'glass_card.dart';

enum ChatSender { user, ai }

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.from, required this.text});

  final ChatSender from;
  final String text;

  @override
  Widget build(BuildContext context) {
    final isUser = from == ChatSender.user;
    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isUser
            ? AppColors.primary
            : Colors.white.withValues(alpha: 0.68),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(22),
          topRight: const Radius.circular(22),
          bottomLeft: Radius.circular(isUser ? 22 : 6),
          bottomRight: Radius.circular(isUser ? 6 : 22),
        ),
        border: Border.all(
          color: isUser
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.75),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isUser ? Colors.white : AppColors.foreground,
          fontSize: 15,
          height: 1.5,
        ),
      ),
    );

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 240),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 8),
          child: child,
        ),
      ),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: isUser
            ? bubble
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.primaryLight, AppColors.primary],
                      ),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(child: bubble),
                ],
              ),
      ),
    );
  }
}

class TypingBubble extends StatelessWidget {
  const TypingBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: GlassCard(
        radius: 22,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          'Pelatih sedang mengetik...',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.mutedForeground,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}
