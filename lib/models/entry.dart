enum EntryType { pastEvent, futurePlan, note }

const categoryOptions = [
  'Fitness',
  'Health',
  'Nutrition',
  'Work',
  'Personal',
  'Travel',
  'Shopping',
  'Finance',
  'Other',
];

class Entry {
  final String id;
  final EntryType type;
  String title;
  String content;
  final DateTime createdAt;
  DateTime? eventDate;
  DateTime? notificationTime;
  List<String> photoPaths;
  bool isCompleted;
  String? category;

  Entry({
    required this.id,
    required this.type,
    required this.title,
    this.content = '',
    required this.createdAt,
    this.eventDate,
    this.notificationTime,
    List<String>? photoPaths,
    this.isCompleted = false,
    this.category,
  }) : photoPaths = photoPaths ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'eventDate': eventDate?.toIso8601String(),
        'notificationTime': notificationTime?.toIso8601String(),
        'photoPaths': photoPaths,
        'isCompleted': isCompleted,
        'category': category,
      };

  factory Entry.fromJson(Map<String, dynamic> json) => Entry(
        id: json['id'] as String,
        type: EntryType.values.firstWhere((e) => e.name == json['type']),
        title: json['title'] as String,
        content: json['content'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
        eventDate: json['eventDate'] != null
            ? DateTime.parse(json['eventDate'] as String)
            : null,
        notificationTime: json['notificationTime'] != null
            ? DateTime.parse(json['notificationTime'] as String)
            : null,
        photoPaths: List<String>.from(json['photoPaths'] as List? ?? []),
        isCompleted: json['isCompleted'] as bool? ?? false,
        category: json['category'] as String?,
      );

  Entry copyWith({
    String? title,
    String? content,
    DateTime? eventDate,
    DateTime? notificationTime,
    List<String>? photoPaths,
    bool? isCompleted,
    String? category,
  }) =>
      Entry(
        id: id,
        type: type,
        title: title ?? this.title,
        content: content ?? this.content,
        createdAt: createdAt,
        eventDate: eventDate ?? this.eventDate,
        notificationTime: notificationTime ?? this.notificationTime,
        photoPaths: photoPaths ?? List.from(this.photoPaths),
        isCompleted: isCompleted ?? this.isCompleted,
        category: category ?? this.category,
      );

  String get typeLabel {
    switch (type) {
      case EntryType.pastEvent:
        return 'Past Event';
      case EntryType.futurePlan:
        return 'Plan';
      case EntryType.note:
        return 'Note';
    }
  }
}
