import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '_ui.dart';

class AccountScreen extends StatelessWidget {
  final VoidCallback onLogout;
  const AccountScreen({super.key, required this.onLogout});

  String _getDisplayName(User? user) {
    final metadata = user?.userMetadata ?? {};
    final fullName = metadata['full_name']?.toString().trim();
    if (fullName != null && fullName.isNotEmpty) {
      return fullName;
    }

    final email = user?.email ?? '';
    if (email.isNotEmpty) {
      return email.split('@').first;
    }

    return 'User';
  }

  String _getInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'U';
    if (parts.length == 1) {
      final word = parts.first;
      return word.isNotEmpty ? word[0].toUpperCase() : 'U';
    }

    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    final displayName = _getDisplayName(user);
    final email = user?.email ?? 'unknown@email.com';
    final initials = _getInitials(displayName);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 92),
      children: [
        GlassCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0xFF6366F1),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const _Pill(),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: onLogout,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: const Color(0xFFDC2626),
                        ),
                        icon: const Icon(Icons.logout, size: 16),
                        label: const Text(
                          'Log out',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Study Statistics',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2937),
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.description,
                      label: 'Documents',
                      value: '24',
                      bg: Color(0xFFEFF6FF),
                      iconBg: Color(0xFFDBEAFE),
                      iconColor: Color(0xFF2563EB),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.mic,
                      label: 'Lectures',
                      value: '12',
                      bg: Color(0xFFF5F3FF),
                      iconBg: Color(0xFFF3E8FF),
                      iconColor: Color(0xFF9333EA),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Account Settings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2937),
                ),
              ),
              SizedBox(height: 8),
              _SettingRow(
                icon: Icons.person,
                title: 'Edit Profile',
                subtitle: 'Update your personal information',
                bg: Color(0xFFDBEAFE),
                fg: Color(0xFF2563EB),
              ),
              _SettingRow(
                icon: Icons.notifications,
                title: 'Notifications',
                subtitle: 'Manage notification preferences',
                bg: Color(0xFFF3E8FF),
                fg: Color(0xFF9333EA),
              ),
              _SettingRow(
                icon: Icons.settings,
                title: 'Preferences',
                subtitle: 'Customize your study experience',
                bg: Color(0xFFE0E7FF),
                fg: Color(0xFF4F46E5),
              ),
              _SettingRow(
                icon: Icons.help,
                title: 'Help & Support',
                subtitle: 'Get assistance and tutorials',
                bg: Color(0xFFFCE7F3),
                fg: Color(0xFFEC4899),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: onLogout,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.all(16),
            side: BorderSide(color: Colors.red.withOpacity(0.20)),
            backgroundColor: Colors.white.withOpacity(0.90),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            foregroundColor: const Color(0xFFDC2626),
          ),
          icon: const Icon(Icons.logout),
          label: const Text(
            'Log Out',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFE0E7FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.emoji_events, size: 16, color: Color(0xFF4F46E5)),
            SizedBox(width: 6),
            Text(
              'Pro Member',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF3730A3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color bg;
  final Color iconBg;
  final Color iconColor;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.bg,
    required this.iconBg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color bg;
  final Color fg;

  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: fg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}