///Classes for storing details of SpreadSheet tables.
class MsSsTable {
  List<MsSsCol> cols = [];
  List<MsSsRow> rows = [];
}

class MsSsCol {
  int min;
  int max;
  double width;
  int customWidth;
  MsSsCol(this.min, this.max, this.width, this.customWidth);
}

class MsSsRow {
  int rowId;
  String spans;
  double height;
  List<MsSsCell> cells = [];
  MsSsRow(this.rowId, this.spans, this.height);
}

class MsSsCell {
  int colNo;
  String type;
  String value;
  MsSsCell(this.colNo, this.type, this.value);
}
