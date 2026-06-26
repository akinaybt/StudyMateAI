import 'package:flutter/material.dart';
import '../study_mate_app.dart';
import '_ui.dart';

class HomeScreen extends StatelessWidget {
  final void Function(AppTab) onNavigate;
  final String? uploadedDocumentName;
  final DateTime? uploadedDocumentAt;
  final int practiceCardCount;
  final String? lectureActivityTitle;
  final DateTime? lectureActivityAt;

  const HomeScreen({
    super.key,
    required this.onNavigate,
    this.uploadedDocumentName,
    this.uploadedDocumentAt,
    this.practiceCardCount = 0,
    this.lectureActivityTitle,
    this.lectureActivityAt,
  });

  String _relativeTime(DateTime? date) {
    if (date == null) return '';

    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 92),
      children: [
        const GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
              SizedBox(height: 6),
              Text('Choose how you\'d like to study today', style: TextStyle(color: Color(0xFF6B7280))),
            ],
          ),
        ),
        const SizedBox(height: 14),

        _FeatureCard(
          title: 'Upload Materials',
          subtitle: 'Get summaries & practice questions',
          icon: Icons.upload_file,
          iconBg1: const Color(0xFFDBEAFE),
          iconBg2: const Color(0xFFE0E7FF),
          iconColor: const Color(0xFF4F46E5),
          onTap: () => onNavigate(AppTab.upload),
        ),
        const SizedBox(height: 12),
        _FeatureCard(
          title: 'Live Lecture Capture',
          subtitle: 'Real-time transcription & notes',
          icon: Icons.mic,
          iconBg1: const Color(0xFFF3E8FF),
          iconBg2: const Color(0xFFFCE7F3),
          iconColor: const Color(0xFF9333EA),
          onTap: () => onNavigate(AppTab.lecture),
        ),
        const SizedBox(height: 14),

        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Practice Cards', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
                  const Spacer(),
                  TextButton(
                    onPressed: () => onNavigate(AppTab.cards),
                    child: const Row(
                      children: [
                        Text('View All'),
                        SizedBox(width: 4),
                        Icon(Icons.chevron_right, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFEEF2FF), Color(0xFFF5F3FF)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.style, size: 42, color: Color(0xFF4F46E5)),
                    const SizedBox(height: 8),
                    Text(
                      '$practiceCardCount',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      practiceCardCount == 0
                          ? 'No cards generated yet'
                          : 'Cards ready to study',
                      style: const TextStyle(color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => onNavigate(AppTab.cards),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Start Studying'),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Recent Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
              const SizedBox(height: 10),
              if (uploadedDocumentName == null && lectureActivityTitle == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No recent activity yet',
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                ),
              ...[
                if (uploadedDocumentName != null)
                  (uploadedDocumentName!, true, _relativeTime(uploadedDocumentAt)),
                if (lectureActivityTitle != null)
                  (lectureActivityTitle!, false, _relativeTime(lectureActivityAt)),
              ].map((item)  {
                final title = item.$1;
                final isDoc = item.$2;
                final time = item.$3;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {},
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isDoc ? const Color(0xFFDBEAFE) : const Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(isDoc ? Icons.description : Icons.mic, color: isDoc ? const Color(0xFF2563EB) : const Color(0xFF9333EA)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
                                const SizedBox(height: 2),
                                Text(time, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBg1;
  final Color iconBg2;
  final Color iconColor;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBg1,
    required this.iconBg2,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [iconBg1, iconBg2]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 28, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
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