import 'package:flutter/material.dart';
import 'package:inspector/widgets/activity/inspector.dart';
import '../storage/storage.dart';
import '../leftcolumn/filelist.dart';

class PathInput extends StatefulWidget {
  const PathInput({super.key});
  @override
  PathInputState createState() {
    return PathInputState();
  }
}

class PathInputState extends State<PathInput> {
  final textController = TextEditingController();
  final storage = SharedPref();
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(
        controller: textController,
      ),
      Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: AbsorbPointer(
                absorbing: false,
                child: ElevatedButton(
                  onPressed: () {
                    String dir = textController.text;
                    if (dir == "") {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('路径不可为空')),
                      );
                      return;
                    }
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => Inspector(path:textController.text)));
                    storage.save("dir", dir);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('正在获取 $dir ')),
                    );
                  },
                  child: const Text('提交路径'),
                )),
          )),
    ]);
  }
}


class Inspector extends StatefulWidget {
  String path = "";
  Inspector({required this.path});
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
          Expanded(flex: 1, child: FileExplorer(path:widget.path)),
          Expanded(flex: 3, child: Text("data")),
          Expanded(flex: 1, child: Text("data2"),)
        ],
      ),
    );
  }
}
