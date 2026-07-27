import 'package:flutter/material.dart';
import '../pages/splash/splash_page.dart';
import '../pages/home/home_page.dart';
import '../pages/chat/chat_page.dart';
import '../pages/profile/profile_page.dart';
import '../pages/records/diary_editor_page.dart';
import '../pages/itinerary/itinerary_list_page.dart';
import '../pages/itinerary/itinerary_detail_page.dart';
import '../pages/itinerary/itinerary_editor_page.dart';
import '../pages/profile/api_settings_page.dart';
import '../pages/profile/ima_settings_page.dart';
import '../pages/profile/user_profile_page.dart';
import '../pages/profile/prompt_settings_page.dart';
import 'travel_icons.dart';
import 'theme.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String home = '/';
  static const String records = '/records';
  static const String chat = '/chat';
  static const String profile = '/profile';
  static const String diaryEditor = '/diary-editor';
  static const String itineraryList = '/itineraries';
  static const String itineraryDetail = '/itinerary-detail';
  static const String itineraryEditor = '/itinerary-editor';
  static const String apiSettings = '/api-settings';
  static const String imaSettings = '/ima-settings';
  static const String userProfile = '/user-profile';
  static const String promptSettings = '/prompt-settings';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashPage());
      case diaryEditor:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => DiaryEditorPage(
            recordId: args?['recordId'] as String?,
            itineraryId: args?['itineraryId'] as String?,
            initialContent: args?['initialContent'] as String?,
            destination: args?['destination'] as String?,
            startDate: args?['startDate'] as DateTime?,
            endDate: args?['endDate'] as DateTime?,
            people: args?['people'] as int?,
            tripType: args?['tripType'] as String?,
            initialTotalCost: args?['totalCost'] as double?,
            initialRating: args?['rating'] as double?,
          ),
        );
      case itineraryDetail:
        final id = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => ItineraryDetailPage(itineraryId: id),
        );
      case itineraryEditor:
        final id = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => ItineraryEditorPage(itineraryId: id),
        );
      case apiSettings:
        return MaterialPageRoute(builder: (_) => const ApiSettingsPage());
      case imaSettings:
        return MaterialPageRoute(builder: (_) => const ImaSettingsPage());
      case userProfile:
        return MaterialPageRoute(builder: (_) => const UserProfilePage());
      case promptSettings:
        return MaterialPageRoute(builder: (_) => const PromptSettingsPage());
      default:
        return MaterialPageRoute(builder: (_) => const MainShell());
    }
  }
}

/// 主页面容器（底部导航栏）
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const ItineraryListPage(),
    const ChatPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppTheme.borderColor, width: 0.8),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          items: [
            BottomNavigationBarItem(
              icon: TravelIcons.timelineUnselected(),
              activeIcon: TravelIcons.timelineSelected(),
              label: '首页',
            ),
            BottomNavigationBarItem(
              icon: TravelIcons.mapUnselected(),
              activeIcon: TravelIcons.mapSelected(),
              label: '攻略',
            ),
            BottomNavigationBarItem(
              icon: TravelIcons.chatUnselected(),
              activeIcon: TravelIcons.chatSelected(),
              label: 'AI',
            ),
            BottomNavigationBarItem(
              icon: TravelIcons.personUnselected(),
              activeIcon: TravelIcons.personSelected(),
              label: '我的',
            ),
          ],
        ),
      ),
    );
  }
}
