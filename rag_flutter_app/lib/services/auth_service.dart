import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;


  User? getCurrentuser(){
    return _firebaseAuth.currentUser;
  }

  signInWithGoogle() async {
    //begin Interactive signin process
    final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();

    //obtain auth details from request 
    final GoogleSignInAuthentication gAuth = await gUser!.authentication;

    //create a new credential for user
    final credential = GoogleAuthProvider.credential(
      accessToken: gAuth.accessToken,
      idToken: gAuth.idToken,
    );

    //finally sign in!
    return await _firebaseAuth.signInWithCredential(credential);
  }


}

