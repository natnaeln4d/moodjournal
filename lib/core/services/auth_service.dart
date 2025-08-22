import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../data/models/user_model.dart';

abstract class AuthObserver {
  void onAuthStateChanged(AppUser? user);
}

class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<AuthObserver> _observers = [];
  Rx<AppUser?> user = Rx<AppUser?>(null);

  void addObserver(AuthObserver observer) {
    _observers.add(observer);
  }

  void removeObserver(AuthObserver observer) {
    _observers.remove(observer);
  }

  void _notifyObservers() {
    for (var observer in _observers) {
      observer.onAuthStateChanged(user.value);
    }
  }

  @override
  void onInit() {
    _auth.authStateChanges().listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        // Get our AppUser from Firestore
        final appUser = await _getOrCreateUser(firebaseUser);
        user.value = appUser;
      } else {
        user.value = null;
      }
      _notifyObservers();
    });
    super.onInit();
  }

  Future<AppUser> _getOrCreateUser(User firebaseUser) async {
    try {
      final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (doc.exists) {
        await _firestore.collection('users').doc(firebaseUser.uid).update({
          'lastLogin': Timestamp.now(),
        });

        return AppUser.fromFirestore(doc);
      } else {
        final newUser = AppUser.fromFirebaseUser(firebaseUser);
        await _firestore.collection('users').doc(firebaseUser.uid).set(newUser.toFirestore());
        return newUser;
      }
    } catch (e) {
      print('Error getting/creating user: $e');
      // Fallback to creating user from Firebase data only
      return AppUser.fromFirebaseUser(firebaseUser);
    }
  }

  Future<AppUser?> signUpWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        return await _getOrCreateUser(result.user!);
      }
      return null;
    } catch (e) {
      print('Sign Up Error: $e');
      rethrow;
    }
  }

  Future<AppUser?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        return await _getOrCreateUser(result.user!);
      }
      return null;
    } catch (e) {
      print('Sign In Error: $e');
      rethrow;
    }
  }

  Future<void> updateUser(AppUser updatedUser) async {
    try {
      await _firestore.collection('users').doc(updatedUser.id).update(updatedUser.toFirestore());
      user.value = updatedUser;
      _notifyObservers();
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  Future<void> addPoints(int points) async {
    if (user.value != null) {
      final updatedUser = user.value!.copyWith(points: user.value!.points + points);
      await updateUser(updatedUser);
    }
  }

  Future<void> incrementStreak() async {
    if (user.value != null) {
      final updatedUser = user.value!.copyWith(streak: user.value!.streak + 1);
      await updateUser(updatedUser);
    }
  }

  Future<void> resetStreak() async {
    if (user.value != null) {
      final updatedUser = user.value!.copyWith(streak: 0);
      await updateUser(updatedUser);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}