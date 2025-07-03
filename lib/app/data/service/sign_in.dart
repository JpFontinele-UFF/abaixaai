import 'package:abaixaai/app/data/model/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignInService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  SignInService();

  _createUserDoc() async {
    try {
      DocumentReference documentReference = FirebaseFirestore.instance.doc(
        '/users/${FirebaseAuth.instance.currentUser!.uid}',
      );
      DocumentSnapshot documentSnapshot = await documentReference.get();
      if (documentSnapshot.exists) return;

      await documentReference.set({
        'created_at': DateTime.now(),
        'updated_at': DateTime.now(),
        'email': FirebaseAuth.instance.currentUser!.email,
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        debugPrint('Permission denied: ${e.message}');
      } else {
        debugPrint('Error: ${e.message}');
      }
    }
  }

  Future<UserModel?> signInGoogle() async {
    var account = await _googleSignIn.signIn();
    var b = await account!.authentication;
    final authCredential = GoogleAuthProvider.credential(
      accessToken: b.accessToken,
      idToken: b.idToken,
    );
    try {
      var u = await FirebaseAuth.instance.signInWithCredential(authCredential);
      await _createUserDoc();
      return UserModel.fromFirebase(account);
    } catch (err) {
      debugPrint(err.toString());
    }
    return null;
  }

  Future<UserModel?> trySignInGoogle() async {
    var account = await _googleSignIn.signInSilently();
    if (account == null) {
      return null;
    }
    var b = await account.authentication;
    final authCredential = GoogleAuthProvider.credential(
      accessToken: b.accessToken,
      idToken: b.idToken,
    );
    try {
      var u = await FirebaseAuth.instance.signInWithCredential(authCredential);
      await _createUserDoc();
      return UserModel.fromFirebase(account);
    } catch (err) {
      debugPrint(err.toString());
    }
    return null;
  }

  logoutGoogle() async {
    await _googleSignIn.signOut();
    await FirebaseAuth.instance.signOut();
  }
}
