import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// Channels Constants
const String kAlertNotificationChannelId = 'abozahra_orders_vip_v5';
const String kAlertNotificationChannelName = 'تنبيهات طلبات وحجوزات أبو زهرة (نغمة مخصصة)';
const String kForegroundServiceChannelId = 'abozahra_bg_service_channel_v5';
const String kForegroundServiceChannelName = 'خدمة مراقبة الحجوزات بالخلفية 24/7';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Helper to show high-priority order alert with custom sound
Future<void> showOrderAlertNotification(
  FlutterLocalNotificationsPlugin plugin, {
  required int id,
  required String title,
  required String body,
}) async {
  try {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      kAlertNotificationChannelId,
      kAlertNotificationChannelName,
      channelDescription: 'تنبيهات فورية بصوت مخصص عند وصول حجز جديد أو إسكرين دفع',
      importance: Importance.max,
      priority: Priority.high,
      sound: const RawResourceAndroidNotificationSound('order_alert'),
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
      icon: 'ic_notification',
      ticker: 'Abo Zahra VIP Alert',
      showWhen: true,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'Abo Zahra VIP Alert',
      ),
    );

    final NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await plugin.show(id % 100000, title, body, platformDetails);
  } catch (e) {
    debugPrint('Error in showOrderAlertNotification: $e');
  }
}

