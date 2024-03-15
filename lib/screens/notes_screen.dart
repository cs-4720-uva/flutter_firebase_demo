import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<StatefulWidget> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  late User _user;
  final _newNoteController = TextEditingController();
  bool _userNotesOnlySwitch = false;

  @override
  void initState() {
    _user = FirebaseAuth.instance.currentUser!;
  }

  Stream<QuerySnapshot> _allNotes() {
    return FirebaseFirestore.instance.collection("notes").snapshots();
  }

  Stream<QuerySnapshot> _userNotes() {
    return FirebaseFirestore.instance
        .collection("notes")
        .where("author", isEqualTo: _user.email)
        .snapshots();
  }

  void _saveNote() async {
    var noteText = _newNoteController.text;
    FirebaseFirestore.instance.collection("notes").add({
      "note": noteText,
      "votes": 0,
      "author": _user.email,
    }).then((value) {
      _newNoteController.text = "";
      var snackBar = const SnackBar(
        content: Text("Note Added!"),
        duration: Duration(seconds: 3),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Signed in!"),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text("Welcome, ${_user.email}"),
              TextField(
                  controller: _newNoteController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(), hintText: "New Note")),
              TextButton(onPressed: _saveNote, child: const Text("Save")),
              switchRow(),
              firestoreNotesList(),
            ]),
      ),
    );
  }

  Widget switchRow() {
    return
      Row(
        children: [
          const Text("Show personal notes: "),
          Switch(
            value: _userNotesOnlySwitch,
            onChanged: (bool value) {
              setState(() {
                _userNotesOnlySwitch = value;
              });
            }),
        ]
      );
  }

  Widget firestoreNotesList() {
    return StreamBuilder(
        stream: _userNotesOnlySwitch ? _userNotes() : _allNotes(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text("Something went wrong!");
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Text("Loading");
          }
          return ListView.builder(
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) =>
                  noteView(snapshot.data!.docs[index]));
        } //builder
        );
  }

  Widget noteView(DocumentSnapshot doc) {
    return Row(
      children: [
        Text(doc["note"]),
        const VerticalDivider(thickness: 15),
        Text(doc["votes"].toString()),
        const VerticalDivider(thickness: 15),
        IconButton(
            onPressed: () => _incrementVote(doc),
            icon: const Icon(Icons.thumb_up)),
        if (_user.email == doc["author"])
          IconButton(
              onPressed: () => _deleteNote(doc),
              icon: const Icon(Icons.delete_outline)),
      ],
    );
  }

  void _deleteNote(DocumentSnapshot doc) {
    FirebaseFirestore.instance.collection("notes").doc(doc.id).delete();
  }

  void _incrementVote(DocumentSnapshot doc) {
    FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot freshSnap = await transaction.get(doc.reference);
      await transaction
          .update(freshSnap.reference, {"votes": freshSnap["votes"] + 1});
    });
  }

  @override
  void dispose() {
    FirebaseAuth.instance.signOut();
    super.dispose();
  }
}
