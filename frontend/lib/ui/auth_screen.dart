import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '_ui.dart';

enum AuthMode { login, register }

const String _passwordResetRedirectUrl = 'studymate://reset-password';

class AuthScreen extends StatefulWidget {
  final VoidCallback onLoggedIn;
  const AuthScreen({super.key, required this.onLoggedIn});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  AuthMode _mode = AuthMode.login;
  bool _showPassword = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please enter your email and password.');
      return;
    }

    if (_mode == AuthMode.register && name.isEmpty) {
      _showMessage('Please enter your full name.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_mode == AuthMode.login) {
        final response = await _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (response.session != null) {
          widget.onLoggedIn();
        } else {
          _showMessage('Login failed. Please try again.');
        }
      } else {
        final response = await _supabase.auth.signUp(
          email: email,
          password: password,
          data: {
            'full_name': name,
          },
        );

        if (response.session != null) {
          widget.onLoggedIn();
        } else {
          _showMessage(
            'Account created.',
          );

          if (!mounted) return;
          setState(() {
            _mode = AuthMode.login;
          });
        }
      }
    } on AuthException catch (e) {
      _showMessage(e.message);
    } catch (e) {
      _showMessage('Something went wrong: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showMessage('Please enter your email first.');
      return;
    }

    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: _passwordResetRedirectUrl,
      );
      _showMessage('Password reset email sent.');
    } on AuthException catch (e) {
      _showMessage(e.message);
    } catch (e) {
      _showMessage('Could not send reset email: $e');
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
                child: const Icon(Icons.school, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 14),
              const Text(
                'StudyMate AI',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your Intelligent Academic Companion',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
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
                        child: TextField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            hintText: 'Enter your name',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    _LabeledField(
                      label: 'Email',
                      icon: Icons.mail,
                      child: TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          hintText: 'Enter your email',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _LabeledField(
                      label: 'Password',
                      icon: Icons.lock,
                      child: TextField(
                        controller: _passwordController,
                        obscureText: !_showPassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          suffixIcon: IconButton(
                            onPressed: () => setState(() {
                              _showPassword = !_showPassword;
                            }),
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_mode == AuthMode.login) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Spacer(),
                          TextButton(
                            onPressed: _resetPassword,
                            child: const Text(
                              'Forgot password?',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
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
                            : Text(
                          _mode == AuthMode.login
                              ? 'Log In'
                              : 'Create Account',
                        ),
                      ),
                    ),
                    if (_mode == AuthMode.register) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'By registering, you agree to our Terms of Service and Privacy Policy',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
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
                    Text(
                      'Why StudyMate AI?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    SizedBox(height: 10),
                    _Bullet(
                      text: 'AI-powered study summaries',
                      color: Color(0xFF4F46E5),
                    ),
                    _Bullet(
                      text: 'Real-time lecture transcription',
                      color: Color(0xFFA855F7),
                    ),
                    _Bullet(
                      text: 'Practice questions generation',
                      color: Color(0xFFEC4899),
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

class _SegmentButton extends StatelessWidget {
  final String text;
  final bool active;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.text,
    required this.active,
    required this.onTap,
  });

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

  const _LabeledField({
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
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ),
        ],
      ),
    );
  }
}