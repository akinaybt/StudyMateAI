class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'STUDYMATE_API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );

  static String get uploadEndpoint => '$baseUrl/upload';
  static String get summaryEndpoint => '$baseUrl/summary';
  static String get flashcardsEndpoint => '$baseUrl/flashcards';
  static String get lectureSummaryEndpoint => '$baseUrl/lecture-summary';
}