// Background Polling Worker
Future<void> pollFirestoreReservations(
    FlutterLocalNotificationsPlugin notifications) async {
  try {
    final prefs = await SharedPreferences.getInstance();

    List<String> seenHeadphones =
        prefs.getStringList('seen_headphone_ids') ?? [];
    List<String> seenExams =
        prefs.getStringList('seen_exam_ids') ?? [];
    List<String> seenProofs =
        prefs.getStringList('seen_proof_ids') ?? [];
    bool isFirstRun = prefs.getBool('is_bg_first_run') ?? true;

    // 1. Fetch Headphones reservations
    try {
      final hUrl = Uri.parse(
          'https://firestore.googleapis.com/v1/projects/reservations-e411a/databases/(default)/documents/reservations?pageSize=50');
      final res = await http.get(hUrl).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List documents = (data['documents'] as List?) ?? [];

        for (final doc in documents) {
          final String namePath = doc['name'] ?? '';
          final String docId = namePath.split('/').last;
          final fields = doc['fields'] ?? {};

          final String name = fields['name']?['stringValue'] ?? 'عميل';
          final String device = fields['device']?['stringValue'] ?? 'سماعة';
          final String? proofUrl = fields['payment_proof_url']?['stringValue'];

          if (!seenHeadphones.contains(docId)) {
            seenHeadphones.add(docId);
            if (!isFirstRun) {
              await showOrderAlertNotification(
                notifications,
                id: docId.hashCode,
                title: '🎧 حجز سماعة جديد!',
                body: 'حجز جديد باسم: $name ($device)',
              );
            }
          }

          // Check for new payment screenshot
          if (proofUrl != null &&
              proofUrl.isNotEmpty &&
              !seenProofs.contains(docId)) {
            seenProofs.add(docId);
            if (!isFirstRun) {
              await showOrderAlertNotification(
                notifications,
                id: (docId + '_proof').hashCode,
                title: '📸 إسكرين تحويل جديد!',
                body: 'قام العميل $name برفع إسكرين التحويل.',
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error polling headphones: $e');
    }

    // 2. Fetch Exams reservations
    try {
      final eUrl = Uri.parse(
          'https://firestore.googleapis.com/v1/projects/reservations-e411a/databases/(default)/documents/exam_reservations?pageSize=50');
      final res = await http.get(eUrl).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List documents = (data['documents'] as List?) ?? [];

        for (final doc in documents) {
          final String namePath = doc['name'] ?? '';
          final String docId = namePath.split('/').last;
          final fields = doc['fields'] ?? {};

          final String name = fields['name']?['stringValue'] ?? 'طالب';
          final String section = fields['section']?['stringValue'] ?? 'شعبة';

          if (!seenExams.contains(docId)) {
            seenExams.add(docId);
            if (!isFirstRun) {
              await showOrderAlertNotification(
                notifications,
                id: docId.hashCode,
                title: '🎓 حجز امتحان جديد!',
                body: 'حجز جديد باسم: $name ($section)',
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error polling exams: $e');
    }

    if (isFirstRun) {
      await prefs.setBool('is_bg_first_run', false);
    }
    await prefs.setStringList('seen_headphone_ids', seenHeadphones);
    await prefs.setStringList('seen_exam_ids', seenExams);
    await prefs.setStringList('seen_proof_ids', seenProofs);
  } catch (e) {
    debugPrint('Background polling error: $e');
  }
}

// Background Service Entry Point
@pragma('vm:entry-point')
void onBackgroundServiceStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  final FlutterLocalNotificationsPlugin bgNotifications =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('ic_launcher');
  await bgNotifications.initialize(
    const InitializationSettings(android: androidSettings),
  );

  final androidPlugin = bgNotifications.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  if (androidPlugin != null) {
    final AndroidNotificationChannel alertChannel = AndroidNotificationChannel(
      kAlertNotificationChannelId,
      kAlertNotificationChannelName,
      description: 'تنبيهات فورية بصوت مخصص عند وصول حجز جديد أو إسكرين دفع',
      importance: Importance.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('order_alert'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
      showBadge: true,
    );
    await androidPlugin.createNotificationChannel(alertChannel);
  }

  // Periodic polling every 15 seconds
  Timer.periodic(const Duration(seconds: 15), (timer) async {
    await pollFirestoreReservations(bgNotifications);
  });
}

// Initialize Background Service
Future<void> initializeBackgroundService() async {
  try {
    final service = FlutterBackgroundService();

    const AndroidNotificationChannel bgChannel = AndroidNotificationChannel(
      kForegroundServiceChannelId,
      kForegroundServiceChannelName,
      description: 'إشعار صامت للحفاظ على عمل خدمة مراقبة الحجوزات بالخلفية 24/7',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(bgChannel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onBackgroundServiceStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: kForegroundServiceChannelId,
        initialNotificationTitle: 'Abo Zahra Admin',
        initialNotificationContent: 'خدمة مراقبة الحجوزات تعمل بالخلفية 24/7',
        foregroundServiceNotificationId: 9999,
      ),
      iosConfiguration: IOSConfiguration(
        autoStart: false,
        onForeground: onBackgroundServiceStart,
      ),
    );

    await service.startService();
  } catch (e) {
    debugPrint('Background service init error: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('Safe Flutter Error: ${details.exceptionAsString()}');
  };

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0F0A1A),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Initialize background service
  await initializeBackgroundService();

  runApp(const AboZahraApp());
}

class AboZahraApp extends StatelessWidget {
  const AboZahraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Abo Zahra',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0F0A1A),
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF59E0B),
          secondary: Color(0xFFFCD34D),
          surface: Color(0xFF1A1225),
        ),
      ),
      home: const DashboardWebViewScreen(),
    );
  }
}

class DashboardWebViewScreen extends StatefulWidget {
  const DashboardWebViewScreen({super.key});

  @override
  State<DashboardWebViewScreen> createState() => _DashboardWebViewScreenState();
}

class _DashboardWebViewScreenState extends State<DashboardWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initController();
    _initRealNotificationSystem();
    _requestNativePermissions();
  }

  Future<void> _requestNativePermissions() async {
    try {
      // 1. Request official notification permission (Android 13+ POST_NOTIFICATIONS)
      final notifStatus = await Permission.notification.status;
      if (!notifStatus.isGranted) {
        await Permission.notification.request();
      }

      // 2. Request Ignore Battery Optimizations so OS doesn't kill the background listener
      final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
      if (!batteryStatus.isGranted) {
        await Future.delayed(const Duration(seconds: 2));
        await Permission.ignoreBatteryOptimizations.request();
      }
    } catch (e) {
      debugPrint('Native permission error: $e');
    }
  }

  Future<void> _initRealNotificationSystem() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('ic_launcher');
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
      );

      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        // Delete old channel without custom sound to force Android to use custom sound
        try {
          await androidPlugin.deleteNotificationChannel('abozahra_reservations_v3');
        } catch (_) {}

        // Create new high-importance VIP alert channel with custom sound
        final AndroidNotificationChannel channel = AndroidNotificationChannel(
          kAlertNotificationChannelId,
          kAlertNotificationChannelName,
          description: 'تنبيهات فورية بصوت مخصص عند وصول حجز جديد أو إسكرين دفع',
          importance: Importance.max,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound('order_alert'),
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
          showBadge: true,
        );
        await androidPlugin.createNotificationChannel(channel);

        try {
          await androidPlugin.requestNotificationsPermission();
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Notification setup error: $e');
    }
  }

  Future<void> _triggerHeadsUpNotification(String title, String message) async {
    final int notifId = DateTime.now().millisecondsSinceEpoch % 100000;
    await showOrderAlertNotification(
      flutterLocalNotificationsPlugin,
      id: notifId,
      title: title,
      body: message,
    );
  }

  void _initController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0F0A1A))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Web resource error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) async {
            final url = request.url;

            if (url.startsWith('https://wa.me') ||
                url.startsWith('whatsapp:') ||
                url.startsWith('https://api.whatsapp.com') ||
                url.startsWith('tel:')) {
              try {
                final uri = Uri.parse(url);
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } catch (_) {}
              return NavigationDecision.prevent;
            }

            if (url.startsWith('http://') || url.startsWith('https://')) {
              if (url.contains('imgbb.com') || url.contains('github.io')) {
                try {
                  final uri = Uri.parse(url);
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } catch (_) {}
                return NavigationDecision.prevent;
              }
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'NotificationBridge',
        onMessageReceived: (JavaScriptMessage message) {
          _handleJavaScriptNotification(message.message);
        },
      )
      ..loadFlutterAsset('assets/www/index.html');
  }

  Future<void> _handleJavaScriptNotification(String rawJson) async {
    try {
      final data = jsonDecode(rawJson);
      final String title = data['title'] ?? 'إشعار جديد - Abo Zahra';
      final String message = data['message'] ?? '';
      await _triggerHeadsUpNotification(title, message);
    } catch (e) {
      await _triggerHeadsUpNotification('إشعار Abo Zahra', rawJson);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        try {
          final res = await _controller.runJavaScriptReturningResult(
              'window.handleAndroidBackPressed ? window.handleAndroidBackPressed() : false');
          if (res == true || res == 'true') {
            return false;
          }
        } catch (_) {}

        if (await _controller.canGoBack()) {
          _controller.goBack();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0A1A),
        body: SafeArea(
          child: Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (_isLoading)
                const LinearProgressIndicator(
                  backgroundColor: Color(0xFF1A1225),
                  color: Color(0xFFF59E0B),
                  minHeight: 2.5,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
