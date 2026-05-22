import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';

class BookImage extends StatelessWidget {
  final String imagePath;
  final String localImagePath;
  final double width;
  final double height;
  final double iconSize;

  const BookImage({
    super.key,
    required this.imagePath,
    this.localImagePath = '',
    this.width = 80,
    this.height = 110,
    this.iconSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: imagePath.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child:
                  localImagePath.isNotEmpty && File(localImagePath).existsSync()
                  ? Image.file(
                      File(localImagePath),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildNetworkImage(imagePath),
                    )
                  : _buildNetworkImage(imagePath),
            )
          : Icon(Icons.book, size: iconSize, color: Colors.grey),
    );
  }

  Widget _buildNetworkImage(String path) {
    return CachedNetworkImage(
      imageUrl: ApiService.getImageUrl(path),
      cacheKey: path,
      fit: BoxFit.cover,
      placeholder: (context, url) => const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) =>
          Icon(Icons.book, size: iconSize, color: Colors.grey),
    );
  }
}
