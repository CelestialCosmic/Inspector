import 'dart:io';
import 'package:flutter/material.dart';

class ImageViewer extends StatefulWidget {
  final String selectedFile;
  const ImageViewer({super.key, required this.selectedFile});
  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  int _quarterTurns = 0;

  void _rotateBox() {
    setState(() {
      _quarterTurns = (_quarterTurns + 1) % 4;
    });
  }

  void _rotateBox2() {
    setState(() {
      _quarterTurns = (_quarterTurns - 1) % 4;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: RotatedBox(
              quarterTurns: _quarterTurns,
              child: InteractiveViewer(
                  child: Image.file(File(widget.selectedFile)))),
        ),
        const Padding(padding: EdgeInsets.all(8)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Padding(padding: EdgeInsets.only(left: 8, right: 8)),
            ElevatedButton(
              onPressed: () {
                _rotateBox2();
              },
              child: const Icon(Icons.rotate_90_degrees_ccw_rounded),
            ),
            const Padding(padding: EdgeInsets.only(left: 8, right: 8)),
            ElevatedButton(
              onPressed: () {
                _rotateBox();
              },
              child: const Icon(Icons.rotate_90_degrees_cw_rounded),
            ),
            const Padding(padding: EdgeInsets.only(left: 8, right: 8)),
          ],
        ),
        const Padding(padding: EdgeInsets.all(8)),
      ],
    );
  }
}
