import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

class PdfViewer extends StatefulWidget {
  final String selectedFile;
  const PdfViewer({super.key, required this.selectedFile});
  @override
  State<PdfViewer> createState() => _PdfViewerState();
}

class _PdfViewerState extends State<PdfViewer> {
  int _quarterTurns = 0;
  late final controller =
      PdfController(document: PdfDocument.openFile(widget.selectedFile));
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
          child:
           InteractiveViewer(
              maxScale: 3.0,
              minScale: 0.5,
              child: RotatedBox(
                  quarterTurns: _quarterTurns,
                  child: PdfView(
                    controller: controller,
                  ))),
        ),
        const Padding(padding: EdgeInsets.all(8)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                controller.previousPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeIn);
              },
              child: const Icon(Icons.skip_previous),
            ),
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
            ElevatedButton(
              onPressed: () {
                controller.nextPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeIn);
              },
              child: const Icon(Icons.skip_next),
            ),
          ],
        ),
        const Padding(padding: EdgeInsets.all(8)),
      ],
    );
  }
}
