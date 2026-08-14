import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/theme.dart';
import 'app/routes.dart';
import 'core/app_bootstrap.dart';
import 'core/logger.dart';
import 'providers/records_provider.dart';
import 'providers/itinerary_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/stats_provider.dart';
import 'providers/sync_provider.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('zh_CN', null);
    await Hive.initFlutter();
    await AppLogger().init();
    AppBootstrap.registerEventConsumers();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => RecordsProvider()..init()),
          ChangeNotifierProvider(create: (_) => ItineraryProvider()..init()),
          ChangeNotifierProvider(create: (_) => ChatProvider()),
          ChangeNotifierProvider(create: (_) => ProfileProvider()..init()),
          ChangeNotifierProvider(create: (_) => StatsProvider()..init()),
          ChangeNotifierProvider(create: (_) => SyncProvider()),
        ],
        child: const TravelApp(),
      ),
    );
  }, (error, stack) {
    AppLogger().logError('Uncaught', error, stack);
  });
}

class TravelApp extends StatelessWidget {
  const TravelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '旅行搭子',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en'),
      ],
      locale: const Locale('zh', 'CN'),
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
