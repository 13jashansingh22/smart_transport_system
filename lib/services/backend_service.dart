import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'user_profile_context_service.dart';

class BackendService {
  BackendService._();

  static final BackendService instance = BackendService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _profiles =>
      _firestore.collection('user_profiles');

  Future<UserCredential> createPassengerAccount({
    required String email,
    required String password,
    required String state,
    required String city,
    required String town,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _syncProfile(
      credential.user,
      role: 'passenger',
      state: state,
      city: city,
      town: town,
      email: email,
    );
    return credential;
  }

  Future<UserCredential> signInAndSyncProfile({
    required String role,
    required String email,
    required String password,
    required String state,
    required String city,
    required String town,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _syncProfile(
      credential.user,
      role: role,
      state: state,
      city: city,
      town: town,
      email: email,
    );
    return credential;
  }

  Future<void> _syncProfile(
    User? user, {
    required String role,
    required String state,
    required String city,
    required String town,
    required String email,
  }) async {
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No authenticated user found after backend sign-in.',
      );
    }

    final profile = UserProfileContext(
      role: role,
      state: state,
      city: city,
      town: town,
      email: email,
    );

    await Future.wait([
      _profiles.doc(user.uid).set(
        {
          'uid': user.uid,
          'role': profile.role,
          'state': profile.state,
          'city': profile.city,
          'town': profile.town,
          'email': profile.email,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      ),
      UserProfileContextService.save(
        role: profile.role,
        state: profile.state,
        city: profile.city,
        town: profile.town,
        email: profile.email,
      ),
    ]);
  }

  Future<UserProfileContext?> loadActiveProfile() async {
    final local = await UserProfileContextService.read();
    if (local != null) {
      return local;
    }

    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }

    final snapshot = await _profiles.doc(user.uid).get();
    if (!snapshot.exists) {
      return null;
    }

    final data = snapshot.data();
    if (data == null) {
      return null;
    }

    final role = (data['role'] as String?)?.trim();
    final state = (data['state'] as String?)?.trim();
    final city = (data['city'] as String?)?.trim();
    final town = (data['town'] as String?)?.trim();
    final email = (data['email'] as String?)?.trim();

    if (role == null || state == null || city == null || town == null) {
      return null;
    }

    final profile = UserProfileContext(
      role: role,
      state: state,
      city: city,
      town: town,
      email: email ?? user.email ?? '',
    );

    await UserProfileContextService.save(
      role: profile.role,
      state: profile.state,
      city: profile.city,
      town: profile.town,
      email: profile.email,
    );

    return profile;
  }
}

