import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/Friend_Provider.dart';
import '../utils/color.dart';  // Import your FriendProvider

class FriendsPage extends StatelessWidget {
  final TextEditingController _usernameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final friendProvider = Provider.of<FriendProvider>(context);  // Access the provider

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xff003039),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search Friends',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        hintText: 'Enter Username',
                        hintStyle: TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white10,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.white54,
                        ),
                      ),
                      style: TextStyle(color: Colors.white),
                      onChanged: (value) => friendProvider.searchFriends(value),
                    ),
                    SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: friendProvider.displayedFriendsList.length,
                        itemBuilder: (context, index) {
                          final friend = friendProvider.displayedFriendsList[index];
                          final name = friend['name'];

                          return ListTile(
                            leading: CircleAvatar(
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                              ),
                              backgroundColor: Colors.blue,
                            ),
                            title: Text(name, style: TextStyle(color: Colors.white)),
                            trailing: IconButton(
                              icon: Icon(
                                friendProvider.addedFriends.contains(name) ? Icons.check_circle : Icons.add_circle,
                                color: friendProvider.addedFriends.contains(name) ? Colors.blue : Colors.green,
                              ),
                              onPressed: () {
                                if (!friendProvider.addedFriends.contains(name)) {
                                  friendProvider.addFriend(name);
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xff003039),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Added Friends (${friendProvider.addedFriends.length})',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Expanded(
                      child: friendProvider.addedFriends.isEmpty
                          ? Center(
                        child: Text(
                          'No friends added',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      )
                          : ListView.builder(
                        itemCount: friendProvider.addedFriends.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: CircleAvatar(
                              child: Icon(Icons.person, color: Colors.white),
                              backgroundColor: Colors.blue,
                            ),
                            title: Text(
                              friendProvider.addedFriends[index],
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                        },
                      ),
                    ),
                    if (friendProvider.getErrorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          friendProvider.getErrorMessage!,
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
