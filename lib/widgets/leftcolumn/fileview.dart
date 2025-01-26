import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class Title extends StatelessWidget {
  const Title({Key? key, required this.path}) : super(key: key);
  final String path;
  Widget build(BuildContext context) {
    return Text(path);
  }
}

class DirectoryTree extends StatefulWidget {
  @override
  _DirectoryTreeState createState() {
    return _DirectoryTreeState();
  }
}

class _DirectoryTreeState extends State<DirectoryTree> {
  Directory? _rootDir;
  List<FileSystemEntity>? _files;
  @override
  void initState() {
    super.initState();
    _getDirectory();
  }

  Future<void> _getDirectory() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    setState(() {
      _rootDir = directory;
      _files = directory.listSync();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: _rootDir == null
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _files?.length ?? 0,
                itemBuilder: (context, index) {
                  final file = _files![index];
                  return ListTile(
                      leading: Icon(file is Directory
                          ? Icons.folder
                          : Icons.insert_drive_file),
                      title: Text(file.path.split('\\').last),
                      onTap: () {
                        if (file is Directory) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) {
                              try {
                                file.listSync();
                                return DirectoryTreeViewer(directory: file);
                              } on PathAccessException catch (e) {
                                String dir = file.path.split('\\').last;
                                return AlertDialog(
                                  title: const Text("出错了"),
                                  content: Text("$dir 无法访问"),
                                  actions: [
                                    OutlinedButton(
                                        onPressed: () {Navigator.pop(context,true);},
                                        child: const Text("返回"))
                                  ],
                                );
                              }
                            }),
                          );
                        }
                      });
                },
              ));
  }
}

class DirectoryTreeViewer extends StatelessWidget {
  final Directory directory;

  DirectoryTreeViewer({required this.directory});

  @override
  Widget build(BuildContext context) {
    final List<FileSystemEntity> files;

    files = directory.listSync();
    return Scaffold(
      appBar: AppBar(
        title: Text(directory.path.split('\\').last),
      ),
      body: ListView.builder(
          itemCount: files.length,
          itemBuilder: (context, index) {
            final file = files[index];
            return ListTile(
              leading: Icon(
                  file is Directory ? Icons.folder : Icons.insert_drive_file),
              title: Text(file.path.split('\\').last),
              onTap: () {
                if (file is Directory) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DirectoryTreeViewer(directory: file),
                    ),
                  );
                }
              },
            );
          }),
    );
  }
}
