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

  final VideoCacheService cacheService = VideoCacheService();
  
  bool _isRefreshing = false;
  DateTime? _lastRefreshTime;

  Future<bool> hasConnection() async {
    final conn = await Connectivity().checkConnectivity();
    return conn != ConnectivityResult.none;
  }

  Future<void> loadPlaylist({bool forceRefresh = false}) async {
    if (_isRefreshing) {
      print('⏳ Refresh already in progress, skipping...');
      return;
    }

    final now = DateTime.now();
    if (_lastRefreshTime != null && 
        now.difference(_lastRefreshTime!).inSeconds < 2 && 
        !forceRefresh) {
      print('⏰ Too soon to refresh, skipping...');
      return;
    }

    _isRefreshing = true;
    loading.value = true;

    try {
      bool online = await hasConnection();
      final List<PlaylistModel> newPlaylist = [];

      if (online) {
        print('🌐 Loading playlist from server...');
        final response = await DioServices().getMethod(UrlPlaylist.playlist);
        
        if (response != null && response.statusCode == 200) {
          for (var item in response.data) {
            final model = PlaylistModel.fromJson(item);
            newPlaylist.add(model);
          }
          
          if (_hasPlaylistChanged(newPlaylist)) {
            print('🔄 Playlist changed, updating...');
            playlistList.assignAll(newPlaylist);
          } else {
            print('ℹ️ Playlist unchanged, skipping update');
          }
        }
      } else {
        print('📱 Loading playlist from cache...');
        final cachePath = await cacheService.getCachePath();
        final cachedFiles = Directory(cachePath)
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.mp4'));

        for (var f in cachedFiles) {
          newPlaylist.add(
            PlaylistModel(
              title: f.uri.pathSegments.last,
              filename: f.uri.pathSegments.last,
              url: f.path,
              contentType: "video/mp4",
            ),
          );
        }
        
        if (_hasPlaylistChanged(newPlaylist)) {
          playlistList.assignAll(newPlaylist);
        }
      }

      _lastRefreshTime = DateTime.now();
      
    } catch (e) {
      print('❌ Error loading playlist: $e');
    } finally {
      loading.value = false;
      _isRefreshing = false;
    }
  }

  bool _hasPlaylistChanged(List<PlaylistModel> newPlaylist) {
    if (playlistList.length != newPlaylist.length) return true;
    
    for (int i = 0; i < playlistList.length; i++) {
      if (playlistList[i].filename != newPlaylist[i].filename ||
          playlistList[i].url != newPlaylist[i].url) {
        return true;
      }
    }
    
    return false;
  }

  Future<void> forceRefresh() async {
    print('🔥 Force refreshing playlist...');
    await loadPlaylist(forceRefresh: true);
  }

  // 🔥 فقط وقتی ویدیو نیاز هست دانلود کن (نه خودکار)
  Future<File?> getVideoFile(PlaylistModel model) async {
    // اول بررسی کن آیا از قبل در کش هست
    final cached = await cacheService.getCachedFile(model.filename!);
    if (cached != null) {
      print('📦 Using cached video: ${model.filename}');
      return cached;
    }

    // اگر آنلاین هستیم، دانلود کن
    bool online = await hasConnection();
    if (online) {
      print('⬇️ Downloading video: ${model.filename}');
      downloading.value = true;
      progress.value = 0.0;

      try {
        final file = await cacheService.downloadVideo(
          model.url!,
          model.filename!,
          onProgress: (received, total) {
            if (total != -1) progress.value = received / total;
          },
        );

        downloading.value = false;
        return file;
      } catch (e) {
        downloading.value = false;
        print('❌ Error downloading video: $e');
        return null;
      }
    } else {
      print('❌ No internet and video not cached: ${model.filename}');
      return null;
    }
  }

  // 🔥 فقط کش رو پاک کن بدون دانلود خودکار
  Future<void> clearCacheWithoutDownload() async {
    print('🧹 Clearing cache without auto-download...');
    final dir = Directory(await cacheService.getCachePath());
    if (await dir.exists()) {
      await for (var entity in dir.list()) {
        if (entity is File) await entity.delete();
      }
    }
    print('✅ Cache cleared successfully');
    
    // پلی‌لیست رو مجدداً بارگذاری کن (بدون دانلود خودکار)
    await forceRefresh();
  }
}