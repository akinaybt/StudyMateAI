import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '_ui.dart';

enum AuthMode { login, register }

class AuthScreen extends StatefulWidget {
  final VoidCallback onLoggedIn;
  const AuthScreen({super.key, required this.onLoggedIn});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  AuthMode _mode = AuthMode.login;
  bool _showPassword = false;

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
                child: const Icon(Icons.school, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 14),
              const Text('StudyMate AI', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
              const SizedBox(height: 6),
              const Text('Your Intelligent Academic Companion', style: TextStyle(color: Color(0xFF6B7280))),
              const SizedBox(height: 22),

              GlassCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _SegmentButton(
                            text: 'Log In',
                            active: _mode == AuthMode.login,
                            onTap: () => setState(() => _mode = AuthMode.login),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SegmentButton(
                            text: 'Register',
                            active: _mode == AuthMode.register,
                            onTap: () => setState(() => _mode = AuthMode.register),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_mode == AuthMode.register) ...[
                      _LabeledField(
                        label: 'Full Name',
                        icon: Icons.person,
                        child: const TextField(decoration: InputDecoration(hintText: 'Enter your name')),
                      ),
                      const SizedBox(height: 12),
                    ],

                    _LabeledField(
                      label: 'Email',
                      icon: Icons.mail,
                      child: const TextField(
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(hintText: 'Enter your email'),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _LabeledField(
                      label: 'Password',
                      icon: Icons.lock,
                      child: TextField(
                        obscureText: !_showPassword,
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _showPassword = !_showPassword),
                            icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                          ),
                        ),
                      ),
                    ),

                    if (_mode == AuthMode.login) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Checkbox(value: false, onChanged: (_) {}),
                          const Text('Remember me', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                          const Spacer(),
                          TextButton(
                            onPressed: () {},
                            child: const Text('Forgot password?', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: widget.onLoggedIn,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                        ),
                        child: Text(_mode == AuthMode.login ? 'Log In' : 'Create Account'),
                      ),
                    ),

                    if (_mode == AuthMode.register) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'By registering, you agree to our Terms of Service and Privacy Policy',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Why StudyMate AI?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
                    SizedBox(height: 10),
                    _Bullet(text: 'AI-powered study summaries', color: Color(0xFF4F46E5)),
                    _Bullet(text: 'Real-time lecture transcription', color: Color(0xFFA855F7)),
                    _Bullet(text: 'Practice questions generation', color: Color(0xFFEC4899)),
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

class _SegmentButton extends StatelessWidget {
  final String text;
  final bool active;
  final VoidCallback onTap;

  const _SegmentButton({required this.text, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg = active
        ? const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFA855F7)])
        : null;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: bg,
          color: active ? null : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget child;

  const _LabeledField({required this.label, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
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

class _Bullet extends StatelessWidget {
  final String text;
  final Color color;
  const _Bullet({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
        ],
      ),
    );
  }
}