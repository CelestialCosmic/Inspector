// import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';
// import 'dart:io';

// class Title extends StatelessWidget {
//   const Title({Key? key, required this.path}) : super(key: key);
//   final String path;
//   Widget build(BuildContext context) {
//     return Text(path);
//   }
// }

// class DirectoryTree extends StatefulWidget {
//   @override
//   _DirectoryTreeState createState() {
//     return _DirectoryTreeState();
//   }
// }

// class _DirectoryTreeState extends State<DirectoryTree> {
//   Directory? _rootDir;
//   List<FileSystemEntity>? _files;
//   @override
//   void initState() {
//     super.initState();
//     _getDirectory();
//   }

//   Future<void> _getDirectory() async {
//     final Directory directory = await getApplicationDocumentsDirectory();
//     setState(() {
//       _rootDir = directory;
//       _files = directory.listSync();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         appBar: AppBar(title: const Text("文件列表")),
//         body: _rootDir == null
//             ? const Center(child: CircularProgressIndicator())
//             : ListView.builder(
//                 itemCount: _files?.length ?? 0,
//                 itemBuilder: (context, index) {
//                   final file = _files![index];
//                   return ListTile(
//                       leading: Icon(file is Directory
//                           ? Icons.folder
//                           : Icons.insert_drive_file),
//                       title: Text(file.path.split('\\').last),
//                       onTap: () {
//                         if (file is Directory) {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) {
//                               try {
//                                 file.listSync();
//                                 return DirectoryTreeViewer(directory: file);
//                               } on PathAccessException catch (e) {
//                                 String dir = file.path.split('\\').last;
//                                 return Scaffold(
//                                     body: AlertDialog(
//                                   title: const Text("出错了"),
//                                   content: Text("$dir 无法访问"),
//                                   actions: [
//                                     OutlinedButton(
//                                         onPressed: () {
//                                           Navigator.pop(context, true);
//                                         },
//                                         child: const Text("返回"))
//                                   ],
//                                 ));
//                               }
//                             }),
//                           );
//                         }
//                       });
//                 },
//               ));
//   }
// }

// class DirectoryTreeViewer extends StatelessWidget {
//   final Directory directory;

//   DirectoryTreeViewer({required this.directory});

//   @override
//   Widget build(BuildContext context) {
//     final List<FileSystemEntity> files = directory.listSync();
//     return
//     Scaffold(
//       appBar: AppBar(
//         title: Text(directory.path.split('\\').last),
//       ),
//       body:
//       ListView.builder(
//           itemCount: files.length,
//           itemBuilder: (context, index) {
//             final file = files[index];
//             return ListTile(
//               leading: Icon(
//                   file is Directory ? Icons.folder : Icons.insert_drive_file),
//               title: Text(file.path.split('\\').last),
//               onTap: () {
//                 if (file is Directory) {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) =>
//                           DirectoryTreeViewer(directory: file),
//                     ),
//                   );
//                 }
//               },
//             );
//           }
//     ),
//     );
//   }
// }

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class FileExplorer extends StatefulWidget {
  @override
  _FileExplorerState createState() => _FileExplorerState();
}

class _FileExplorerState extends State<FileExplorer> {
  Directory? currentDirectory;
  List<FileSystemEntity> files = [];
  List<Directory> previousDirectories = [];

  @override
  void initState() {
    super.initState();
    _initDirectory();
  }

  Future<void> _initDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
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
    return Scaffold(
      appBar: AppBar(
        title: Text('File Explorer'),
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
