import 'package:flutter/material.dart';

class AdvertisementSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      color: Colors.grey[300],
      child: Center(
        child: Text(
          'Advertisement',
          style: TextStyle(fontSize: 18, color: Colors.black),
        ),
      ),
    );
  }
}