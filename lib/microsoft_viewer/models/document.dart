import 'package:microsoft_viewer/models/word_page.dart';

///Class for storing word related details
class Document {
  String name;
  List<WordPage> pages = [];
  Document(this.name);
}
