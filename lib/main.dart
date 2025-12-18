import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'package:quizzit/firebase_options.dart';
import 'services/ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set up error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      print('Flutter Error: ${details.exception}');
      print('Stack trace: ${details.stack}');
    }
  };

  // Initialize Firebase with error handling
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if (kDebugMode) {
      print('✅ Firebase initialized successfully');
    }
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print('❌ Firebase initialization error: $e');
      print('Stack trace: $stackTrace');
    }
    // Run app anyway - it will show an error screen or fallback
  }

  // Initialize Google Mobile Ads
  try {
    await AdService.instance.initialize();
    // Configure request settings for test ads in debug mode
    if (kDebugMode) {
      MobileAds.instance.updateRequestConfiguration(
        AdService.instance.getRequestConfiguration(),
      );
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Ad initialization error: $e');
    }
    // Continue even if ads fail to initialize
  }

  runApp(const QuizGeneratorApp());
}

class QuizGeneratorApp extends StatefulWidget {
  const QuizGeneratorApp({super.key});

  /// Accessor to allow children (e.g., Settings screen) to change theme.
  static QuizGeneratorAppState of(BuildContext context) {
    final state = context.findAncestorStateOfType<_QuizGeneratorAppState>();
    assert(state != null, 'QuizGeneratorApp state not found in context');
    return state!;
  }

  @override
  State<QuizGeneratorApp> createState() => _QuizGeneratorAppState();
}

/// Public abstract class for QuizGeneratorApp state
abstract class QuizGeneratorAppState extends State<QuizGeneratorApp> {
  ThemeMode get themeMode;
  void setThemeMode(ThemeMode mode);
}

class _QuizGeneratorAppState extends QuizGeneratorAppState {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  ThemeMode get themeMode => _themeMode;

  @override
  void setThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
    _saveThemeMode(mode);
  }

  @override
  void initState() {
    super.initState();
    _loadSavedTheme();
  }

  Future<void> _loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString('theme_mode');
      if (value == 'dark') {
        setState(() {
          _themeMode = ThemeMode.dark;
        });
      } else if (value == 'light') {
        setState(() {
          _themeMode = ThemeMode.light;
        });
      } else if (value == 'system') {
        setState(() {
          _themeMode = ThemeMode.system;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading saved theme: $e');
      }
    }
  }

  Future<void> _saveThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String value;
      switch (mode) {
        case ThemeMode.dark:
          value = 'dark';
          break;
        case ThemeMode.system:
          value = 'system';
          break;
        case ThemeMode.light:
          value = 'light';
          break;
      }
      await prefs.setString('theme_mode', value);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving theme: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lightTheme = ThemeData(
      primarySwatch: Colors.deepPurple,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
    );

    final darkTheme = ThemeData.dark().copyWith(
      colorScheme: const ColorScheme.dark(
        primary: Colors.deepPurple,
        secondary: Colors.deepPurpleAccent,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.black87,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
    );

    return MaterialApp(
      title: 'Quiz Generator',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeMode,
      home: const AuthWrapper(),
      // Add error builder to catch any rendering errors
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: child ?? const SizedBox(),
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if Firebase is initialized
    try {
      // Try to access FirebaseAuth - if it fails, show login directly
      final auth = FirebaseAuth.instance;
      return StreamBuilder<User?>(
        stream: auth.authStateChanges(),
        builder: (context, snapshot) {
          // Handle errors in the stream
          if (snapshot.hasError) {
            if (kDebugMode) {
              print('Auth stream error: ${snapshot.error}');
            }
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Authentication Error',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Error: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        // Try to show login screen anyway
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text('Continue to Login'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            return const DashboardScreen();
          } else {
            return const LoginScreen();
          }
        },
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ AuthWrapper error: $e');
        print('Stack trace: $stackTrace');
      }
      // Fallback to login screen if there's an error
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 64,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              const Text(
                'Firebase Not Available',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Unable to connect to Firebase. Please check your configuration.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Show login screen anyway
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text('Continue Anyway'),
              ),
            ],
          ),
        ),
      );
    }
  }
}
