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
    super.initState();
  }

  Stream<QuerySnapshot> _allNotes() {
    return FirebaseFirestore.instance.collection("notes").snapshots();
  }

  Stream<QuerySnapshot> _userNotes() {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(_user.uid)
        .collection("private_notes")
        .snapshots();
  }

  void _saveNote() async {
    var noteText = _newNoteController.text;

    FirebaseFirestore.instance.collection("notes").add({
      "note": noteText,
      "liked_by": <String>[],
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

  void _savePrivateNote() async {
    var noteText = _newNoteController.text;
    FirebaseFirestore.instance
        .collection("users")
        .doc(_user.uid)
        .collection("private_notes")
        .add({
      "note": noteText,
      "author": _user.email,
      "liked_by": <String>[]
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
              TextButton(
                  onPressed: _savePrivateNote,
                  child: const Text("Save as Private Note")),
              switchRow(),
              firestoreNotesList(),
            ]),
      ),
    );
  }

  Widget switchRow() {
    return Row(children: [
      const Text("Show personal notes: "),
      Switch(
          value: _userNotesOnlySwitch,
          onChanged: (bool value) {
            setState(() {
              _userNotesOnlySwitch = value;
            });
          }),
    ]);
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
        if (!_userNotesOnlySwitch) Text("${_likeCount(doc)}"),
        if (!_userNotesOnlySwitch) const VerticalDivider(thickness: 15),
        if (!_userNotesOnlySwitch)
          IconButton(
              onPressed: () => _toggleLike(doc),
              icon: Icon(
                  _isLiked(doc) ? Icons.thumb_up
                      : Icons.thumb_up_outlined)),
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

  void _toggleLike(DocumentSnapshot doc) {
    FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot freshSnap = await transaction.get(doc.reference);
      if (_isLiked(doc)) {
        transaction.update(freshSnap.reference, {
          "liked_by": FieldValue.arrayRemove([_user.uid])
        });
      } else {
        transaction.update(freshSnap.reference, {
          "liked_by": FieldValue.arrayUnion([_user.uid])
        });
      }
    });
  }

  @override
  void dispose() {
    FirebaseAuth.instance.signOut();
    super.dispose();
  }

  bool _isLiked(DocumentSnapshot doc) {
    List likedBy = doc["liked_by"];
    return likedBy.contains(_user.uid);
  }

  int _likeCount(DocumentSnapshot doc) {
    List likedBy = doc["liked_by"];
    return likedBy.length;
  }
}
