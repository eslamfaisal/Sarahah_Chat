import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_facebook_login_with_web/flutter_facebook_login_with_web.dart';
import 'package:http/http.dart' as h;
import 'package:sarahah_chat/model/auth_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  static final FacebookLogin _fblogin = FacebookLogin();
  FacebookLoginStatus loginStatus;
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<dynamic> signInWithFacebook() async {
    print('begin');
    SharedPreferences userInfo = await SharedPreferences.getInstance();
    final result = await _fblogin.logIn(['email', 'public_profile']);
    switch (result.status) {
      case FacebookLoginStatus.loggedIn:
        loginStatus = result.status;
        final FacebookAccessToken accessToken = result.accessToken;
        AuthCredential fbCredential =
            FacebookAuthProvider.credential(accessToken.token);
        FirebaseAuth.instance
            .signInWithCredential(fbCredential)
            .then((user) async {
          userInfo.setString('firebaseUID', user.user.uid);
          var graphResponse = await h.get(
              'https://graph.facebook.com/v2.12/me?fields=name,first_name,last_name,email,picture.height(200)&access_token=${result.accessToken.token}');
          var profile = json.decode(graphResponse.body);
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(user.user.uid)
              .set(
                AuthModel().toMap(
                  AuthModel(
                    fierbaseUID: user.user.uid,
                    facebookUID: profile['id'],
                    name: profile['name'],
                    email: profile['email'],
                    photoUrl: profile['picture']['data']['url'],
                  ),
                ),
              );
        });
        break;
      case FacebookLoginStatus.cancelledByUser:
        loginStatus = result.status;
        print('Login cancelled by the user.');
        break;
      case FacebookLoginStatus.loggedIn:
        loginStatus = result.status;
        print('Something went wrong with the login process.\n'
            'Here\'s the error Facebook gave us: ${result.errorMessage}');
        break;
      default:
    }
    print('end');
  }
}
