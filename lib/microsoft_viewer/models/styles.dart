///Class for storing styles information.
class Styles {
  String name;
  String type;
  String styleId;
  int firstLineInd = 0;
  Map<String, String> fonts = {};
  int fontSize = 0;
  bool? keepNext;
  bool? keepLines;
  bool? pageBreakBefore;
  int spacingBefore = 0;
  int spacingAfter = 0;
  int outlineLvl = 0;
  Map<String, String> tableBorder = {};
  List<String> formats = [];
  String? textColor;
  String? jc;
  Styles(this.name, this.type, this.styleId);
}
