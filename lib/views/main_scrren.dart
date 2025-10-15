import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:zosign/controller/playlist_controller.dart';
import 'package:zosign/services/video_cache_service.dart';

int _selectedVideoIndex = 0;

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late VideoPlayerController _controller;
  final PlaylistController playlistController = Get.put(PlaylistController());
  bool isControllerInitialized = false;

  @override
  void initState() {
    super.initState();

    // گوش دادن به ریفرش نوتیف
    ever(playlistController.refreshTrigger, (shouldRefresh) async {
      if (shouldRefresh == true) {
        await _onNotificationReceived();
      }
    });

    playlistController.loadPlaylist().then((_) {
      if (playlistController.playlistList.isNotEmpty) {
        _playVideo(_selectedVideoIndex);
      }
    });
  }

  Future<void> _onNotificationReceived() async {
    final cache = VideoCacheService();
    await cache.clearCache();

    playlistController.playlistList.clear();
    await playlistController.loadPlaylist();

    if (playlistController.playlistList.isNotEmpty) {
      _selectedVideoIndex = 0;
      _playVideo(_selectedVideoIndex);
    } else {
      setState(() => isControllerInitialized = false);
    }
  }

  @override
  void dispose() {
    if (isControllerInitialized) _controller.dispose();
    super.dispose();
  }

  Future<void> _playVideo(int index) async {
    final playlist = playlistController.playlistList;
    if (playlist.isEmpty) return;

    final model = playlist[index];

    // 1️⃣ ویدیو فعلی: اگر کش هست استفاده کن، وگرنه دانلود کن و پخش کن
    File videoFile = await playlistController.downloadNextVideo(model);

    _controller = VideoPlayerController.file(videoFile);
    await _controller.initialize();
    setState(() => isControllerInitialized = true);
    _controller.play();

    // 2️⃣ پیش‌بارگذاری ویدیو بعدی
    final nextIndex = (index + 1) % playlist.length;
    final nextModel = playlist[nextIndex];
    if (!nextModel.url!.startsWith('/')) {
      // دانلود بعدی پشت‌صحنه بدون انتظار
      playlistController.downloadNextVideo(nextModel);
    }

    // 3️⃣ لیسنر اتمام ویدیو فعلی
    _controller.addListener(() async {
      if (!_controller.value.isInitialized) return;
      if (_controller.value.position >= _controller.value.duration) {
        _controller.pause();
        _controller.dispose();

        _selectedVideoIndex = nextIndex;
        _playVideo(nextIndex); // رفتن به ویدیوی بعدی
      }
    });
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
                  return const CircularProgressIndicator(color: Colors.white);
                }

                if (playlistController.playlistList.isEmpty) {
                  return const Text(
                    '🎬 No Video ',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
                  );
                }

                if (!isControllerInitialized) {
                  return const CircularProgressIndicator(color: Colors.white);
                }

                return AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                );
              }),
            ),

            // نوار دانلود
            Obx(() {
              if (playlistController.downloading.value) {
                return Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    value: playlistController.progress.value,
                    backgroundColor: Colors.transparent,
                    color: Colors.blueAccent,
                    minHeight: 3,
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }
            }),
          ],
        ),
      ),
    );
  }
}
