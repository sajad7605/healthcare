class AppConfig {
  final String splashMessage;
  final String motd;
  final String appVersion;
  final String supportPhone;

  AppConfig({
    required this.splashMessage,
    required this.motd,
    required this.appVersion,
    required this.supportPhone,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      splashMessage: json['splashMessage'] as String? ?? 'به دندون‌یار خوش آمدید! 🦷',
      motd: json['motd'] as String? ?? '',
      appVersion: json['appVersion'] as String? ?? '1.0.0',
      supportPhone: json['supportPhone'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'splashMessage': splashMessage,
      'motd': motd,
      'appVersion': appVersion,
      'supportPhone': supportPhone,
    };
  }
}
