import 'dart:io';
import 'dart:async';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import 'package:zosign/components/url.dart';
import 'package:zosign/services/video_cache_service.dart';
import 'package:zosign/controller/playlist_controller.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;

  WebSocketService._internal();

  final String url = UrlPlaylist.webSocketUrl;
  WebSocket? _socket;
  Timer? _reconnectTimer;
  bool _isConnecting = false;
  Function(String message)? onMessage;

  Future<void> connect({Function(String)? onMessage}) async {
    this.onMessage = onMessage;

    if (_isConnecting || _socket?.readyState == WebSocket.open) {
      print('🔁 WebSocket already connected or connecting...');
      return;
    }

    _isConnecting = true;

    print('🔗 Connecting to WebSocket: $url');

    try {
      _socket = await WebSocket.connect(url);
      print('✅ WebSocket connected successfully: $url');
      _isConnecting = false;

      _socket!.listen(
        (data) async {
          print('💬 WebSocket message received: $data');
          if (onMessage != null) onMessage(data);
          await _handleCacheClear();
        },
        onError: (e) {
          print('❌ WebSocket error: $e');
          _reconnect();
        },
        onDone: () {
          print('🔚 WebSocket connection closed by server');
          _reconnect();
        },
        cancelOnError: false,
      );
    } catch (e) {
      print('⚠️ WebSocket connection failed: $e');
      _isConnecting = false;
      _reconnect();
    }
  }

  void _reconnect() {
    if (_reconnectTimer?.isActive ?? false) return;

    _reconnectTimer = Timer(const Duration(seconds: 5), () async {
      print('🔄 Attempting to reconnect WebSocket...');
      await connect(onMessage: onMessage);
    });
  }

  /// 🧹 پاک‌کردن کش ویدیو و GetStorage + ریفرش پلی‌لیست
  Future<void> _handleCacheClear() async {
    try {
      print('🧹 WebSocket: Starting cache clearance...');
      
      final box = GetStorage();
      print('🗑️ Clearing GetStorage...');
      await box.erase();
      
      final cache = VideoCacheService();
      print('🗑️ Clearing video cache...');
      await cache.clearCache();
      
      // 🔥 ریفرش پلی‌لیست با متد جدید
      if (Get.isRegistered<PlaylistController>()) {
        final playlistController = Get.find<PlaylistController>();
        await playlistController.forceRefresh();
        print('✅ Playlist refreshed after WebSocket cache clear');
      }
      
      print('🎯 WebSocket cache clearance completed successfully');
    } catch (e) {
      print('⚠️ Error during WebSocket cache clearance: $e');
    }
  }

  void send(String msg) {
    if (_socket?.readyState == WebSocket.open) {
      _socket!.add(msg);
      print('📤 WebSocket message sent: $msg');
    } else {
      print('⚠️ Cannot send, WebSocket not connected');
    }
  }

  void closeManually() {
    _reconnectTimer?.cancel();
    _socket?.close();
    _socket = null;
    print('🔒 WebSocket closed manually');
  }

  // وضعیت اتصال رو چک کن
  bool get isConnected => _socket?.readyState == WebSocket.open;
}