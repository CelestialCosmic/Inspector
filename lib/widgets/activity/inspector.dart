import 'package:flutter/material.dart';
import 'package:inspector/widgets/leftcolumn/filelist.dart';

class Inspector extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _InspectorState();
  }
}

class _InspectorState extends State<Inspector> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(flex: 1, child: FileExplorer()),
          Expanded(flex: 3, child: Text("data"))
        ],
      ),
    );
  }
}
