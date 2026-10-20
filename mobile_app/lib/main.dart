import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const String kNotificationChannelId = 'abozahra_reservations_v3';
const String kNotificationChannelName = 'حجوزات وإشعارات أبو زهرة';

void main() {
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
        final AndroidNotificationChannel channel = AndroidNotificationChannel(
          kNotificationChannelId,
          kNotificationChannelName,
          description: 'تنبيهات فورية عند وصول حجز جديد أو رفع إسكرين دفع',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
          showBadge: true,
        );
        await androidPlugin.createNotificationChannel(channel);

        try {
          await androidPlugin.requestNotificationsPermission();
        } catch (_) {}
      }

      try {
        final status = await Permission.notification.status;
        if (!status.isGranted) {
          await Permission.notification.request();
        }
      } catch (e) {
        debugPrint('Permission request error: $e');
      }
    } catch (e) {
      debugPrint('Notification setup error: $e');
    }
  }

  Future<void> _triggerHeadsUpNotification(String title, String message) async {
    try {
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        kNotificationChannelId,
        kNotificationChannelName,
        channelDescription: 'تنبيهات فورية عند وصول حجز جديد أو رفع إسكرين دفع',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'إشعار Abo Zahra',
        showWhen: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 400, 200, 400]),
        playSound: true,
        icon: 'ic_notification',
        styleInformation: BigTextStyleInformation(
          message,
          contentTitle: title,
        ),
      );

      final NotificationDetails platformDetails =
          NotificationDetails(android: androidDetails);

      final int notifId = DateTime.now().millisecondsSinceEpoch % 100000;
      await flutterLocalNotificationsPlugin.show(
        notifId,
        title,
        message,
        platformDetails,
      );
    } catch (e) {
      debugPrint('Error triggering notification: $e');
    }
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
