import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_storage/get_storage.dart';
import 'package:zosign/services/sendTokenFcmToServer.dart';
import 'package:zosign/controller/playlist_controller.dart';
import 'firebase_options.dart';
import 'views/main_scrren.dart';

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'default_channel', // id
  'Default Channel', // name
  description: 'This channel is used for default notifications.',
  importance: Importance.high,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('[Background] Message in background : ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await GetStorage.init();

  // ساخت کانال نوتیف برای اندروید
  if (Platform.isAndroid) {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings();
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      print('🖱️ user clicked notification: ${response.payload}');
    },
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 🔔 درخواست مجوز نوتیف
  NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  print('🔐 Permissions: ${settings.authorizationStatus}');

  // 📦 دریافت و ذخیره توکن
  FirebaseMessaging.instance.getToken().then((token) {
    print('🔥 FCM Token: $token');
    final box = GetStorage();
    box.write('fcm_token', token);
    sendTokenToServer(token!);
  }).catchError((e) {
    print('❌ Error getting FCM token: $e');
  });

  // ✅ هندل نوتیف در فورگراند
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('📩 Message in foreground: ${message.notification?.title}');
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    // 🔁 وقتی نوتیف میاد پلی‌لیست ریفرش بشه
    try {
      final playlistController = Get.find<PlaylistController>();
      playlistController.refreshTrigger.value = true;
    } catch (e) {
      print('⚠️ PlaylistController not found: $e');
    }

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: android.smallIcon,
          ),
        ),
        payload: message.data['route'],
      );
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('🚀 User opened notification: ${message.data}');
  });

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
      home: const MainScreen(),
    );
  }
}
