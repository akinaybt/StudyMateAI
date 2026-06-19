import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '_ui.dart';
import '../services/api_service.dart';

class LectureScreen extends StatefulWidget {
  final VoidCallback onBack;
  const LectureScreen({super.key, required this.onBack});

  @override
  State<LectureScreen> createState() => _LectureScreenState();
}

class _LectureScreenState extends State<LectureScreen> {
  static const String _bucketName = 'documents';

  final SupabaseClient _supabase = Supabase.instance.client;
  final ApiService _apiService = const ApiService();
  final AudioRecorder _recorder = AudioRecorder();

  bool _recording = false;
  bool _loading = false;

  String? _recordingPath;
  String? _summary;
  String? _transcript;

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();

    if (!hasPermission) {
      _showMessage('Microphone permission is required.');
      return;
    }

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/lecture_${DateTime.now().millisecondsSinceEpoch}.m4a';

    try {
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );

      if (!mounted) return;
      setState(() {
        _recording = true;
        _recordingPath = path;
        _summary = null;
        _transcript = null;
      });
    } catch (e) {
      _showMessage('Could not start recording: $e');
    }
  }

  Future<void> _stopRecordAndSummarize() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      _showMessage('Please log in first.');
      return;
    }

    if (!mounted) return;
    setState(() {
      _recording = false;
      _loading = true;
    });

    try {
      final path = await _recorder.stop();

      if (path == null || path.isEmpty) {
        throw Exception('Recording file was not created.');
      }

      final file = File(path);
      final fileName = 'lecture_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final storagePath = '${user.id}/lectures/$fileName';

      await _supabase.storage.from(_bucketName).upload(
        storagePath,
        file,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: false,
          contentType: 'audio/m4a',
        ),
      );

      final result = await _apiService.getLectureSummary(
        storagePath: storagePath,
        fileName: fileName,
        contentType: 'audio/m4a',
      );

      if (!mounted) return;
      setState(() {
        _summary = result['summary']?.toString() ?? 'No summary returned.';
        _transcript = result['transcript']?.toString();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showMessage('Could not summarize lecture: $e');
    }
  }

  Future<void> _handleRecordButton() async {
    if (_loading) return;

    if (_recording) {
      await _stopRecordAndSummarize();
    } else {
      await _startRecording();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasTranscript = _transcript != null && _transcript!.trim().isNotEmpty;
    final hasSummary = _summary != null && _summary!.trim().isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 92),
      children: [
        TextButton.icon(
          onPressed: widget.onBack,
          icon: const Icon(Icons.chevron_left),
          label: const Text('Back'),
        ),

        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _recording
                  ? const [
                Color(0xFFFFF1F2),
                Color(0xFFFCE7F3),
                Color(0xFFF5F3FF),
              ]
                  : const [
                Color(0xFFF8FAFF),
                Color(0xFFEFF6FF),
                Color(0xFFF5F3FF),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFFC7D2FE).withValues(alpha: 0.55),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4F46E5).withValues(alpha:0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _recording
                              ? const [Color(0xFFF87171), Color(0xFFEC4899)]
                              : const [Color(0xFF818CF8), Color(0xFFA855F7)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: (_recording
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF6366F1))
                                .withValues(alpha:0.20),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.mic, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lecture Summary',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Record your lecture and get a transcript with an AI summary.',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                Center(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        width: 148,
                        height: 148,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _recording
                                ? const [Color(0xFFF87171), Color(0xFFEC4899)]
                                : const [Color(0xFFC084FC), Color(0xFF6366F1)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_recording
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF6366F1))
                                  .withValues(alpha:0.25),
                              blurRadius: 28,
                              spreadRadius: 2,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 200),
                          scale: _recording ? 1.05 : 1.0,
                          child: Icon(
                            _recording ? Icons.stop : Icons.mic,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _handleRecordButton,
                          icon: Icon(_recording ? Icons.stop : Icons.play_arrow),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _recording
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 14,
                            ),
                            elevation: 0,
                          ),
                          label: Text(
                            _recording ? 'Stop & Summarize' : 'Start Recording',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha:0.72),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFC7D2FE).withValues(alpha:0.55),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: _recording
                                    ? const Color(0xFFFEE2E2)
                                    : const Color(0xFFE0E7FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _recording ? Icons.fiber_manual_record : Icons.info_outline,
                                size: 20,
                                color: _recording
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFF4F46E5),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _loading
                                    ? 'Transcribing and summarizing...'
                                    : _recording
                                    ? 'Recording is active. Stop when you finish speaking.'
                                    : 'Tap start to record audio and generate transcript + summary.',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF374151),
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                if (_loading) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha:0.75),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFC7D2FE).withValues(alpha:0.5),
                      ),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Processing lecture with Groq AI...',
                            style: TextStyle(
                              color: Color(0xFF374151),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (hasSummary) ...[
                  const SizedBox(height: 16),
                  _ResultCard(
                    title: 'AI Summary',
                    icon: Icons.summarize,
                    accent: const Color(0xFF4F46E5),
                    background: const [Color(0xFFF8FAFF), Color(0xFFEFF6FF)],
                    text: _summary!,
                  ),
                ],

                if (hasTranscript) ...[
                  const SizedBox(height: 14),
                  _ResultCard(
                    title: 'Transcript',
                    icon: Icons.text_snippet_outlined,
                    accent: const Color(0xFF9333EA),
                    background: const [Color(0xFFFCF7FF), Color(0xFFF3E8FF)],
                    text: _transcript!,
                  ),
                ],
              ],
            ),
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
                icon: Icons.upload_file,
                text: 'Audio is uploaded to your Supabase bucket',
                bg: Color(0xFFDBEAFE),
                fg: Color(0xFF2563EB),
              ),
              _StepRow(
                icon: Icons.auto_awesome,
                text: 'Groq turns the audio into text',
                bg: Color(0xFFF3E8FF),
                fg: Color(0xFF9333EA),
              ),
              _StepRow(
                icon: Icons.summarize,
                text: 'AI writes a clean study summary',
                bg: Color(0xFFFCE7F3),
                fg: Color(0xFFDB2777),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accent;
  final List<Color> background;
  final String text;

  const _ResultCard({
    required this.title,
    required this.icon,
    required this.accent,
    required this.background,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: background,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha:0.12)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha:0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha:0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: accent),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: const TextStyle(
              height: 1.45,
              color: Color(0xFF374151),
              fontSize: 13.5,
            ),
          ),
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
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: fg),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF374151),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
