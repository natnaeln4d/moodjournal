
class AppConstants {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://default.api.com',
  );
  static const String geminiApiKey = String.fromEnvironment(
       'GEMINI_API_KEY',
       defaultValue:env.geminiApiKey
  );

}
