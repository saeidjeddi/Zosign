import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:zosign/components/url.dart';
import 'package:zosign/model/playlist_model.dart';
import 'package:zosign/services/dio_service.dart';
import 'package:zosign/services/video_cache_service.dart';

class PlaylistController extends GetxController {
  RxBool loading = false.obs;
  RxBool downloading = false.obs;
  RxDouble progress = 0.0.obs;
  RxList<PlaylistModel> playlistList = <PlaylistModel>[].obs;

  RxBool refreshTrigger = false.obs; // ✅ برای ریفرش از نوتیف
  final VideoCacheService cacheService = VideoCacheService();

  Future<bool> hasConnection() async {
    final conn = await Connectivity().checkConnectivity();
    return conn != ConnectivityResult.none;
  }

  Future<void> loadPlaylist() async {
    loading.value = true;
    playlistList.clear();

    bool online = await hasConnection();

    if (online) {
      final response = await DioServices().getMethod(UrlPlaylist.playlist);
      if (response != null && response.statusCode == 200) {
        for (var item in response.data) {
          final model = PlaylistModel.fromJson(item);
          playlistList.add(model);
        }
      }
    } else {
      final cachePath = await cacheService.getCachePath();
      final cachedFiles = Directory(cachePath)
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.mp4'));

      for (var f in cachedFiles) {
        playlistList.add(
          PlaylistModel(
            title: f.uri.pathSegments.last,
            filename: f.uri.pathSegments.last,
            url: f.path,
            contentType: "video/mp4",
          ),
        );
      }
    }

    loading.value = false;
  }

  Future<File> downloadNextVideo(PlaylistModel model) async {
    final cached = await cacheService.getCachedFile(model.filename!);
    if (cached != null) return cached;

    downloading.value = true;
    progress.value = 0.0;

    final file = await cacheService.downloadVideo(
      model.url!,
      model.filename!,
      onProgress: (received, total) {
        if (total != -1) progress.value = received / total;
      },
    );

    downloading.value = false;
    return file;
  }

  Future<void> clearCache() async {
    final dir = Directory(await cacheService.getCachePath());
    if (await dir.exists()) {
      await for (var entity in dir.list()) {
        if (entity is File) await entity.delete();
      }
    }
    print('🧹 Cache cleared successfully');
  }
}
