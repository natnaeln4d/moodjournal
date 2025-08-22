class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final DateTime unlockedAt;
  final bool isUnlocked;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.unlockedAt,
    required this.isUnlocked,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'unlockedAt': unlockedAt.millisecondsSinceEpoch,
      'isUnlocked': isUnlocked,
    };
  }

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      icon: map['icon'],
      unlockedAt: DateTime.fromMillisecondsSinceEpoch(map['unlockedAt']),
      isUnlocked: map['isUnlocked'],
    );
  }
}