import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'theme/app_colors.dart';
import 'providers/portfolio_provider.dart';
import 'providers/theme_provider.dart';
import 'models/models.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(PriceLogAdapter());
  Hive.registerAdapter(StockAdapter());
  await Hive.openBox<Stock>('stocks');
  await Hive.openBox('settings');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PortfolioProvider()..loadFromHive()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDark = themeProvider.isDark;

        return MaterialApp(
          title: 'CSE Portfolio',
          debugShowCheckedModeBanner: false,
          theme: isDark
              ? ThemeData(
                  brightness: Brightness.dark,
                  scaffoldBackgroundColor: AppColors.bg,
                  textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme).apply(bodyColor: AppColors.text, displayColor: AppColors.text),
                  colorScheme: const ColorScheme.dark(primary: AppColors.em, secondary: AppColors.blue, surface: AppColors.s1),
                )
              : ThemeData(
                  brightness: Brightness.light,
                  scaffoldBackgroundColor: const Color(0xFFF5F7FA),
                  textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme).apply(bodyColor: const Color(0xFF1A1D2E), displayColor: const Color(0xFF1A1D2E)),
                  colorScheme: const ColorScheme.light(primary: Color(0xFF00C97D), secondary: Color(0xFF4D8FFF), surface: Colors.white),
                ),
          home: const MainScreen(),
        );
      },
    );
  }
}
