import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'study_mate_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://szisrcnkdosfquevxmqd.supabase.co',
    anonKey: 'sb_publishable_5DQ-lA4GKI-SiBDetVkqMg_PZWQNe1j',
  );
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
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => const StudyMateApp(),
        );
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => const StudyMateApp(),
        );
      },
    );
  }
}
