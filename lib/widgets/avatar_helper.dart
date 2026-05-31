import 'dart:io';
import 'package:flutter/material.dart';

Widget buildAvatarWidget({
  required String emoji,
  required String url,
  required String imagePath,
  required double size,
  required double emojiSize,
}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const LinearGradient(
        colors: [Color(0xFFC084FC), Color(0xFF818CF8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF7C3AED).withOpacity(0.2),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: ClipOval(
      child: Builder(
        builder: (context) {
          if (imagePath.isNotEmpty) {
            try {
              final file = File(imagePath);
              if (file.existsSync()) {
                return Image.file(
                  file,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildEmojiFallback(emoji, emojiSize);
                  },
                );
              }
            } catch (e) {
              debugPrint("Error loading avatar image file: $e");
            }
          }
          
          if (url.isNotEmpty) {
            return Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildEmojiFallback(emoji, emojiSize);
              },
            );
          }
          
          return _buildEmojiFallback(emoji, emojiSize);
        },
      ),
    ),
  );
}

Widget _buildEmojiFallback(String emoji, double emojiSize) {
  return Center(
    child: Text(
      emoji.isNotEmpty ? emoji : '👩‍🦰',
      style: TextStyle(fontSize: emojiSize),
    ),
  );
}
