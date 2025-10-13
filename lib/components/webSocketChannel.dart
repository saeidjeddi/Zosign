import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:zosign/components/url.dart';




final channel = WebSocketChannel.connect(
  Uri.parse(UrlPlaylist.webSocketChannelUrlConst),
);