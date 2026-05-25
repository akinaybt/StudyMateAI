import 'package:flutter/material.dart';
import '_ui.dart';

class LectureScreen extends StatefulWidget {
  final VoidCallback onBack;
  const LectureScreen({super.key, required this.onBack});

  @override
  State<LectureScreen> createState() => _LectureScreenState();
}

class _LectureScreenState extends State<LectureScreen> {
  bool _recording = false;

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
              const Text('Live Lecture Capture', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
              const SizedBox(height: 6),
              const Text('Real-time transcription and intelligent summarization', style: TextStyle(color: Color(0xFF6B7280))),
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
                      child: const Icon(Icons.mic, size: 56, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _recording = !_recording),
                      icon: Icon(_recording ? Icons.stop : Icons.play_arrow),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _recording ? const Color(0xFFEF4444) : const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      ),
                      label: Text(_recording ? 'Stop Recording' : 'Start Recording'),
                    ),
                    if (_recording) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Live Transcription:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
                            SizedBox(height: 6),
                            Text(
                              '"Today we\'re going to discuss artificial intelligence and its applications in modern computing..."',
                              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                    ],
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
              Text('Features', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
              SizedBox(height: 10),
              _Dot(text: 'Real-time speech transcription'),
              _Dot(text: 'Automatic summarization'),
              _Dot(text: 'Key points extraction'),
              _Dot(text: 'Save & review later'),
            ],
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final String text;
  const _Dot({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF4F46E5), shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF374151)))),
        ],
      ),
    );
  }
}