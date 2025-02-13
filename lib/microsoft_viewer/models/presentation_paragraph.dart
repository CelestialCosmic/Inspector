import 'package:microsoft_viewer/models/presentation_image.dart';
import 'package:microsoft_viewer/models/presentation_text.dart';

///Class for storing word paragraph details.
class PresentationParagraph {
  List<PresentationText> textSpans = [];
  List<PresentationImage> images = [];
  PresentationParagraph();
}
