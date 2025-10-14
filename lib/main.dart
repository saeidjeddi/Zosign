import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'package:zosign/views/main_scrren.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('📩 پیام در بک‌گراند: ${message.messageId}');
}

Future<String?> getFcmTokenWithRetry({int retries = 5, int delaySeconds = 2}) async {
  for (int i = 0; i < retries; i++) {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) return token;
      print('⏳ توکن هنوز آماده نیست، تلاش دوباره...');
    } catch (e) {
      print('❌ خطا هنگام گرفتن توکن FCM: $e');
    }
    await Future.delayed(Duration(seconds: delaySeconds));
  }
  return null;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  final fcmToken = await getFcmTokenWithRetry();
  if (fcmToken != null) {
    print('🔥 FCM Token: $fcmToken');
  } else {
    print('❌ بعد از چند تلاش، FCM Token هنوز آماده نیست.');
  }

  runApp(const MainAppTv());
}

class MainAppTv extends StatelessWidget {
  const MainAppTv({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}
