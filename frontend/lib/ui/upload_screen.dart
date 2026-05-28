import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '_ui.dart';

class UploadScreen extends StatefulWidget {
  final VoidCallback onBack;
  const UploadScreen({super.key, required this.onBack});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

enum UploadActionView { none, summary, quiz }

class _UploadScreenState extends State<UploadScreen> {
  PlatformFile? _picked;
  bool _loading = false;

  UploadActionView _view = UploadActionView.none;
  String? _summaryText;
  String? _quizText;

  Future<void> _pickFile() async {
    try {
      setState(() {
        _loading = true;
        _view = UploadActionView.none;
        _summaryText = null;
        _quizText = null;
      });

      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: false,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'txt'],
      );

      if (!mounted) return;

      if (result == null || result.files.isEmpty) {
        setState(() => _loading = false);
        return; // user cancelled
      }

      setState(() {
        _picked = result.files.first;
        _loading = false;
      });

      // If you need an actual "upload to server", we can do it here.
      // For now, "uploaded" == "selected on device".
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick file: $e')),
      );
    }
  }

  Future<void> _generateSummary() async {
    if (_picked == null) return;

    setState(() {
      _loading = true;
      _view = UploadActionView.summary;
    });

    // MOCK: replace later with backend call.
    await Future<void>.delayed(const Duration(milliseconds: 700));

    setState(() {
      _summaryText =
      'Summary for "${_picked!.name}"\n\n'
          '- Main topic: Artificial Intelligence basics\n'
          '- Key ideas: learning, reasoning, neural networks\n'
          '- Takeaway: AI is a broad field; ML is a subset\n';
      _loading = false;
    });
  }

  Future<void> _generateQuiz() async {
    if (_picked == null) return;

    setState(() {
      _loading = true;
      _view = UploadActionView.quiz;
    });

    // MOCK: replace later with backend call.
    await Future<void>.delayed(const Duration(milliseconds: 700));

    setState(() {
      _quizText =
      'Practice Questions for "${_picked!.name}"\n\n'
          '1) Define Artificial Intelligence.\n'
          '2) What is the difference between AI and Machine Learning?\n'
          '3) Name 3 types of Machine Learning.\n'
          '4) What is a neural network?\n';
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasFile = _picked != null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 92),
      children: [
        TextButton.icon(
          onPressed: widget.onBack,
          icon: const Icon(Icons.chevron_left),
          label: const Text('Back'),
        ),

        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upload Materials',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Upload lecture slides, notes, or readings',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 16),

              // Clickable upload area
              _UploadArea(
                loading: _loading,
                fileName: _picked?.name,
                onTap: _loading ? null : _pickFile,
              ),

              if (hasFile) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _loading ? null : _generateSummary,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: const BorderSide(color: Color(0xFFC7D2FE)),
                          foregroundColor: const Color(0xFF4F46E5),
                        ),
                        child: const Text(
                          'Summary',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _loading ? null : _generateQuiz,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Practice questions',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              if (_loading) ...[
                const SizedBox(height: 14),
                const Center(child: CircularProgressIndicator()),
              ],

              if (_view == UploadActionView.summary && _summaryText != null) ...[
                const SizedBox(height: 14),
                _ResultBox(title: 'Summary', text: _summaryText!),
              ],

              if (_view == UploadActionView.quiz && _quizText != null) ...[
                const SizedBox(height: 14),
                _ResultBox(title: 'Practice Questions', text: _quizText!),
              ],
            ],
          ),
        ),

        const SizedBox(height: 14),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'What happens next?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2937),
                ),
              ),
              SizedBox(height: 12),
              _StepRow(
                icon: Icons.menu_book,
                text: 'AI analyzes your content',
                bg: Color(0xFFDBEAFE),
                fg: Color(0xFF2563EB),
              ),
              _StepRow(
                icon: Icons.description,
                text: 'Generates concise summaries',
                bg: Color(0xFFE0E7FF),
                fg: Color(0xFF4F46E5),
              ),
              _StepRow(
                icon: Icons.school,
                text: 'Creates practice questions',
                bg: Color(0xFFF3E8FF),
                fg: Color(0xFF9333EA),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UploadArea extends StatelessWidget {
  final bool loading;
  final String? fileName;
  final VoidCallback? onTap;

  const _UploadArea({
    required this.loading,
    required this.fileName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasFile = fileName != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF).withOpacity(0.35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFC7D2FE),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFFE0E7FF),
              child: Icon(
                hasFile ? Icons.check : Icons.upload,
                size: 28,
                color: const Color(0xFF4F46E5),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              loading
                  ? 'Opening file picker...'
                  : hasFile
                  ? 'Selected: $fileName'
                  : 'Drop files here or click to\nbrowse',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Supports PDF, DOCX, PPT, and more',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultBox extends StatelessWidget {
  final String title;
  final String text;

  const _ResultBox({required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC7D2FE).withOpacity(0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(height: 1.35)),
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

  const _StepRow({
    required this.icon,
    required this.text,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: fg),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
            ),
          ),
        ],
      ),
    );
  }
}
