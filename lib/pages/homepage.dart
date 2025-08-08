import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:todolist/services/firestore.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final FirestoreService firestoreService = FirestoreService();

  //Text Controller
  final TextEditingController textController = TextEditingController();

  //open a dialog box to add a note
  void openNoteBox({String? docID, String? currentNote}) {
    if (currentNote != null) {
      textController.text = currentNote;
    } else {
      textController.clear();
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            actionsAlignment: MainAxisAlignment.center,
            content: TextField(controller: textController),
            actions: [
              ElevatedButton(
                onPressed: () {
                  //add a new note
                  if (docID == null) {
                    firestoreService.addNote(textController.text);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Note Created"),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    firestoreService.updateNote(docID, textController.text);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Note Updated"),
                        backgroundColor: Colors.blue,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }

                  //clear the text controller
                  textController.clear();

                  //close the box
                  Navigator.pop(context);
                },
                child: Text("Add"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blueGrey,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("T O D O  L I S T", style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: openNoteBox,
          child: Icon(Icons.add),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: firestoreService.getNotesStream(),
          builder: (context, snapshot) {
            //if we have data , get all docs
            if (snapshot.hasData) {
              List notesList = snapshot.data!.docs;

              //display as a List
              return ListView.builder(
                itemCount: notesList.length,
                itemBuilder: (context, index) {
                  //get each individual doc
                  DocumentSnapshot document = notesList[index];
                  String docID = document.id;

                  //get note from each doc
                  Map<String, dynamic> data =
                      document.data() as Map<String, dynamic>;
                  String noteText = data['note'];
                  Timestamp? timestamp = data['timestamp'] as Timestamp?;
                  String noteDate = "";
                  String noteTime = "";
                  if (timestamp != null) {
                    DateTime dateTime =
                        timestamp
                            .toDate(); // Convert Firestore Timestamp to Dart DateTime
                    noteDate = dateTime.toString().substring(0, 10);
                    noteTime = dateTime.toString().substring(11, 16);
                  }

                  //display as a listTile
                  return ListTile(
                    title: Text(noteText),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Date: ${noteDate}"),
                        Text("Time: ${noteTime}"),
                      ],
                    ),

                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        //Update Note
                        IconButton(
                          onPressed:
                              () => openNoteBox(
                                docID: docID,
                                currentNote: noteText,
                              ),
                          icon: Icon(Icons.settings),
                        ),

                        //Delete Note
                        IconButton(
                          onPressed: () {
                            firestoreService.deletNote(docID);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Note Deleted"),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: Icon(Icons.delete),
                        ),
                      ],
                    ),
                  );
                },
              );
            } else {
              return Text("There's no notes");
            }
          },
        ),
      ),
    );
  }
}
