class Mood {
  final String id;
  final String userId;
  final String moodType; // 'happy', 'sad', 'neutral'
  final DateTime timestamp;
  final String? note;

  Mood({
    required this.id,
    required this.userId,
    required this.moodType,
    required this.timestamp,
    this.note,
  });

  factory Mood.fromMap(Map<String, dynamic> map) {
    return Mood(
      id: map['id'],
      userId: map['userId'],
      moodType: map['moodType'],
      timestamp: DateTime.parse(map['timestamp']),
      note: map['note'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'moodType': moodType,
      'timestamp': timestamp.toIso8601String(),
      'note': note,
    };
  }
}