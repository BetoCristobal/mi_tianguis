import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AppImageView extends StatelessWidget {
  const AppImageView({
    required this.imagePath,
    required this.fallback,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholderColor = const Color(0xFFE8D9C8),
    this.progressSize = 28,
    super.key,
  });

  final String imagePath;
  final Widget fallback;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color placeholderColor;
  final double progressSize;

  @override
  Widget build(BuildContext context) {
    final trimmed = imagePath.trim();
    if (trimmed.isEmpty) {
      return fallback;
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: trimmed,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => Container(
          width: width,
          height: height,
          color: placeholderColor,
          child: Center(
            child: SizedBox(
              width: progressSize,
              height: progressSize,
              child: const CircularProgressIndicator(),
            ),
          ),
        ),
        errorWidget: (context, url, error) => fallback,
      );
    }

    if (trimmed.startsWith('assets/')) {
      return Image.asset(
        trimmed,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    }

    final file = File(trimmed);
    if (file.existsSync()) {
      return Image.file(
        file,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    }

    return fallback;
  }
}
