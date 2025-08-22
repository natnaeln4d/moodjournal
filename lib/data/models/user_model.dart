import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastLogin;
  final int points;
  final int streak;
  final Map<String, dynamic> achievements;
  final Map<String, dynamic> preferences;

  AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
    required this.lastLogin,
    this.points = 0,
    this.streak = 0,
    this.achievements = const {},
    this.preferences = const {},
  });

  // Convert Firebase User to our AppUser
  factory AppUser.fromFirebaseUser(User user) {
    return AppUser(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
      points: 0,
      streak: 0,
      achievements: {},
      preferences: {
        'notifications': true,
        'darkMode': false,
        'dailyReminder': true,
      },
    );
  }

  // Convert from Firestore document
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AppUser(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate() ?? DateTime.now(),
      points: data['points'] ?? 0,
      streak: data['streak'] ?? 0,
      achievements: Map<String, dynamic>.from(data['achievements'] ?? {}),
      preferences: Map<String, dynamic>.from(data['preferences'] ?? {}),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': Timestamp.fromDate(lastLogin),
      'points': points,
      'streak': streak,
      'achievements': achievements,
      'preferences': preferences,
    };
  }

  // Copy with method for updates
  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLogin,
    int? points,
    int? streak,
    Map<String, dynamic>? achievements,
    Map<String, dynamic>? preferences,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      points: points ?? this.points,
      streak: streak ?? this.streak,
      achievements: achievements ?? this.achievements,
      preferences: preferences ?? this.preferences,
    );
  }
}