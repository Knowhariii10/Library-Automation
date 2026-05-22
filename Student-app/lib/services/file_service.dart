import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';

class FileService {
  static final FileService instance = FileService._init();
  FileService._init();

  Future<String?> downloadAndSaveImage(String url, String fileName) async {
    if (kIsWeb) return null;
    if (url.isEmpty) return null;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/book_images');

      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final filePath = path.join(imagesDir.path, fileName);
      final file = File(filePath);

      if (await file.exists()) {
        return filePath;
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        print('DEBUG: Saved image to $filePath');
        return filePath;
      }
    } catch (e) {
      print('DEBUG: Error downloading image: $e');
    }
    return null;
  }

  Future<String?> getLocalPath(String fileName) async {
    if (kIsWeb) return null;
    final directory = await getApplicationDocumentsDirectory();
    final filePath = path.join(directory.path, 'book_images', fileName);
    final file = File(filePath);
    if (await file.exists()) {
      return filePath;
    }
    return null;
  }
}
