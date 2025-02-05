import 'dart:io';
import 'package:flutter/material.dart';
import '../storage/storage.dart';

class FileExplorer extends StatefulWidget {
  @override
  _FileExplorerState createState() => _FileExplorerState();
  final String path;
  FileExplorer({required this.path});
}

class _FileExplorerState extends State<FileExplorer> {
  Directory? currentDirectory;
  List<FileSystemEntity> files = [];
  List<Directory> previousDirectories = [];

  @override
  void initState() {
    super.initState();
    _initDirectory(widget.path);
  }

  Future<void> _initDirectory(path) async {
    Directory directory = Directory(path);
    setState(() {
      currentDirectory = directory;
      _listFiles(directory);
    });
  }

  int _listFiles(Directory directory) {
    try {
      final entities = directory.listSync();
      setState(() {
        files = entities;
      });
      return 1;
    } on PathAccessException {
      return 0;
    } on PathNotFoundException {
      return 2;
    }
  }

  void navigateToFolder(Directory folder) {
    int status = _listFiles(folder);
    if (status != 0) {
      setState(() {
        previousDirectories.add(currentDirectory!);
        currentDirectory = folder;
        _listFiles(folder);
      });
    }
  }

  void goBack() {
    if (previousDirectories.isNotEmpty) {
      setState(() {
        currentDirectory = previousDirectories.removeLast();
        _listFiles(currentDirectory!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> list = widget.path.split('\\');
    return Scaffold(
      appBar: AppBar(
        title: list.last == "" ? Text(list[list.length - 2]) : Text(list.last),
        leading: previousDirectories.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: goBack,
              )
            : null,
      ),
      body: currentDirectory == null
          ? Center(child: Text("data"))
          : ListView.builder(
              itemCount: files.length,
              itemBuilder: (context, index) {
                final entity = files[index];
                final isFolder = entity is Directory;
                return ListTile(
                  leading: isFolder
                      ? Icon(Icons.folder)
                      : Icon(Icons.insert_drive_file),
                  title: Text(entity.path.split('\\').last),
                  onTap: isFolder
                      ? () {
                          navigateToFolder(entity);
                        }
                      : () {},
                );
              },
            ),
    );
  }
}

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
                            builder: (context) =>
                                Inspector(path: textController.text)));
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
          Expanded(flex: 1, child: FileExplorer(path: widget.path)),
          Expanded(flex: 3, child: Text("data")),
          Expanded(
            flex: 1,
            child: Text("data2"),
          )
        ],
      ),
    );
  }
}
