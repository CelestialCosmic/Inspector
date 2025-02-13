///Classes for storing tables in word documents.
class MsTable {
  int seqNo;
  List<MsTableRow> rows = [];
  int colNums = 0;
  String tblStyle;
  String rightFromText;
  String bottomFromText;
  String vertAnchor;
  String tblpY;
  String tblWidth;
  String tblWType;
  String tblLook;
  MsTable(this.seqNo, this.tblStyle, this.rightFromText, this.bottomFromText,
      this.vertAnchor, this.tblpY, this.tblWidth, this.tblWType, this.tblLook);
}

class MsTableRow {
  bool isHeader;
  List<MsTableCell> cells = [];
  MsTableRow(this.isHeader);
}

class MsTableCell {
  String cellText;
  int cellWidth;
  MsTableCell(this.cellText, this.cellWidth);
}
