import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';
import 'package:zosign/components/url.dart';

Future<void> sendTokenToServer(String token) async {
  final dio = Dio();
  final box = GetStorage();

  final String apiUrl = UrlPlaylist.fcmPostEndpoint;
  final fcmToken = box.read('fcm_token') ?? token;

  try {
    final response = await dio.post(
      apiUrl,
      data: {'token': fcmToken},
      options: Options(
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('✅ Token sent successfully to server');
      print('📦 Server response: ${response.data}');
    } else {
      print('⚠️ Server responded with status: ${response.statusCode}');
      print('⚠️ Response data: ${response.data}');
    }
  } on DioException catch (e) {
    print('🚨 Dio error: ${e.message}');
    if (e.response != null) {
      print('🚨 Server response: ${e.response?.data}');
    }
  } catch (e) {
    print('🚨 Unknown error sending token: $e');
  }
}
