import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:zosign/controller/playlist_controller.dart';
import 'package:zosign/model/playlist_model.dart';
import 'package:zosign/services/webSocket_serveice.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late VideoPlayerController _controller;
  final PlaylistController playlistController = Get.find<PlaylistController>();
  bool isControllerInitialized = false;
  int _selectedVideoIndex = 0;
  bool _isVideoEnded = false;

  final List<Function()> _refreshQueue = [];
  bool _isProcessingQueue = false;
  Timer? _refreshDebounceTimer;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  void _initializeApp() async {
    // 📡 راه‌اندازی WebSocket
    if (Get.isRegistered<WebSocketService>()) {
      final ws = Get.find<WebSocketService>();
      ws.onMessage = (msg) async {
        print('🎧 WebSocket message received: $msg');
        _scheduleRefresh();
      };
    }

    // 🎬 بارگذاری اولیه پلی‌لیست
    await playlistController.loadPlaylist();
    if (playlistController.playlistList.isNotEmpty) {
      _playVideo(0);
    }

    // 🔥 گوش دادن به تغییرات پلی‌لیست
    ever(playlistController.playlistList, (List<PlaylistModel> newPlaylist) {
      print('📋 Playlist updated, current length: ${newPlaylist.length}');
      if (newPlaylist.isNotEmpty && !isControllerInitialized) {
        _selectedVideoIndex = 0;
        _playVideo(0);
      } else if (newPlaylist.isEmpty) {
        // اگر پلی‌لیست خالی شد
        setState(() {
          isControllerInitialized = false;
        });
      }
    });
  }

  void _scheduleRefresh() {
    _refreshDebounceTimer?.cancel();
    _refreshDebounceTimer = Timer(const Duration(seconds: 1), () {
      _enqueueRefresh();
    });
  }

  void _enqueueRefresh() {
    print('📥 Adding refresh to queue');
    _refreshQueue.add(_performRefresh);
    _processRefreshQueue();
  }

  void _processRefreshQueue() async {
    if (_isProcessingQueue || _refreshQueue.isEmpty) return;
    
    _isProcessingQueue = true;
    
    try {
      final task = _refreshQueue.removeAt(0);
      await task();
    } catch (e) {
      print('❌ Error processing refresh queue: $e');
    } finally {
      _isProcessingQueue = false;
      
      if (_refreshQueue.isNotEmpty) {
        _processRefreshQueue();
      }
    }
  }

  Future<void> _performRefresh() async {
    print('🔄 Performing refresh (clear cache + reload list)...');
    
    try {
      // ویدیوی فعلی رو متوقف کن
      if (isControllerInitialized) {
        await _controller.pause();
        await _controller.dispose();
        setState(() {
          isControllerInitialized = false;
        });
      }

      // کش رو پاک کن و لیست رو دوباره بارگذاری کن
      await playlistController.clearCacheWithoutDownload();
      
      print('✅ Refresh completed - cache cleared, list reloaded');
      
      // اگر ویدیویی موجود هست، از اول پلی‌لیست شروع کن
      if (playlistController.playlistList.isNotEmpty) {
        _selectedVideoIndex = 0;
        _playVideo(0);
      }
    } catch (e) {
      print('❌ Error during refresh: $e');
    }
  }

  @override
  void dispose() {
    _refreshDebounceTimer?.cancel();
    if (isControllerInitialized) _controller.dispose();
    super.dispose();
  }

  // 🔥 پخش ویدیو با قابلیت لوپ بی‌نهایت
  Future<void> _playVideo(int index) async {
    final playlist = playlistController.playlistList;
    if (playlist.isEmpty) {
      print('❌ Playlist is empty, cannot play video');
      return;
    }

    // 🔥 اطمینان از اینکه ایندکس در محدوده معتبر باشد
    final safeIndex = index % playlist.length;
    final model = playlist[safeIndex];
    
    print('🎬 Preparing to play video: ${model.title} (Index: $safeIndex/${playlist.length})');

    try {
      // ویدیو رو دانلود کن یا از کش بگیر
      File? videoFile = await playlistController.getVideoFile(model);
      
      if (videoFile == null) {
        print('❌ Video file not available: ${model.title}');
        // اگر ویدیو دانلود نشد، به ویدیوی بعدی برو
        _playNextVideo(safeIndex);
        return;
      }

      // Dispose ویدیو قبلی
      if (isControllerInitialized) {
        await _controller.pause();
        await _controller.dispose();
      }

      _controller = VideoPlayerController.file(videoFile);
      await _controller.initialize();
      
      setState(() {
        isControllerInitialized = true;
        _isVideoEnded = false;
      });
      
      _controller.play();
      print('✅ Video started playing: ${model.title}');

      // 🔥 لیسنر پایان ویدیو برای لوپ
      _controller.addListener(() async {
        if (!_controller.value.isInitialized || _isVideoEnded) return;
        
        // اگر ویدیو به پایان رسید
        if (_controller.value.position >= _controller.value.duration - const Duration(milliseconds: 100)) {
          print('⏭️ Video ended, playing next in loop...');
          _isVideoEnded = true;
          
          await _controller.pause();
          await _controller.dispose();
          
          setState(() {
            isControllerInitialized = false;
          });
          
          // 🔥 به ویدیوی بعدی برو (با لوپ)
          _playNextVideo(safeIndex);
        }
      });
    } catch (e) {
      print('❌ Error playing video: $e');
      setState(() {
        isControllerInitialized = false;
      });
      // در صورت خطا به ویدیوی بعدی برو
      _playNextVideo(index);
    }
  }

  // 🔥 پخش ویدیوی بعدی با قابلیت لوپ
  void _playNextVideo(int currentIndex) {
    final playlist = playlistController.playlistList;
    if (playlist.isEmpty) return;

    // 🔥 محاسبه ایندکس بعدی با لوپ
    final nextIndex = (currentIndex + 1) % playlist.length;
    _selectedVideoIndex = nextIndex;
    
    print('🔁 Moving to next video: $nextIndex/${playlist.length}');
    _playVideo(nextIndex);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: Obx(() {
                if (playlistController.loading.value) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 16),
                      Text(
                        'Loading playlist...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  );
                }

                if (playlistController.playlistList.isEmpty) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.videocam_off, size: 64, color: Colors.white54),
                      const SizedBox(height: 16),
                      const Text(
                        'No Videos Available',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                    ],
                  );
                }

                if (!isControllerInitialized) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 16),
                      Text(
                        'Loading video...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  );
                }

                return AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                );
              }),
            ),

            // 📶 نوار پیشرفت دانلود
            Obx(() {
              if (playlistController.downloading.value) {
                return Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      LinearProgressIndicator(
                        value: playlistController.progress.value,
                        backgroundColor: Colors.transparent,
                        color: Colors.blueAccent,
                        minHeight: 3,
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),

            // 🔥 نمایش شماره ویدیوی فعلی
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Obx(() => Text(
                  '${_selectedVideoIndex + 1}/${playlistController.playlistList.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}