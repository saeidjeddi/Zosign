import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zosign/controller/playlist_controller.dart';
import 'package:zosign/services/sendTokenFcmToServer.dart';
import 'package:zosign/services/webSocket_serveice.dart';
import 'package:zosign/views/login_screen.dart';
import 'package:zosign/views/splash_screen.dart';
import 'firebase_options.dart';
import 'views/main_scrren.dart';

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'default_channel',
  'Default Channel',
  description: 'Default notifications channel.',
  importance: Importance.high,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('[Background] Message: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await GetStorage.init();

  final box = GetStorage();
  final playlistController = Get.put(PlaylistController());

  // ساخت کانال نوتیف برای اندروید
  if (Platform.isAndroid) {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  const initializationSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(),
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      print('🖱️ User clicked notification: ${response.payload}');
    },
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  String? fcmToken;
  try {
    NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      fcmToken = await FirebaseMessaging.instance.getToken();
      await box.write('fcm_token', fcmToken);
      await sendTokenToServer(fcmToken!);
      print('✅ FCM Token: $fcmToken');
    }
  } catch (e) {
    print('⚠️ Firebase not supported or failed: $e');
  }

  // 🔥 همیشه WebSocket رو راه‌اندازی کن - حتی اگر FCM فعال باشد
  print('🔗 Starting WebSocket service...');
  final wsService = Get.put(WebSocketService());

  // 🔥 فقط WebSocket مسئول پاک‌سازی کش باشد
  wsService.connect(onMessage: (msg) async {
    print('📩 WebSocket Message: $msg');
    
    // پاک کردن کش‌های ذخیره‌شده
    await box.erase();

    // پاک کردن کش ویدیوها
    try {
      final dir = await getApplicationDocumentsDirectory();
      final videoDir = Directory('${dir.path}/videos');
      if (await videoDir.exists()) {
        videoDir.deleteSync(recursive: true);
        print('🧽 Video cache deleted via WebSocket: ${videoDir.path}');
      }
    } catch (e) {
      print('⚠️ Error deleting video cache: $e');
    }

    // 🔥 فقط پلی‌لیست رو ریفرش کن - بدون دانلود خودکار
    await playlistController.clearCacheWithoutDownload();
  });

  // 🔥 FCM فقط برای نمایش نوتیفیکیشن - بدون پاک‌سازی کش
  if (fcmToken != null && fcmToken.isNotEmpty) {
    print('🚀 Firebase Messaging active (notifications only)...');
    
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('📩 FCM Notification received: ${message.messageId}');
      print('📢 Notification Title: ${message.notification?.title}');
      print('📝 Notification Body: ${message.notification?.body}');
      
      // 🔥 فقط نوتیفیکیشن نمایش داده شود - کش پاک نمی‌شود
      // اینجا می‌توانید نوتیفیکیشن محلی نمایش دهید اگر نیاز است
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      print('📩 FCM Notification opened from background: ${message.messageId}');
      // 🔥 هیچ عملیات پاک‌سازی انجام نمی‌شود
    });
  }

  runApp(const MainAppTv());
}

class MainAppTv extends StatelessWidget {
  const MainAppTv({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Zosign Player',
      theme: ThemeData.dark(useMaterial3: true),
      home:  SplashScreen(),
    );
  }
}