import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/Friend_Provider.dart';

class FriendsPage extends StatelessWidget {
  final TextEditingController _usernameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final friendProvider = Provider.of<FriendProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // Set base font size and adjust for mobile view
    double baseFontSize = 18;
    double adjustedFontSize = screenWidth < 600 ? baseFontSize * 0.7 : baseFontSize;

    // Adjust icon size based on screen width
    double baseIconSize = 24;
    double adjustedIconSize = screenWidth < 600 ? baseIconSize * 0.8 : baseIconSize;

    return Scaffold(

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Check if the available width is less than 600 pixels (mobile view)
            if (constraints.maxWidth < 600) {
              return Column(
                children: [

                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(8),
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
                              fontSize: adjustedFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
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
                                size: adjustedIconSize,
                              ),
                            ),
                            style: TextStyle(color: Colors.white, fontSize: adjustedFontSize),
                            onChanged: (value) => friendProvider.searchFriends(value),
                          ),
                          SizedBox(height: 8),
                          Expanded(
                            child: ListView.builder(
                              itemCount: friendProvider.displayedFriendsList.length,
                              itemBuilder: (context, index) {
                                final friend = friendProvider.displayedFriendsList[index];
                                final name = friend['name'];

                                return ListTile(
                                  contentPadding: EdgeInsets.symmetric(vertical: 0),
                                  leading: CircleAvatar(
                                    child: Icon(Icons.person, color: Colors.white, size: adjustedIconSize),
                                    backgroundColor: Colors.blue,
                                  ),
                                  title: Text(
                                    name,
                                    style: TextStyle(color: Colors.white, fontSize: adjustedFontSize),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      friendProvider.addedFriends.contains(name) ? Icons.check_circle : Icons.add_circle,
                                      color: friendProvider.addedFriends.contains(name) ? Colors.blue : Colors.green,
                                      size: adjustedIconSize,
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
                  SizedBox(height: 16), // Space between containers
                  // Added Friends Container
                  Expanded(
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
                              fontSize: adjustedFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 8),
                          friendProvider.buildAddedFriendsList(context),
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
              );
            } else { // Web view
              return Row(
                children: [
                  // Search Friends Container
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: EdgeInsets.all(8),
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
                              fontSize: adjustedFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
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
                                size: adjustedIconSize,
                              ),
                            ),
                            style: TextStyle(color: Colors.white, fontSize: adjustedFontSize),
                            onChanged: (value) => friendProvider.searchFriends(value),
                          ),
                          SizedBox(height: 8),
                          Expanded(
                            child: ListView.builder(
                              itemCount: friendProvider.displayedFriendsList.length,
                              itemBuilder: (context, index) {
                                final friend = friendProvider.displayedFriendsList[index];
                                final name = friend['name'];

                                return ListTile(
                                  contentPadding: EdgeInsets.symmetric(vertical: 0),
                                  leading: CircleAvatar(
                                    child: Icon(Icons.person, color: Colors.white, size: adjustedIconSize),
                                    backgroundColor: Colors.blue,
                                  ),
                                  title: Text(
                                    name,
                                    style: TextStyle(color: Colors.white, fontSize: adjustedFontSize),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      friendProvider.addedFriends.contains(name) ? Icons.check_circle : Icons.add_circle,
                                      color: friendProvider.addedFriends.contains(name) ? Colors.blue : Colors.green,
                                      size: adjustedIconSize,
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
                  // Added Friends Container
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
                              fontSize: adjustedFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 8),
                          friendProvider.buildAddedFriendsList(context),
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
              );
            }
          },
        ),
      ),

    );
  }
}
