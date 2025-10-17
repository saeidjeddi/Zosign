class UrlPlaylist {
  static const String baseUrl = "http://192.168.5.234/";
  static const String playlist = "${baseUrl}videos/playlist/?format=json";
  static const String fcmPostEndpoint = "${baseUrl}api/token/";
  static const String webSocketUrl = "ws://192.168.5.234/ws/notifications/";
}