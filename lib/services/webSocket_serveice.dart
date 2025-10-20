import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:zosign/components/url.dart';
import 'package:zosign/controller/playlist_controller.dart';
import 'package:zosign/services/video_cache_service.dart';

class WebSocketService {
  // --- Singleton ---
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  // --- Fields ---
  final String url = UrlPlaylist.webSocketUrl;
  WebSocket? _socket;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  bool _isConnecting = false;
  Function(String message)? onMessage;

  // --- Public Getters ---
  bool get isConnected => _socket?.readyState == WebSocket.open;

  // --- Main connect ---
  Future<void> connect({Function(String)? onMessage}) async {
    this.onMessage = onMessage;

    if (_isConnecting || isConnected) {
      print('🔁 WebSocket already connected or connecting...');
      return;
    }

    _isConnecting = true;
    print('🔗 Connecting to WebSocket: $url');

    try {
      _socket = await WebSocket.connect(url);
      print('✅ WebSocket connected successfully: $url');
      _isConnecting = false;

      _listenSocket();
      _startHeartbeat();
      _watchNetworkStatus();

    } catch (e) {
      print('⚠️ WebSocket connection failed: $e');
      _isConnecting = false;
      _scheduleReconnect();
    }
  }

  // --- Listen for messages / errors ---
  void _listenSocket() {
    _socket?.listen(
      (data) async {
        print('💬 WebSocket message received: $data');
        if (onMessage != null) onMessage!(data);
        await _handleCacheClear();
      },
      onError: (e) {
        print('❌ WebSocket error: $e');
        _scheduleReconnect();
      },
      onDone: () {
        print('🔚 WebSocket connection closed by server');
        _scheduleReconnect();
      },
      cancelOnError: false,
    );
  }

  // --- Heartbeat system ---
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (isConnected) {
        try {
          _socket!.add('ping');
          print('💓 WebSocket heartbeat sent');
        } catch (e) {
          print('💔 Heartbeat failed, reconnecting...');
          _scheduleReconnect();
        }
      }
    });
  }

  // --- Network watcher (compatible with connectivity_plus v6+) ---
  void _watchNetworkStatus() {
  _connectivitySub ??= Connectivity().onConnectivityChanged.listen((results) async {
    final status = results.isNotEmpty ? results.first : ConnectivityResult.none;

    if (status == ConnectivityResult.none) {
      // اینترنت قطع شد 👇
      print('📴 Internet lost, closing WebSocket...');
      _heartbeatTimer?.cancel();
      _reconnectTimer?.cancel();

      if (_socket != null) {
        try {
          await _socket!.close();
          print('🔒 WebSocket closed due to network loss');
        } catch (_) {}
      }

      _socket = null;
      _isConnecting = false;

    } else {
      // اینترنت برگشت 👇
      print('🌐 Internet restored, reconnecting WebSocket...');
      await Future.delayed(const Duration(seconds: 2)); // یه تاخیر کوچیک برای پایداری شبکه

      if (!isConnected && !_isConnecting) {
        await connect(onMessage: onMessage);
      }

      // حالا پلی‌لیست رو از نو بگیر
      if (Get.isRegistered<PlaylistController>()) {
        final playlistController = Get.find<PlaylistController>();
        await playlistController.forceRefresh();
        print('🔁 Playlist refreshed after internet reconnect');
      }
    }
  });
}

  // --- Reconnect logic ---
  void _scheduleReconnect() {
    if (_reconnectTimer?.isActive ?? false) return;
    if (_isConnecting) return;

    _reconnectTimer = Timer(const Duration(seconds: 5), () async {
      if (!isConnected) {
        print('🔄 Attempting to reconnect WebSocket...');
        await connect(onMessage: onMessage);
      }
    });
  }

  // --- Handle clear cache ---
Future<void> _handleCacheClear() async {
  try {
    print('🧹 WebSocket: Starting cache clearance...');

    final box = GetStorage();
    await box.erase();
    print('🗑️ GetStorage cleared.');

    final cache = VideoCacheService();
    await cache.clearCache();
    print('🗑️ Video cache cleared.');

    // اگه PlaylistController هنوز آماده نیست، صبر کن تا رجیستر بشه
    int retry = 0;
    while (!Get.isRegistered<PlaylistController>() && retry < 2) {
      print('⏳ Waiting for PlaylistController to be ready...');
      await Future.delayed(const Duration(milliseconds: 300));
      retry++;
    }

    if (Get.isRegistered<PlaylistController>()) {
      final playlistController = Get.find<PlaylistController>();
      await playlistController.forceRefresh();
      print('✅ Playlist refreshed after WebSocket cache clear');
    } else {
      print('⚠️ PlaylistController not available, skipping refresh.');
    }

    print('🎯 WebSocket cache clearance completed successfully');
  } catch (e) {
    print('⚠️ Error during WebSocket cache clearance: $e');
  }
}

  // --- Send data ---
  void send(String msg) {
    if (isConnected) {
      _socket!.add(msg);
      print('📤 WebSocket message sent: $msg');
    } else {
      print('⚠️ Cannot send, WebSocket not connected');
    }
  }

  // --- Manual close ---
  void closeManually() {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _connectivitySub?.cancel();
    _connectivitySub = null;

    _socket?.close();
    _socket = null;

    print('🔒 WebSocket closed manually');
  }
}
