import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final double size;
  final VoidCallback? onEditPressed;
  final bool showEditBadge;

  const UserAvatar({
    super.key,
    this.avatarUrl,
    required this.name,
    this.size = 90,
    this.onEditPressed,
    this.showEditBadge = false,
  });

  String get initials {
    if (name.trim().isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length > 1 && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  ImageProvider? _getImageProvider() {
    if (avatarUrl == null || avatarUrl!.trim().isEmpty) return null;
    final trimmed = avatarUrl!.trim();

    if (trimmed.startsWith('data:image') || trimmed.length > 200 && !trimmed.startsWith('http')) {
      try {
        final cleanBase64 = trimmed.contains(',') ? trimmed.split(',').last : trimmed;
        return MemoryImage(base64Decode(cleanBase64));
      } catch (_) {
        return null;
      }
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return NetworkImage(trimmed);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = _getImageProvider();

    Widget avatarContent = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: imageProvider == null ? AppColors.primaryGradient : null,
        color: imageProvider != null ? Colors.transparent : null,
        boxShadow: const [
          BoxShadow(
            color: Color(0x3D6366F1),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
        image: imageProvider != null
            ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
            : null,
      ),
      alignment: Alignment.center,
      child: imageProvider == null
          ? Text(
              initials,
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.38,
                fontWeight: FontWeight.w800,
              ),
            )
          : null,
    );

    if (!showEditBadge) {
      return avatarContent;
    }

    return Stack(
      children: [
        GestureDetector(
          onTap: onEditPressed,
          child: avatarContent,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: onEditPressed,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
