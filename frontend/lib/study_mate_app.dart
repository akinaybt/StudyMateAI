import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'ui/auth_screen.dart';
import 'ui/home_screen.dart';
import 'ui/upload_screen.dart';
import 'ui/lecture_screen.dart';
import 'ui/account_screen.dart';
import 'ui/cards_screen.dart';

enum AppTab { home, upload, cards, lecture, account }

class StudyMateApp extends StatefulWidget {
  const StudyMateApp({super.key});

  @override
  State<StudyMateApp> createState() => _StudyMateAppState();
}

class _StudyMateAppState extends State<StudyMateApp> {
  AppTab _tab = AppTab.home;

  /// Set this to `false` to show the Auth screen first.
  bool _isLoggedIn = false;

  // Background similar to bg-gradient-to-br from-blue-50 via-indigo-50 to-purple-50
  static const _bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFEFF6FF), // blue-50-ish
      Color(0xFFEEF2FF), // indigo-50-ish
      Color(0xFFF5F3FF), // purple-50-ish
    ],
  );

  void _go(AppTab tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      // IMPORTANT: wrap in Material so InkWell in AuthScreen has a Material ancestor.
      return DecoratedBox(
        decoration: const BoxDecoration(gradient: _bgGradient),
        child: Material(
          type: MaterialType.transparency,
          child: SafeArea(
            child: AuthScreen(
              onLoggedIn: () => setState(() => _isLoggedIn = true),
            ),
          ),
        ),
      );
    }

    final Widget body = switch (_tab) {
      AppTab.home => HomeScreen(onNavigate: _go),
      AppTab.upload => UploadScreen(onBack: () => _go(AppTab.home)),
      AppTab.cards => CardsScreen(onBack: () => _go(AppTab.home)),
      AppTab.lecture => LectureScreen(onBack: () => _go(AppTab.home)),
      AppTab.account => AccountScreen(
        onLogout: () => setState(() => _isLoggedIn = false),
      ),
    };

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: _bgGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              const _Header(),
              Expanded(child: body),
            ],
          ),
        ),
        bottomNavigationBar: _BottomNav(
          tab: _tab,
          onChange: (t) => setState(() => _tab = t),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    // approximates "bg-white/80 backdrop-blur border-b border-indigo-100 sticky"
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.82),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFC7D2FE).withOpacity(0.6), // indigo-200-ish
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF818CF8), // indigo-400-ish
                  Color(0xFFA855F7), // purple-500-ish
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.school, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'StudyMate AI',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 2),
              Text(
                'Your Intelligent Companion',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6B7280), // gray-500-ish
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final AppTab tab;
  final ValueChanged<AppTab> onChange;

  const _BottomNav({required this.tab, required this.onChange});

  @override
  Widget build(BuildContext context) {
    const Color active = Color(0xFF4F46E5); // indigo-600-ish
    const Color inactive = Color(0xFF6B7280); // gray-500-ish

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.82),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFC7D2FE).withOpacity(0.6),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            label: 'Home',
            icon: Icons.school,
            active: tab == AppTab.home,
            activeColor: active,
            inactiveColor: inactive,
            onTap: () => onChange(AppTab.home),
          ),
          _NavItem(
            label: 'Upload',
            icon: Icons.upload_file,
            active: tab == AppTab.upload,
            activeColor: active,
            inactiveColor: inactive,
            onTap: () => onChange(AppTab.upload),
          ),
          _NavItem(
            label: 'Cards',
            icon: Icons.credit_card,
            active: tab == AppTab.cards,
            activeColor: active,
            inactiveColor: inactive,
            onTap: () => onChange(AppTab.cards),
          ),
          _NavItem(
            label: 'Lecture',
            icon: Icons.mic,
            active: tab == AppTab.lecture,
            activeColor: active,
            inactiveColor: inactive,
            onTap: () => onChange(AppTab.lecture),
          ),
          _NavItem(
            label: 'Account',
            icon: Icons.person,
            active: tab == AppTab.account,
            activeColor: active,
            inactiveColor: inactive,
            onTap: () => onChange(AppTab.account),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? activeColor : inactiveColor;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}