import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch any unexpected flutter framework errors safely
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('Safe Flutter Error: ${details.exceptionAsString()}');
  };

  // Modern transparent status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0F0A1A),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Run the application immediately without blocking
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
    _initNotificationsSafely();
  }

  Future<void> _initNotificationsSafely() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Tap on notification
        },
      );

      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'abozahra_reservations_v2',
          'حجوزات وإشعارات أبو زهرة',
          description: 'تنبيهات فورية عند وصول حجز جديد أو رفع إسكرين دفع',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        );
        await androidPlugin.createNotificationChannel(channel);
        try {
          await androidPlugin.requestNotificationsPermission();
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Notification setup error (handled safely): $e');
    }
  }

  void _initController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0F0A1A))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _progress = progress / 100.0;
              });
            }
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

            // Handle WhatsApp links directly in official WhatsApp app
            if (url.startsWith('https://wa.me') ||
                url.startsWith('whatsapp:') ||
                url.startsWith('https://api.whatsapp.com')) {
              try {
                final uri = Uri.parse(url);
                await launchUrl(uri, mode: LaunchMode.externalApplication);
                return NavigationDecision.prevent;
              } catch (_) {}
            }

            // Handle phone dialer links
            if (url.startsWith('tel:')) {
              try {
                final uri = Uri.parse(url);
                await launchUrl(uri, mode: LaunchMode.externalApplication);
                return NavigationDecision.prevent;
              } catch (_) {}
            }

            // Handle external links (ImgBB, GitHub, etc.)
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
      final String title = data['title'] ?? 'إشعار جديد';
      final String message = data['message'] ?? '';

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'abozahra_reservations_v2',
        'حجوزات وإشعارات أبو زهرة',
        channelDescription: 'تنبيهات فورية عند وصول حجز جديد أو رفع إسكرين دفع',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      );

      const NotificationDetails platformDetails =
          NotificationDetails(android: androidDetails);

      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch % 100000,
        title,
        message,
        platformDetails,
      );
    } catch (e) {
      debugPrint('Error triggering local notification: $e');
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
