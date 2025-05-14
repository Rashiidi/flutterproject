import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:project/firebase_options.dart';
import 'package:project/screens/admin_dashboard.dart';
import 'package:project/screens/ngo_dashboard.dart';
import 'package:project/screens/user_dashboard.dart';
import 'screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Role Login',
      theme: ThemeData(useMaterial3: true),
      initialRoute:
          FirebaseAuth.instance.currentUser == null ? '/login' : '/home',
      routes: {
        '/login': (context) => LoginScreen(),
        '/admin': (context) => const AdminHome(),
        '/user': (context) => const UserHome(),
        '/ngo': (context) => const NgoHome(),
      },
      home: LoginScreen(),
    );
  }
}