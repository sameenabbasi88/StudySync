import 'package:flutter/material.dart';
import '../utils/color.dart';

class TimeSpentSection extends StatelessWidget {
  final Duration totalTimeSpentThisWeek;

  TimeSpentSection({required this.totalTimeSpentThisWeek});

  @override
  Widget build(BuildContext context) {
    String formattedTimeSpent = _formatDuration(totalTimeSpentThisWeek);

    // Get the screen width
    double screenWidth = MediaQuery.of(context).size.width;

    // Set font sizes based on screen width
    double titleFontSize = screenWidth < 600 ? 18 : 20; // Smaller font for mobile
    double timeFontSize = screenWidth < 600 ? 14 : 16; // Smaller font for mobile

    return Container(
      // padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Time Spent:',
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text(
            formattedTimeSpent,
            style: TextStyle(
              fontSize: timeFontSize,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);
    int seconds = duration.inSeconds.remainder(60);
    return '$hours hours, $minutes minutes, $seconds seconds';
  }
}
