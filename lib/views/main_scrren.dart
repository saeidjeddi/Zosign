import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:get/get.dart';
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
  bool isControllersVisible = true;
  final iconColor = Colors.white;

  @override
  void initState() {
    super.initState();
    playlistController.getPlayList().then((_) {
      if (playlistController.playlistList.isNotEmpty) {
        _initializeVideo(_selectedVideoIndex);
      }
    });
  }

  @override
  void dispose() {
    if (isControllerInitialized) _controller.dispose();
    super.dispose();
  }

  void _initializeVideo(int index) {
    final playlist = playlistController.playlistList;
    if (playlist.isEmpty) return;

    _controller = VideoPlayerController.networkUrl(
      Uri.parse(playlist[index].url!),
    );

    _controller.addListener(() {
      if (!mounted) return;
      setState(() {});
      if (_controller.value.isInitialized &&
          !_controller.value.isPlaying &&
          (_controller.value.position >= _controller.value.duration)) {
        onChangeVideo(_selectedVideoIndex + 1);
      }
    });

    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() => isControllerInitialized = true);
      _controller.play();
    });
  }

  void onChangeVideo(int index) {
    final playlist = playlistController.playlistList;
    if (playlist.isEmpty) return;

    if (_controller.value.isInitialized) {
      _controller.pause();
      _controller.dispose();
    }

    _selectedVideoIndex = index % playlist.length;
    if (_selectedVideoIndex < 0) {
      _selectedVideoIndex = playlist.length - 1;
    }

    _initializeVideo(_selectedVideoIndex);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
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
              return GestureDetector(
                onTap: () => setState(
                    () => isControllersVisible = !isControllersVisible),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                    if (isControllersVisible)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: () async {
                                    final pos = await _controller.position;
                                    if (pos != null) {
                                      final target =
                                          pos - const Duration(seconds: 10);
                                      await _controller.seekTo(target > Duration.zero
                                          ? target
                                          : Duration.zero);
                                    }
                                  },
                                  icon: Icon(Icons.fast_rewind_rounded,
                                      color: iconColor),
                                ),
                                IconButton(
                                  onPressed: () {
                                    onChangeVideo(_selectedVideoIndex - 1);
                                  },
                                  icon: Icon(Icons.skip_previous_rounded,
                                      color: iconColor),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    _controller.value.isPlaying
                                        ? await _controller.pause()
                                        : await _controller.play();
                                    setState(() {});
                                  },
                                  icon: Icon(
                                    _controller.value.isPlaying
                                        ? Icons.pause_circle_filled_rounded
                                        : Icons.play_circle_fill_rounded,
                                    color: iconColor,
                                    size: 45,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    onChangeVideo(_selectedVideoIndex + 1);
                                  },
                                  icon: Icon(Icons.skip_next_rounded,
                                      color: iconColor),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    final pos = await _controller.position;
                                    if (pos != null) {
                                      final target =
                                          pos + const Duration(seconds: 10);
                                      await _controller.seekTo(
                                          target < _controller.value.duration
                                              ? target
                                              : _controller.value.duration);
                                    }
                                  },
                                  icon: Icon(Icons.fast_forward_rounded,
                                      color: iconColor),
                                ),
                              ],
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(
                                        _controller.value.position),
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 12),
                                  ),
                                  Text(
                                    _formatDuration(
                                        _controller.value.duration),
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 15,
                              width: double.infinity,
                              child: VideoProgressIndicator(
                                
                                _controller,
                                allowScrubbing: true,
                                colors: const VideoProgressColors(
                                  playedColor: Colors.red,
                                  backgroundColor: Colors.grey,
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 4.0),
                              ),
                            ),

                            const SizedBox(height: 16.0),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            }
          }),
        ),
      ),
    );
  }
}