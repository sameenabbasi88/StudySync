import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();  // Initialize Firebase
  runApp(firebase_option());
}

class firebase_option extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Image Picker Example'),
        ),
        body: ImagePickerWidget(),
      ),
    );
  }
}

class ImagePickerWidget extends StatefulWidget {
  @override
  _ImagePickerWidgetState createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  Uint8List? _imageData;
  String? _imageUrl;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null && result.files.single.bytes != null) {
      Uint8List imageData = result.files.single.bytes!;

      // Upload image to Firebase Storage
      try {
        final ref = _storage.ref().child('uploads/${DateTime.now().millisecondsSinceEpoch}.png');
        await ref.putData(imageData);

        // Get the download URL and set it to display the image
        final url = await ref.getDownloadURL();
        setState(() {
          _imageData = imageData;
          _imageUrl = url;
        });
      } catch (e) {
        print("Error uploading image: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _imageUrl != null
              ? Image.network(_imageUrl!)
              : Text('No image selected'),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _pickImage,
            child: Text('Pick Image'),
          ),
        ],
      ),
    );
  }
}

