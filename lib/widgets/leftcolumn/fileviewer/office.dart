import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../../../microsoft_viewer/microsoft_viewer.dart';
// import 'package:microsoft_viewer/microsoft_viewer.dart';

class OfficeViewer extends StatefulWidget {
  final String selectedFile;
  const OfficeViewer({super.key, required this.selectedFile});
  @override
  State<OfficeViewer> createState() => _OfficeViewerState();
}

class _OfficeViewerState extends State<OfficeViewer> {
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
    } catch (e) {}
  }

  @override
  void initState() {
    super.initState();
    getExternalFile();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
        constraints: const BoxConstraints.expand(), child: microsoftViewer);
  }
}
