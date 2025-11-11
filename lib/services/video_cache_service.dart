import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';


/// 🗃️ سرویس مدیریت کش و دانلود ویدیوها
class VideoCacheService {
  final Dio _dio = Dio();

/// 📁 دریافت مسیر کش ویدیوها
  Future<String> getCachePath() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/videos';
    final folder = Directory(path);
    if (!await folder.exists()) await folder.create(recursive: true);
    return path;
  }


/// 📦 دریافت فایل کش شده اگر وجود داشته باشد
  Future<File?> getCachedFile(String fileName) async {
    final path = await getCachePath();
    final file = File('$path/$fileName.mp4');
    return await file.exists() ? file : null;
  }

/// ⬇️ دانلود ویدیو و ذخیره در کش
  Future<File> downloadVideo(
    String url,
    String fileName, {
    Function(int, int)? onProgress,
  }) async {
    final path = await getCachePath();
    final savePath = '$path/$fileName.mp4';

    await _dio.download(
      url,
      savePath,
      onReceiveProgress: onProgress,
    );

    return File(savePath);
  }

/// 🧹 پاک‌سازی کش ویدیوها
  Future<void> clearCache() async {
    final path = await getCachePath();
    final dir = Directory(path);
    if (await dir.exists()) {
      await for (var entity in dir.list()) {
        if (entity is File) await entity.delete();
      }
    }
    print('🧹 Cache cleared successfully');
  }
}
