
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'viewmodels/food_list_view_model.dart';
import 'screens/home_screen.dart';
import 'utils/notification_helper.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  await NotificationHelper().init();
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool? _isFirstTime;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isFirstTime = prefs.getBool('isFirstTime') ?? true;
      });
    } catch (e) {
      debugPrint('Error checking first time: $e');
      // If error (e.g. MissingPluginException), default to false to unblock UI
      setState(() {
        _isFirstTime = false; 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFirstTime == null) {
      return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FoodListViewModel()..loadItems()),
      ],
      child: MaterialApp(
        title: 'MoguMogu',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFF9800), // Warm Orange
            primary: const Color(0xFFFF9800),
            secondary: const Color(0xFF4CAF50), // Fresh Green
            surface: Colors.white, // Pure White
          ),
          useMaterial3: true,
          textTheme: GoogleFonts.mPlusRounded1cTextTheme(),
        ),
        home: _isFirstTime! ? const OnboardingScreen() : const HomeScreen(),
      ),
    );
  }
}
