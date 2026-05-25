import 'package:flutter/material.dart';
import '_ui.dart';

class UploadScreen extends StatelessWidget {
  final VoidCallback onBack;
  const UploadScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 92),
      children: [
        TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.chevron_left),
          label: const Text('Back'),
        ),
        const GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Upload Materials', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
              SizedBox(height: 6),
              Text('Upload lecture slides, notes, or readings', style: TextStyle(color: Color(0xFF6B7280))),
              SizedBox(height: 16),
              _UploadArea(),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('What happens next?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
              SizedBox(height: 12),
              _StepRow(icon: Icons.menu_book, text: 'AI analyzes your content', bg: Color(0xFFDBEAFE), fg: Color(0xFF2563EB)),
              _StepRow(icon: Icons.description, text: 'Generates concise summaries', bg: Color(0xFFE0E7FF), fg: Color(0xFF4F46E5)),
              _StepRow(icon: Icons.school, text: 'Creates practice questions', bg: Color(0xFFF3E8FF), fg: Color(0xFF9333EA)),
            ],
          ),
        ),
      ],
    );
  }
}

class _UploadArea extends StatelessWidget {
  const _UploadArea();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF).withOpacity(0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC7D2FE), width: 2, style: BorderStyle.solid),
      ),
      child: Column(
        children: const [
          CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFFE0E7FF),
            child: Icon(Icons.upload, size: 28, color: Color(0xFF4F46E5)),
          ),
          SizedBox(height: 10),
          Text('Drop files here or click to browse', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
          SizedBox(height: 6),
          Text('Supports PDF, DOCX, PPT, and more', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color bg;
  final Color fg;
  const _StepRow({required this.icon, required this.text, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20, color: fg),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF374151)))),
        ],
      ),
    );
  }
}