import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  Future<UserCredential?> SigninWithGoogle() async {
    try {
      UserCredential? authResult; // Declare authResult here

      // Start interactive sign-in process
      final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();

      if (gUser != null) {
        // Obtain auth details from the request
        final GoogleSignInAuthentication gAuth = await gUser.authentication;

        // Create new credentials for the user
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: gAuth.accessToken,
          idToken: gAuth.idToken,
        );

        // Finally, sign in
        authResult =
            await FirebaseAuth.instance.signInWithCredential(credential);

        final User? user = authResult.user;

        if (user != null) {
          // Store additional user information in Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'name': user.displayName,
            'email': user.email,
          });
        }
      }

      return authResult;
    } catch (error) {
      print(error);
    }
  }
}
