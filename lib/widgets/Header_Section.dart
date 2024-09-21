import 'package:flutter/material.dart';
import '../utils/color.dart';

class HeaderSection extends StatefulWidget {
  final Function(String) onLinkPressed;

  const HeaderSection({required this.onLinkPressed});

  @override
  _HeaderSectionState createState() => _HeaderSectionState();
}

class _HeaderSectionState extends State<HeaderSection> {
  String _activeLink = 'studysync'; // Default active link

  void _handleLinkPress(String link) {
    setState(() {
      _activeLink = link; // Update the active link when pressed
    });
    widget.onLinkPressed(link);
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen width
    double screenWidth = MediaQuery.of(context).size.width;

    // Adjust the main text and link sizes dynamically based on screen width
    double mainTextSize = screenWidth * 0.07; // Adjust based on screen width
    double linkTextSize = screenWidth * 0.045; // Adjust for link text

    // Adjust spacing dynamically with a max and min limit
    double spacing = screenWidth * 0.03; // Smaller spacing for smaller screens

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 10,
            color:AppColors.backgroundColor, // Border color
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 10), // Offset content to accommodate the border
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: spacing, // Spacing between elements
            runSpacing: 10,  // Spacing between rows when wrapping occurs
            children: [
              GestureDetector(
                onTap: () {
                  _handleLinkPress('studysync');
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _activeLink == 'studysync' ? Color(0xFFA62217) : Colors.transparent,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    'STUDYSYNC',
                    style: TextStyle(
                      fontSize: mainTextSize.clamp(20, 30), // Set a min and max size
                      fontWeight: FontWeight.bold,
                      color: _activeLink == 'studysync' ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
              HeaderLink(
                text: 'Friends',
                fontSize: linkTextSize,
                isActive: _activeLink == 'friends',
                onLinkPressed: _handleLinkPress,
              ),
              HeaderLink(
                text: 'Groups',
                fontSize: linkTextSize,
                isActive: _activeLink == 'groups',
                onLinkPressed: _handleLinkPress,
              ),
              HeaderLink(
                text: 'Profile',
                fontSize: linkTextSize,
                isActive: _activeLink == 'profile',
                onLinkPressed: _handleLinkPress,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class HeaderLink extends StatelessWidget {
  final String text;
  final double fontSize;
  final bool isActive;
  final Function(String) onLinkPressed;

  const HeaderLink({
    required this.text,
    required this.fontSize,
    required this.isActive,
    required this.onLinkPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onLinkPressed(text.toLowerCase());
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Color(0xFFA62217) : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize.clamp(14, 22), // Clamp font size between 14 and 22
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
