import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

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
    } on PathAccessException catch (e) {
      return 0;
    }
  }

  int navigateToFolder(Directory folder) {
    setState(() {
      previousDirectories.add(currentDirectory!);
      currentDirectory = folder;
      _listFiles(folder);
    });
    return 1;
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
        title: list.last == ""
               ?Text(list[list.length-2])
               :Text(list.last),
        leading: previousDirectories.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: goBack,
              )
            : null,
      ),
      body: currentDirectory == null
          ? Center(child: CircularProgressIndicator())
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
                      : null,
                );
              },
            ),
    );
  }
}
