import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '_ui.dart';
import '../services/api_service.dart';

class UploadScreen extends StatefulWidget {
  final VoidCallback onBack;
  final ValueChanged<String> onDocumentUploaded;
  final ValueChanged<int> onFlashcardsGenerated;

  const UploadScreen({
    super.key,
    required this.onBack,
    required this.onDocumentUploaded,
    required this.onFlashcardsGenerated,
  });

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

enum UploadActionView { none, summary, quiz }

class _UploadScreenState extends State<UploadScreen> {
  static const String _bucketName = 'documents';

  final SupabaseClient _supabase = Supabase.instance.client;
  final ApiService _apiService = const ApiService();

  PlatformFile? _picked;
  bool _loading = false;

  UploadActionView _view = UploadActionView.none;
  String? _summaryText;
  String? _quizText;
  String? _storagePath;
  String? _documentId;

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _contentTypeForFile(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        throw Exception('Unsupported file type: $extension');
    }
  }

  Future<void> _uploadToBucket() async {
    final picked = _picked;
    if (picked == null) return;

    final user = _supabase.auth.currentUser;
    if (user == null) {
      _showMessage('Please log in before uploading files.');
      return;
    }

    final path = picked.path;
    if (path == null || path.isEmpty) {
      _showMessage('This file cannot be uploaded because its path is missing.');
      return;
    }

    final file = File(path);
    final storagePath =
        '${user.id}/${DateTime.now().millisecondsSinceEpoch}_${picked.name}';

    await _supabase.storage.from(_bucketName).upload(
      storagePath,
      file,
      fileOptions: const FileOptions(
        cacheControl: '3600',
        upsert: false,
      ),
    );

    final backendResponse = await _apiService.uploadDocument(
      storagePath: storagePath,
      fileName: picked.name,
      contentType: _contentTypeForFile(picked.name),
    );

    if (!mounted) return;
    setState(() {
      _storagePath = storagePath;
      _documentId = backendResponse['document_id']?.toString();
    });

    widget.onDocumentUploaded(picked.name);
  }

  Future<void> _pickFile() async {
    try {
      setState(() {
        _loading = true;
        _view = UploadActionView.none;
        _summaryText = null;
        _quizText = null;
        _storagePath = null;
        _documentId = null;
      });

      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: false,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'pptx'],
      );

      if (!mounted) return;

      if (result == null || result.files.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      final selectedFile = result.files.first;

      setState(() {
        _picked = selectedFile;
      });

      await _uploadToBucket();

      if (!mounted) return;
      setState(() => _loading = false);

      _showMessage('File uploaded to cloud storage.');
    } on StorageException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);

      _showMessage('Supabase upload failed: ${e.message}');
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);

      _showMessage('Failed to upload document: $e');
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);

      _showMessage('Failed to pick or upload file: $e');
    }
  }

  Future<void> _generateSummary() async {
    final documentId = _documentId;
    if (_picked == null || documentId == null) {
      _showMessage('Please upload a supported document first.');
      return;
    }

    setState(() {
      _loading = true;
      _view = UploadActionView.summary;
      _summaryText = null;
    });

    try {
      final result = await _apiService.getSummary(documentId);

      if (!mounted) return;
      setState(() {
        _summaryText = result['summary']?.toString() ?? 'No summary returned.';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showMessage('Summary generation failed: $e');
    }
  }

  Future<void> _generateQuiz() async {
    final documentId = _documentId;
    if (_picked == null || documentId == null) {
      _showMessage('Please upload a supported document first.');
      return;
    }

    setState(() {
      _loading = true;
      _view = UploadActionView.quiz;
    });

    try {
      final result = await _apiService.getFlashcards(documentId);
      final cards = (result['flashcards'] as List<dynamic>?) ?? const [];

      widget.onFlashcardsGenerated(cards.length);

      final buffer = StringBuffer();

      buffer.writeln('Practice Questions for "${_picked!.name}"');
      buffer.writeln();

      for (final card in cards) {
        if (card is Map<String, dynamic>) {
          final question = card['question']?.toString() ?? '';
          final answer = card['answer']?.toString() ?? '';
          if (question.isEmpty && answer.isEmpty) continue;
          buffer.writeln('- Q: $question');
          buffer.writeln('  A: $answer');
          buffer.writeln();
        }
      }

      if (!mounted) return;
      setState(() {
        _quizText = buffer.toString().trim().isEmpty
            ? 'No flashcards returned.'
            : buffer.toString().trim();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showMessage('Flashcards generation failed: $e');
    }
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
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: SizedBox(
                    width: double.infinity,
                    child: _UploadArea(
                      loading: _loading,
                      fileName: _picked?.name,
                      onTap: _loading ? null : _pickFile,
                    ),
                  ),
                ),
              ),
              if (_storagePath != null) ...[
                const SizedBox(height: 10),
                Text(
                  'Uploaded to bucket: $_storagePath',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
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
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _pickFile,
                    icon: const Icon(Icons.upload_file),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: const BorderSide(color: Color(0xFFC7D2FE)),
                      foregroundColor: const Color(0xFF4F46E5),
                    ),
                    label: const Text(
                      'Upload new document',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
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