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
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _initController();
    _initRealNotificationSystem();
  }

  /// Sets up Android High Importance Notification Channel & requests Android 13+ permission dialog
  Future<void> _initRealNotificationSystem() async {
    try {
      // 1. Initialize local notifications with default icon
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('ic_launcher');
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification tapped: ${response.payload}');
        },
      );

      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      // 2. Create Heads-Up High Importance Channel
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

        // Request official Android 13+ Notification Permission via plugin
        try {
          await androidPlugin.requestNotificationsPermission();
        } catch (_) {}
      }

      // 3. Request official System Permission dialog via permission_handler (just like WhatsApp)
      try {
        final status = await Permission.notification.status;
        if (!status.isGranted) {
          final result = await Permission.notification.request();
          debugPrint('Notification permission status: $result');
        }
      } catch (e) {
        debugPrint('Permission handler check (handled safely): $e');
      }

      // 4. Send an instant welcome notification after 1.5 seconds so user sees it in action
      Future.delayed(const Duration(milliseconds: 1500), () {
        _triggerHeadsUpNotification(
          '👑 مرحباً بك في Abo Zahra',
          'تم تفعيل نظام الإشعارات الفورية بنجاح! ستصلك تنبيهات الحجوزات والدفع فوراً.',
        );
      });
    } catch (e) {
      debugPrint('Notification setup error (handled safely): $e');
    }
  }

  /// Triggers a real heads-up native Android notification with vibration & sound
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
      debugPrint('Native notification dispatched successfully [ID: $notifId]');
    } catch (e) {
      debugPrint('Error triggering local notification: $e');
    }
  }

  void _initController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0F0A1A))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) setState(() => _progress = progress / 100.0);
          },
          onPageStarted: (String url) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Web resource error (handled): ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) async {
            final url = request.url;

            // WhatsApp routing
            if (url.startsWith('https://wa.me') ||
                url.startsWith('whatsapp:') ||
                url.startsWith('https://api.whatsapp.com')) {
              try {
                final uri = Uri.parse(url);
                await launchUrl(uri, mode: LaunchMode.externalApplication);
                return NavigationDecision.prevent;
              } catch (_) {}
            }

            // Phone dialer
            if (url.startsWith('tel:')) {
              try {
                final uri = Uri.parse(url);
                await launchUrl(uri, mode: LaunchMode.externalApplication);
                return NavigationDecision.prevent;
              } catch (_) {}
            }

            // External links (ImgBB, etc.)
            if (url.startsWith('http://') || url.startsWith('https://')) {
              if (url.contains('imgbb.com') || url.contains('github.io')) {
                try {
                  final uri = Uri.parse(url);
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                  return NavigationDecision.prevent;
                } catch (_) {}
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
      );

    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      final htmlContent = await rootBundle.loadString('assets/www/index.html');
      await _controller.loadHtmlString(
        htmlContent,
        baseUrl: 'https://reservations-e411a.firebaseapp.com',
      );
    } catch (e) {
      debugPrint('Fallback loading asset: $e');
      _controller.loadFlutterAsset('assets/www/index.html');
    }
  }

  Future<void> _handleJavaScriptNotification(String rawJson) async {
    try {
      final data = jsonDecode(rawJson);
      final String title = data['title'] ?? 'إشعار جديد - Abo Zahra';
      final String message = data['message'] ?? '';
      await _triggerHeadsUpNotification(title, message);
    } catch (e) {
      // If rawJson was plain text
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
                LinearProgressIndicator(
                  value: _progress > 0 && _progress < 1 ? _progress : null,
                  backgroundColor: const Color(0xFF1A1225),
                  color: const Color(0xFFF59E0B),
                  minHeight: 3,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
