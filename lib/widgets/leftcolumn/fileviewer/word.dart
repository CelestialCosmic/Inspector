// import 'package:flutter/material.dart';
// import 'package:microsoft_viewer/microsoft_viewer.dart';
// import 'dart:io';

// class WordViewer extends StatefulWidget {
//   final String selectedFile;
//   const WordViewer({super.key, required this.selectedFile});
//   @override
//   State<WordViewer> createState() => _WordViewerState();
// }

// class _WordViewerState extends State<WordViewer> {
//   late MicrosoftViewer microsoftViewer = const MicrosoftViewer([]);
//   Future<void> getAssetFile() async {
//     ByteData byteData = await rootBundle.load(widget.selectedFile);
//     setState(() {
//       Key newKey = UniqueKey();
//       microsoftViewer = MicrosoftViewer(
//         Uint8List.sublistView(byteData),
//         key: newKey,
//       );
//     });
//   }
//   @override
//   void initState() {
//     super.initState();
//     getAssetFile();
//   }
//   @override
//   Widget build(BuildContext context) {
//     return Expanded(child: microsoftViewer);
//   }
// }

import 'package:flutter/material.dart';
import 'package:microsoft_viewer/microsoft_viewer.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class WordViewer extends StatefulWidget {
  final String selectedFile;
  const WordViewer({super.key, required this.selectedFile});
  @override
  State<WordViewer> createState() => _WordViewerState();
}

class _WordViewerState extends State<WordViewer> {
  late MicrosoftViewer microsoftViewer = const MicrosoftViewer([]);
  
  Future<void> getExternalFile() async {
    try {
      File file = File(widget.selectedFile);
      Uint8List fileBytes = await file.readAsBytes();
      setState(() {
        Key newKey = UniqueKey();
        microsoftViewer = MicrosoftViewer(
          fileBytes,
          key: newKey,
        );
      });
    } catch (e) {
      
    }
  }

  @override
  void initState() {
    super.initState();
    getExternalFile();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints.expand(),
      child: microsoftViewer);
  }
}