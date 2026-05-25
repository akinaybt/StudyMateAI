import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'study_mate_app.dart';

void main() {
  runApp(const StudyMateAppRoot());
}

class StudyMateAppRoot extends StatelessWidget {
  const StudyMateAppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudyMate AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const StudyMateApp(),
    );
  }
}