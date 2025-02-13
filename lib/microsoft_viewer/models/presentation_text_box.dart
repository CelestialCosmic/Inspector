import 'dart:ui';

import 'package:microsoft_viewer/models/presentation_paragraph.dart';

///Class for storing details of text boxes
class PresentationTextBox {
  Offset offset;
  Size size;
  List<PresentationParagraph> presentationParas = [];
  PresentationTextBox(this.offset, this.size);
}
