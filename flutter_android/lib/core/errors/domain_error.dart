/// Standardized domain error matching `docs/API_CONTRACT.md` Section 2.
class AppDomainError implements Exception {
  final String code;
  final int status;
  final String message;
  final Map<String, dynamic>? details;

  const AppDomainError({
    required this.code,
    required this.message,
    this.status = 400,
    this.details,
  });

  @override
  String toString() => '[$code] $message';
}
