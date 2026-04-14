import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class VideoStorageScreen extends StatefulWidget {
  @override
  _VideoStorageScreenState createState() => _VideoStorageScreenState();
}

class _VideoStorageScreenState extends State<VideoStorageScreen> {
  late VideoPlayerController _controller;
  File? _videoFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickVideo() async {
    final pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _videoFile = File(pickedFile.path);
      });
      _initializeVideoPlayer();
    }
  }

  Future<void> _recordVideo() async {
    final pickedFile = await _picker.pickVideo(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _videoFile = File(pickedFile.path);
      });
      _initializeVideoPlayer();
    }
  }

  void _initializeVideoPlayer() {
    if (_videoFile != null) {
      _controller = VideoPlayerController.file(_videoFile!)
        ..initialize().then((_) {
          setState(() {}); // Ensure the first frame is shown
        });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Storage'),
      ),
      body: Column(
        children: [
          if (_videoFile != null && _controller.value.isInitialized)
            AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            )
          else
            Container(
              height: 200,
              color: Colors.grey[300],
              child: Center(
                child: Text('No video selected.'),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _pickVideo,
                child: Text('Pick Video from Gallery'),
              ),
              SizedBox(width: 20),
              ElevatedButton(
                onPressed: _recordVideo,
                child: Text('Record Video'),
              ),
            ],
          ),
          if (_videoFile != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    if (_controller.value.isPlaying) {
                      _controller.pause();
                    } else {
                      _controller.play();
                    }
                    setState(() {});
                  },
                  child: Icon(
                    _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
