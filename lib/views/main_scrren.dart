import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:zosign/controller/playlist_controller.dart';

int _selectedVideoIndex = 0;

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late VideoPlayerController _controller;
  final PlaylistController playlistController = PlaylistController();
  bool isControllerInitialized = false;

  @override
  void initState() {
    super.initState();
    playlistController.loadPlaylist().then((_) {
      if (playlistController.playlistList.isNotEmpty) {
        _playVideo(_selectedVideoIndex);
      }
    });
  }

  @override
  void dispose() {
    if (isControllerInitialized) _controller.dispose();
    super.dispose();
  }
void _playVideo(int index) async {
  final playlist = playlistController.playlistList;
  if (playlist.isEmpty) return;

  final model = playlist[index];
  File videoFile;

  if (model.url!.startsWith('/')) {
    videoFile = File(model.url!);
    _controller = VideoPlayerController.file(videoFile);
  } else {
    videoFile = await playlistController.downloadNextVideo(model);
    _controller = VideoPlayerController.file(videoFile);
  }

  await _controller.initialize();
  setState(() => isControllerInitialized = true);
  _controller.play();

  final nextIndex = (index + 1) % playlist.length; 
  final nextModel = playlist[nextIndex];
  if (!nextModel.url!.startsWith('/')) {
    playlistController.downloadNextVideo(nextModel);
  }

  _controller.addListener(() {
    if (!_controller.value.isInitialized) return;
    if (_controller.value.position >= _controller.value.duration) {
      _controller.pause();
      _controller.dispose();
      _selectedVideoIndex = nextIndex; 
      _playVideo(nextIndex);
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
                  return const CircularProgressIndicator();
                } else if (playlistController.playlistList.isEmpty) {
                  return const Text(
                    "No videos available",
                    style: TextStyle(color: Colors.white),
                  );
                } else if (!isControllerInitialized) {
                  return const CircularProgressIndicator();
                } else {
                  return AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  );
                }
              }),
            ),
            
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
