import 'dart:io';
import 'package:flutter/material.dart';
import './fileviewer/image.dart';
import './fileviewer/pdf.dart';

class FileExplorer extends StatefulWidget {
  @override
  _FileExplorerState createState() => _FileExplorerState();
  final String path;
  const FileExplorer({super.key, required this.path});
}

class _FileExplorerState extends State<FileExplorer> {
  Directory? currentDirectory;
  List<FileSystemEntity> files = [];
  List<Directory> previousDirectories = [];
  String? selectedFile;

  @override
  void initState() {
    super.initState();
    _initDirectory(widget.path);
  }

  Future<void> _initDirectory(String path) async {
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
      body: Row(
        children: [
          Expanded(
              flex: 1,
              child: Scaffold(
                appBar: AppBar(
                  title: list.last == ""
                      ? Text(list[list.length - 2])
                      : Text(list.last),
                  leading: previousDirectories.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: goBack,
                        )
                      : null,
                ),
                body: ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final entity = files[index];
                    final isFolder = entity is Directory;
                    return ListTile(
                      leading: isFolder
                          ? const Icon(Icons.folder)
                          : const Icon(Icons.insert_drive_file),
                      title: Text(entity.path.split('\\').last),
                      onTap: isFolder
                          ? () {
                              navigateToFolder(entity);
                            }
                          : () {
                              setState(() {
                                selectedFile = entity.path;
                              });
                            },
                    );
                  },
                ),
              )),
          Expanded(
              flex: 3,
              child: Window(
                selectedFile: selectedFile,
              )),
          const Expanded(
            flex: 1,
            child: Text("data2"),
          )
        ],
      ),
    );
  }
}

class Window extends StatelessWidget {
  final String? selectedFile;
  Window({super.key, required this.selectedFile});

  int number = 1;
  @override
  Widget build(BuildContext context) {
    if (selectedFile == null) {
      return const Center(
        child: Text("未选择文件"),
      );
    } else {
      if (selectedFile!.endsWith(("jpg")) |
          selectedFile!.endsWith("png") |
          selectedFile!.endsWith("jpeg") |
          selectedFile!.endsWith("webp")) {
        return ImageViewer(
          selectedFile: selectedFile!,
        );
      } else if (selectedFile!.endsWith("pdf")) {
        return PdfViewer(selectedFile: selectedFile!);
      }
    }
    return Center(child: Text("未设计打开该文件的组件:\n${selectedFile!}"));
  }
}
