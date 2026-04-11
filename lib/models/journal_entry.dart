const Map<int, String> kMoodEmojis = {
  1: '😞',
  2: '😕',
  3: '😐',
  4: '🙂',
  5: '😄',
};

class JournalEntry {
  final String id;
  final String dateKey; // YYYY-MM-DD local — one entry per day
  final int mood; // 1–5
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Health snapshot — saved at write time so past entries show historical data
  final int? steps;
  final double? heartRate;
  final double? sleepHours;
  final double? calories;
  final double? spo2;

  const JournalEntry({
    required this.id,
    required this.dateKey,
    required this.mood,
    this.content = '',
    required this.createdAt,
    required this.updatedAt,
    this.steps,
    this.heartRate,
    this.sleepHours,
    this.calories,
    this.spo2,
  });

  bool get hasHealthData =>
      steps != null || heartRate != null || sleepHours != null ||
      calories != null || spo2 != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'dateKey': dateKey,
        'mood': mood,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        if (steps != null) 'steps': steps,
        if (heartRate != null) 'heartRate': heartRate,
        if (sleepHours != null) 'sleepHours': sleepHours,
        if (calories != null) 'calories': calories,
        if (spo2 != null) 'spo2': spo2,
      };

  factory JournalEntry.fromJson(Map<String, dynamic> j) => JournalEntry(
        id: j['id'] as String,
        dateKey: j['dateKey'] as String,
        mood: j['mood'] as int? ?? 3,
        content: j['content'] as String? ?? '',
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
        steps: j['steps'] as int?,
        heartRate: (j['heartRate'] as num?)?.toDouble(),
        sleepHours: (j['sleepHours'] as num?)?.toDouble(),
        calories: (j['calories'] as num?)?.toDouble(),
        spo2: (j['spo2'] as num?)?.toDouble(),
      );

  JournalEntry copyWith({
    int? mood,
    String? content,
    DateTime? updatedAt,
    int? steps,
    double? heartRate,
    double? sleepHours,
    double? calories,
    double? spo2,
  }) =>
      JournalEntry(
        id: id,
        dateKey: dateKey,
        mood: mood ?? this.mood,
        content: content ?? this.content,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        steps: steps ?? this.steps,
        heartRate: heartRate ?? this.heartRate,
        sleepHours: sleepHours ?? this.sleepHours,
        calories: calories ?? this.calories,
        spo2: spo2 ?? this.spo2,
      );

  String get moodEmoji => kMoodEmojis[mood] ?? '😐';
}
