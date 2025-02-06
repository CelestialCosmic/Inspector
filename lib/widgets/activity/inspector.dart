import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
class FileInspector extends StatefulWidget{
  _FileInspectorState createState() => _FileInspectorState();
  String fpath = "";
  GlobalKey<_FileInspectorState> inspectorKey = GlobalKey();
  FileInspector({required this.fpath});
}

class _FileInspectorState extends State<FileInspector>{
  Widget build(BuildContext context){
    return Expanded(child: Text("1"));
  }
}