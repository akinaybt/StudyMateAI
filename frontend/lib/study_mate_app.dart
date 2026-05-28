import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ui/_ui.dart';
import 'ui/account_screen.dart';
import 'ui/auth_screen.dart';
import 'ui/cards_screen.dart';
import 'ui/home_screen.dart';
import 'ui/lecture_screen.dart';
import 'ui/upload_screen.dart';

enum AppTab { home, upload, cards, lecture, account }

enum AppGateState { auth, recovery, app }

class StudyMateApp extends StatefulWidget {
  const StudyMateApp({super.key});

  @override
  State<StudyMateApp> createState() => _StudyMateAppState();
}

class _StudyMateAppState extends State<StudyMateApp> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final StreamSubscription<AuthState> _authSubscription;

  AppTab _tab = AppTab.home;
  AppGateState _gateState = AppGateState.auth;

  static const _bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFEFF6FF),
      Color(0xFFEEF2FF),
      Color(0xFFF5F3FF),
    ],
  );

  @override
  void initState() {
    super.initState();

    _gateState = _supabase.auth.currentSession != null
        ? AppGateState.app
        : AppGateState.auth;

    _authSubscription = _supabase.auth.onAuthStateChange.listen(
          (data) {
        if (!mounted) return;

        setState(() {
          switch (data.event) {
            case AuthChangeEvent.passwordRecovery:
              _gateState = AppGateState.recovery;
              _tab = AppTab.home;
              break;
            case AuthChangeEvent.signedOut:
              _gateState = AppGateState.auth;
              _tab = AppTab.home;
              break;
            case AuthChangeEvent.userDeleted:
              _gateState = AppGateState.auth;
              _tab = AppTab.home;
              break;
            case AuthChangeEvent.initialSession:
            case AuthChangeEvent.signedIn:
            case AuthChangeEvent.tokenRefreshed:
            case AuthChangeEvent.userUpdated:
            case AuthChangeEvent.mfaChallengeVerified:
              if (_gateState != AppGateState.recovery) {
                _gateState = data.session != null
                    ? AppGateState.app
                    : AppGateState.auth;
                if (data.session == null) {
                  _tab = AppTab.home;
                }
              }
              break;
          }
        });
      },
      onError: (error, stackTrace) {
        if (!mounted) return;

        debugPrint('Supabase auth error: $error');

        unawaited(_supabase.auth.signOut());

        setState(() {
          _gateState = AppGateState.auth;
          _tab = AppTab.home;
        });
      },
    );
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  void _go(AppTab tab) => setState(() => _tab = tab);

  void _handleLoggedIn() {
    if (!mounted) return;

    setState(() {
      _gateState = _supabase.auth.currentSession != null
          ? AppGateState.app
          : AppGateState.auth;
      _tab = AppTab.home;
    });
  }

  void _handleLogout() {
    unawaited(_supabase.auth.signOut());
  }

  void _handleRecoveryCompleted() {
    if (!mounted) return;

    setState(() {
      _gateState = AppGateState.app;
      _tab = AppTab.home;
    });
  }

  void _handleRecoveryCancelled() {
    if (!mounted) return;

    setState(() {
      _gateState = AppGateState.auth;
      _tab = AppTab.home;
    });

    unawaited(_supabase.auth.signOut());
  }

  @override
  Widget build(BuildContext context) {
    if (_gateState == AppGateState.auth) {
      return DecoratedBox(
        decoration: const BoxDecoration(gradient: _bgGradient),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: AuthScreen(
              onLoggedIn: _handleLoggedIn,
            ),
          ),
        ),
      );
    }

    if (_gateState == AppGateState.recovery) {
      return DecoratedBox(
        decoration: const BoxDecoration(gradient: _bgGradient),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: PasswordRecoveryScreen(
              onCompleted: _handleRecoveryCompleted,
              onCancel: _handleRecoveryCancelled,
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
        onLogout: _handleLogout,
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

class PasswordRecoveryScreen extends StatefulWidget {
  final VoidCallback onCompleted;
  final VoidCallback onCancel;

  const PasswordRecoveryScreen({
    super.key,
    required this.onCompleted,
    required this.onCancel,
  });

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();

  bool _showPassword = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _updatePassword() async {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password.isEmpty || confirmPassword.isEmpty) {
      _showMessage('Please enter and confirm your new password.');
      return;
    }

    if (password.length < 6) {
      _showMessage('Password must be at least 6 characters long.');
      return;
    }

    if (password != confirmPassword) {
      _showMessage('Passwords do not match.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: password),
      );

      _showMessage('Password updated successfully.');
      widget.onCompleted();
    } on AuthException catch (e) {
      _showMessage(e.message);
    } catch (e) {
      _showMessage('Could not update password: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF818CF8), Color(0xFFA855F7)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.lock_reset, color: Colors.white, size: 34),
              ),
              const SizedBox(height: 14),
              const Text(
                'Reset Password',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose a new password for your StudyMate account',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 22),
              GlassCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _RecoveryField(
                      label: 'New Password',
                      icon: Icons.lock,
                      child: TextField(
                        controller: _passwordController,
                        obscureText: !_showPassword,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          hintText: 'Enter new password',
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _showPassword = !_showPassword;
                              });
                            },
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _RecoveryField(
                      label: 'Confirm Password',
                      icon: Icons.lock_outline,
                      child: TextField(
                        controller: _confirmPasswordController,
                        obscureText: !_showPassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _updatePassword(),
                        decoration: const InputDecoration(
                          hintText: 'Confirm new password',
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updatePassword,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Text('Update Password'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: widget.onCancel,
                      child: const Text(
                        'Cancel recovery',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecoveryField extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget child;

  const _RecoveryField({
    required this.label,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Icon(icon, size: 18, color: const Color(0xFF9CA3AF)),
            ),
            Expanded(child: child),
          ],
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.82),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFC7D2FE).withOpacity(0.6),
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
                  Color(0xFF818CF8),
                  Color(0xFFA855F7),
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
                  color: Color(0xFF6B7280),
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
    const Color active = Color(0xFF4F46E5);
    const Color inactive = Color(0xFF6B7280);

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