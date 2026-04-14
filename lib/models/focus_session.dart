class FocusSession {
  final String id;
  final int durationMinutes;
  final String? label;
  final DateTime completedAt;

  const FocusSession({
    required this.id,
    required this.durationMinutes,
    this.label,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'durationMinutes': durationMinutes,
        if (label != null) 'label': label,
        'completedAt': completedAt.toIso8601String(),
      };

  factory FocusSession.fromJson(Map<String, dynamic> j) => FocusSession(
        id: j['id'] as String,
        durationMinutes: j['durationMinutes'] as int,
        label: j['label'] as String?,
        completedAt: DateTime.parse(j['completedAt'] as String),
      );
}
