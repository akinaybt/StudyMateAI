import 'package:flutter/material.dart';
import '_ui.dart';

class PracticeCardData {
  final String question;
  final String answer;
  final String source;

  const PracticeCardData({required this.question, required this.answer, required this.source});
}

class CardsScreen extends StatefulWidget {
  final VoidCallback onBack;
  const CardsScreen({super.key, required this.onBack});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  final cards = const [
    PracticeCardData(
      question: 'What is Artificial Intelligence?',
      answer:
          'AI is the simulation of human intelligence processes by machines, especially computer systems. These processes include learning, reasoning, and self-correction.',
      source: 'Introduction to AI.pdf',
    ),
    PracticeCardData(
      question: 'What are the main types of Machine Learning?',
      answer:
          'The three main types are: Supervised Learning (labeled data), Unsupervised Learning (unlabeled data), and Reinforcement Learning (reward-based learning).',
      source: 'Machine Learning Lecture',
    ),
    PracticeCardData(
      question: 'What is a Neural Network?',
      answer:
          'A neural network is a series of algorithms that attempts to recognize underlying relationships in data through a process that mimics the way the human brain operates.',
      source: 'Neural Networks Notes.pdf',
    ),
    PracticeCardData(
      question: 'What is the difference between AI and Machine Learning?',
      answer:
          'AI is the broader concept of machines being able to carry out tasks intelligently. Machine Learning is a subset of AI that enables machines to learn from data without being explicitly programmed.',
      source: 'Introduction to AI.pdf',
    ),
  ];

  int index = 0;
  bool flipped = false;

  void next() {
    setState(() {
      flipped = false;
      if (index < cards.length - 1) index++;
    });
  }

  void prev() {
    setState(() {
      flipped = false;
      if (index > 0) index--;
    });
  }

  @override
  Widget build(BuildContext context) {
    final card = cards[index];

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
              const Text('Practice Cards', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
              const SizedBox(height: 6),
              const Text('Review AI-generated flashcards from your materials', style: TextStyle(color: Color(0xFF6B7280))),
              const SizedBox(height: 16),

              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: const Color(0xFFE0E7FF), borderRadius: BorderRadius.circular(999)),
                  child: Text(
                    'Card ${index + 1} of ${cards.length}',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF3730A3)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _FlipCard(
                flipped: flipped,
                onTap: () => setState(() => flipped = !flipped),
                front: _CardFace(
                  gradient: const [Color(0xFFEFF6FF), Color(0xFFE0E7FF)],
                  border: const Color(0xFFC7D2FE),
                  iconBg: const Color(0xFF4F46E5),
                  icon: Icons.menu_book,
                  title: card.question,
                  hint: 'Tap to reveal answer',
                  hintColor: const Color(0xFF4F46E5),
                ),
                back: _CardFace(
                  gradient: const [Color(0xFFF5F3FF), Color(0xFFFCE7F3)],
                  border: const Color(0xFFE9D5FF),
                  iconBg: const Color(0xFFA855F7),
                  icon: Icons.description,
                  title: card.answer,
                  hint: 'Tap to see question',
                  hintColor: const Color(0xFFA855F7),
                  isParagraph: true,
                ),
              ),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFE0E7FF), borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    const Icon(Icons.description, size: 18, color: Color(0xFF4F46E5)),
                    const SizedBox(width: 8),
                    const Text('Source:', style: TextStyle(color: Color(0xFF374151))),
                    const Spacer(),
                    Text(card.source, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: index == 0 ? null : prev,
                      icon: const Icon(Icons.chevron_left),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: const BorderSide(color: Color(0xFFC7D2FE)),
                        foregroundColor: const Color(0xFF4F46E5),
                      ),
                      label: const Text('Previous', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: index == cards.length - 1 ? null : next,
                      icon: const Text(''),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                      ),
                      label: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Next', style: TextStyle(fontWeight: FontWeight.w800)),
                          SizedBox(width: 6),
                          Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('All Practice Cards', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
              const SizedBox(height: 12),
              ...List.generate(cards.length, (i) {
                final c = cards[i];
                final active = i == index;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      index = i;
                      flipped = false;
                    }),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(14),
                      backgroundColor: active ? const Color(0xFFE0E7FF) : const Color(0xFFF3F4F6),
                      side: BorderSide(color: active ? const Color(0xFFC7D2FE) : const Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: active ? const Color(0xFF4F46E5) : const Color(0xFF9CA3AF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.question, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
                              const SizedBox(height: 4),
                              Text(c.source, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                            ],
                          ),
                        ),
                        if (active)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: Color(0xFF4F46E5), shape: BoxShape.circle),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        )
      ],
    );
  }
}

class _FlipCard extends StatelessWidget {
  final bool flipped;
  final VoidCallback onTap;
  final Widget front;
  final Widget back;

  const _FlipCard({
    required this.flipped,
    required this.onTap,
    required this.front,
    required this.back,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: flipped ? 1 : 0),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOut,
        builder: (context, t, _) {
          final angle = 3.1415926535 * t;
          final isBack = angle > 3.1415926535 / 2;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: isBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(3.1415926535),
                    child: back,
                  )
                : front,
          );
        },
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  final List<Color> gradient;
  final Color border;
  final Color iconBg;
  final IconData icon;
  final String title;
  final String hint;
  final Color hintColor;
  final bool isParagraph;

  const _CardFace({
    required this.gradient,
    required this.border,
    required this.iconBg,
    required this.icon,
    required this.title,
    required this.hint,
    required this.hintColor,
    this.isParagraph = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 340),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: iconBg,
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isParagraph ? 14 : 18,
              height: 1.35,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.rotate_right, size: 18, color: hintColor),
              const SizedBox(width: 8),
              Text(hint, style: TextStyle(fontWeight: FontWeight.w700, color: hintColor)),
            ],
          ),
        ],
      ),
    );
  }
}