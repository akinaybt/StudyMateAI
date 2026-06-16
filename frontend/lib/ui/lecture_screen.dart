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
  }

  Future<void> _stopRecordAndSummarize() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      _showMessage('Please log in first.');
      return;
    }

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
                'Lecture Summary',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Record your lecture, then generate a summary',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _recording
                              ? const [Color(0xFFF87171), Color(0xFFEC4899)]
                              : const [Color(0xFFC084FC), Color(0xFF6366F1)],
                        ),
                      ),
                      child: Icon(
                        _recording ? Icons.stop : Icons.mic,
                        size: 56,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loading ? null : _handleRecordButton,
                      icon: Icon(_recording ? Icons.stop : Icons.mic),
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
                          vertical: 12,
                        ),
                      ),
                      label: Text(
                        _recording ? 'Stop & Summarize' : 'Start Recording',
                      ),
                    ),
                    if (_loading) ...[
                      const SizedBox(height: 14),
                      const CircularProgressIndicator(),
                      const SizedBox(height: 8),
                      const Text('Transcribing and summarizing...'),
                    ],
                  ],
                ),
              ),
              if (_summary != null) ...[
                const SizedBox(height: 18),
                _ResultBox(title: 'Summary', text: _summary!),
              ],
              if (_transcript != null) ...[
                const SizedBox(height: 12),
                _ResultBox(title: 'Transcript', text: _transcript!),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ResultBox extends StatelessWidget {
  final String title;
  final String text;

  const _ResultBox({
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFC7D2FE).withOpacity(0.55),
        ),
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
