import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:online_voting/HomeScreen.dart';

class DasboardScreen extends StatefulWidget {
  final bool hasVoted; // ✅ Pass the voting status in the constructor
  DasboardScreen({required this.hasVoted});

  @override
  _PollScreenState createState() => _PollScreenState();
}

class _PollScreenState extends State<DasboardScreen> {
  final DatabaseReference _pollRef = FirebaseDatabase.instance.ref().child('polls');
  final DatabaseReference _voteRef = FirebaseDatabase.instance.ref().child('votes');
  Map<String, bool> clickedMap = {}; // Store click state for each poll
  bool isVotingDisabled = false; // Disable all voting after one selection

  @override
  void initState() {
    super.initState();
    isVotingDisabled = widget.hasVoted; // ✅ Disable voting if already voted
    _checkUserVoteStatus();
  }

  // ✅ Check if the user has already voted
  void _checkUserVoteStatus() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    DatabaseEvent event = await _voteRef.once();
    if (event.snapshot.value != null) {
      Map<dynamic, dynamic> votes = event.snapshot.value as Map<dynamic, dynamic>;

      bool hasVoted = false;
      votes.forEach((pollId, users) {
        if (users is Map && users.containsKey(uid)) {
          hasVoted = true;
          clickedMap[pollId] = true; // ✅ Mark this poll as voted
        }
      });

      if (hasVoted) {
        setState(() {
          isVotingDisabled = true; // ✅ Disable voting globally
        });
      }
    }
  }

  // ✅ Function to handle voting (Prevents multiple votes)
  void _votePoll(String id) async {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    // ✅ Check if the user has already voted
    DatabaseEvent event = await _voteRef.child(id).child(uid).once();
    if (event.snapshot.value != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ You have already voted!")),
      );
      return;
    }

    if (clickedMap[id] == true || isVotingDisabled) return; // Prevent multiple votes

    // ✅ Get the current vote count
    DatabaseEvent voteEvent = await _pollRef.child(id).child("votes").once();
    int currentVotes = voteEvent.snapshot.value != null ? (voteEvent.snapshot.value as int) : 0;

    // ✅ Update the vote count
    await _voteRef.child(id).child(uid).set(true); // ✅ Store user's vote
    await _pollRef.child(id).update({'votes': currentVotes + 1});

    setState(() {
      clickedMap[id] = true;
      isVotingDisabled = true; // ✅ Disable voting for all items
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ Your vote has been successfully recorded!")),
    );
  }

  // ✅ Logout function
  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Homescreen()));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ Successfully logged out!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🎉 Welcome to Online Voting 🎉'),
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
            padding: const EdgeInsets.all(20),
          ),
          Expanded(
            child: StreamBuilder(
              stream: _pollRef.onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                  return Center(child: Text('🚫 No polls available!'));
                }

                Map<dynamic, dynamic> polls =
                (snapshot.data!.snapshot.value as Map<dynamic, dynamic>);
                List<Map<String, dynamic>> pollList = polls.entries.map((e) => {
                  'id': e.key,
                  'question': e.value['question'],
                }).toList();

                return ListView.builder(
                  itemCount: pollList.length,
                  itemBuilder: (context, index) {
                    String id = pollList[index]['id']!;
                    String question = pollList[index]['question']!;
                    bool clicked = clickedMap[id] ?? false;

                    return Card(
                      elevation: 5,
                      margin: EdgeInsets.all(10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        title: Text(
                          question,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        subtitle: clicked
                            ? Text(
                          "✅ You have already voted!",
                          style: TextStyle(color: Colors.green, fontSize: 16),
                        )
                            : Text(
                          "❌ You have not voted yet",
                          style: TextStyle(color: Colors.red, fontSize: 16),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.thumb_up,
                            color: clicked ? Colors.green : Colors.grey,
                            size: 30,
                          ),
                          onPressed: isVotingDisabled ? null : () => _votePoll(id),
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
