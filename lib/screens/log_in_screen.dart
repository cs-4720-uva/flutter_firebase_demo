import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase_demo/screens/notes_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, required this.title});
  final String title;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailFieldController = TextEditingController();
  final _passwordFieldController = TextEditingController();
  String _statusLabel = "";

  void _signIn() async {
    var result = "";
    try {
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: _emailFieldController.text,
        password: _passwordFieldController.text,
      );
      result = "Logged In - ${credential.user?.email}";
      if (!mounted) return;
      Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotesScreen())
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        result = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        result = 'Wrong password provided for that user.';
      } else {
        result = e.code;
      }
    } catch (e) {
      result = e.toString();
    }
    setState(() {
      _statusLabel = result;
    });
  }

  void _createUser() async {
    var result = "";
    try {
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailFieldController.text,
        password: _passwordFieldController.text,
      );
      result = "User Created!";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        result = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        result = 'The account already exists for that email.';
      } else if (e.code == 'invalid-email'){
        result = 'Bad email format...';
      } else {
        result = e.code;
      }
    } catch (e) {
      result = e.toString();
    }
    setState(() {
      _statusLabel = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Email"
              ),
              controller: _emailFieldController,
            ),
            TextField(
              decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Password"
              ),
              obscureText: true,
              controller: _passwordFieldController,
            ),
            TextButton(onPressed: _signIn, child: const Text("Sign-in")),
            TextButton(onPressed: _createUser, child: const Text("Create User")),
            Text(_statusLabel),
          ],
        ),
      ),
     );
  }
}