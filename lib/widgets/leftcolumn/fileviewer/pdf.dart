import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

class PdfViewer extends StatefulWidget {
  late final String? selectedFile;
  PdfViewer({super.key, required this.selectedFile});
  State<StatefulWidget> createState() => _PdfViewerState();
}

class _PdfViewerState extends State<PdfViewer> {
  final PdfController
  void didUpdateWidget(covariant Window oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedFile != widget.selectedFile &&
        widget.selectedFile != null) {
      pdfController?.dispose();
      if (widget.selectedFile!.endsWith("pdf")) {
        setState(() {
          pdfController = PdfController(
            document: PdfDocument.openFile(widget.selectedFile!),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pdfController = PdfController(
      document: PdfDocument.openFile(widget.selectedFile!),
    );
    return Column(
      children: [
        Row(
          children: [
            ElevatedButton(
              onPressed: () {
                pdfController.previousPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeIn);
              },
              child: const Icon(Icons.skip_previous),
            ),
            ElevatedButton(
              onPressed: () {
                pdfController.nextPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeIn);
              },
              child: const Icon(Icons.rotate_90_degrees_ccw_rounded),
            ),
            ElevatedButton(
              onPressed: () {
                pdfController.nextPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeIn);
              },
              child: const Icon(Icons.rotate_90_degrees_cw_rounded),
            ),
            ElevatedButton(
              onPressed: () {
                pdfController.nextPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeIn);
              },
              child: const Icon(Icons.skip_next),
            ),
          ],
        ),
        Expanded(
          child: PdfView(
            controller: pdfController,
          ),
        ),
      ],
    );
  }
}
