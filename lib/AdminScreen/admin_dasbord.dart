import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:online_voting/AdminScreen/adminScreen.dart';

class PollScreen extends StatefulWidget {
  @override
  _PollScreenState createState() => _PollScreenState();
}

class _PollScreenState extends State<PollScreen> {
  final DatabaseReference _pollRef = FirebaseDatabase.instance.ref().child('polls');
  final DatabaseReference _voteRef = FirebaseDatabase.instance.ref().child('votes');
  final TextEditingController _pollController = TextEditingController();

  // ✅ Function to create a new poll
  void _createPoll() {
    if (_pollController.text.isNotEmpty) {
      String pollId = _pollRef.push().key!; // Generate unique poll ID
      _pollRef.child(pollId).set({
        'id': pollId,
        'question': _pollController.text,
      });
      _pollController.clear(); // Clear input field after submission
    }
  }

  // ✅ Function to delete a poll
  void _deletePoll(String id) {
    _pollRef.child(id).remove(); // Remove poll from database
    _voteRef.child(id).remove(); // Remove associated votes
  }

  // ✅ Function to update an existing poll
  void _updatePoll(String id, String newQuestion) {
    _pollRef.child(id).update({'question': newQuestion});
  }

  // ✅ Logout function
  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => Adminscreen()), // Navigate to Admin screen
    );
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Logout successful!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Poll System'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: Icon(Icons.logout, color: Colors.red),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _pollController,
              decoration: InputDecoration(
                labelText: 'Enter Poll Question', // Input field for poll question
                suffixIcon: IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _createPoll, // Calls the function to create a poll
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: _pollRef.onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                  return Center(child: Text('No polls available'));
                }

                // ✅ Extract polls data from Firebase
                Map<dynamic, dynamic> polls =
                (snapshot.data!.snapshot.value as Map<dynamic, dynamic>);
                List<Map<String, dynamic>> pollList = polls.entries.map((e) => {
                  'id': e.key,
                  'question': e.value['question'],
                  'votes': e.value['votes'] ?? 0, // Default votes to 0 if null
                }).toList();

                return ListView.builder(
                  itemCount: pollList.length,
                  itemBuilder: (context, index) {
                    String id = pollList[index]['id']!;
                    String question = pollList[index]['question']!;
                    int votes = pollList[index]['votes']!;
                    TextEditingController _editController =
                    TextEditingController(text: question);

                    return Card(
                      child: ListTile(
                        title: Text(question), // Display poll question
                        subtitle: Text('Votes: $votes'), // Display vote count
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ✅ Edit button
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Edit Poll'),
                                    content: TextField(
                                      controller: _editController,
                                      decoration:
                                      InputDecoration(labelText: 'Update Poll'),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          _updatePoll(id, _editController.text);
                                          Navigator.pop(context);
                                        },
                                        child: Text('Update'),
                                      )
                                    ],
                                  ),
                                );
                              },
                            ),
                            // ✅ Delete button
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () => _deletePoll(id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
