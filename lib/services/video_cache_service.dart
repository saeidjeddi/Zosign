import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class VideoCacheService {
  final Dio _dio = Dio();

  Future<String> getCachePath() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/videos';
    final folder = Directory(path);
    if (!await folder.exists()) await folder.create(recursive: true);
    return path;
  }

  Future<File?> getCachedFile(String fileName) async {
    final path = await getCachePath();
    final file = File('$path/$fileName.mp4');
    return await file.exists() ? file : null;
  }

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
}
