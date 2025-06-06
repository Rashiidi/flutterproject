// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAxeb90ykLKVWbNXPrEET5OoL5sLiglYZg',
    appId: '1:669116782391:web:0dc40a5443385d9a6fecb2',
    messagingSenderId: '669116782391',
    projectId: 'flutterproject-63906',
    authDomain: 'flutterproject-63906.firebaseapp.com',
    databaseURL: 'https://flutterproject-63906-default-rtdb.firebaseio.com',
    storageBucket: 'flutterproject-63906.firebasestorage.app',
    measurementId: 'G-JES1JZF5VF',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDPi3C1Sm0B4u5x7BnMywp1ZiHvpMG88ik',
    appId: '1:669116782391:android:f4283935e9bfecf86fecb2',
    messagingSenderId: '669116782391',
    projectId: 'flutterproject-63906',
    databaseURL: 'https://flutterproject-63906-default-rtdb.firebaseio.com',
    storageBucket: 'flutterproject-63906.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCELg_n3Z9OUiHyl3NARrq4mP2OYusTh9w',
    appId: '1:669116782391:ios:077a91d64437a8166fecb2',
    messagingSenderId: '669116782391',
    projectId: 'flutterproject-63906',
    databaseURL: 'https://flutterproject-63906-default-rtdb.firebaseio.com',
    storageBucket: 'flutterproject-63906.firebasestorage.app',
    iosBundleId: 'com.example.project',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCELg_n3Z9OUiHyl3NARrq4mP2OYusTh9w',
    appId: '1:669116782391:ios:077a91d64437a8166fecb2',
    messagingSenderId: '669116782391',
    projectId: 'flutterproject-63906',
    databaseURL: 'https://flutterproject-63906-default-rtdb.firebaseio.com',
    storageBucket: 'flutterproject-63906.firebasestorage.app',
    iosBundleId: 'com.example.project',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAxeb90ykLKVWbNXPrEET5OoL5sLiglYZg',
    appId: '1:669116782391:web:57e34960dc43dfb06fecb2',
    messagingSenderId: '669116782391',
    projectId: 'flutterproject-63906',
    authDomain: 'flutterproject-63906.firebaseapp.com',
    databaseURL: 'https://flutterproject-63906-default-rtdb.firebaseio.com',
    storageBucket: 'flutterproject-63906.firebasestorage.app',
    measurementId: 'G-WZLB9QG5Q8',
  );
}
