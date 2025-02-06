import '../storage/storage.dart';
import 'package:flutter/material.dart';
import '../leftcolumn/filelist.dart';

// 输入路径
class PathInput extends StatefulWidget {
  const PathInput({super.key});
  @override
  PathInputState createState() {
    return PathInputState();
  }
}

class PathInputState extends State<PathInput> {
  String? selectedFile;
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
                            builder: (context) =>
                                FileExplorer(path: textController.text)));
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